package com.onmu.api.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.AddFriendRequest;
import com.onmu.api.web.dto.FriendResponse;
import com.onmu.api.web.dto.UpdateFriendRequest;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class FriendService {
  private final JdbcTemplate jdbcTemplate;
  private final UserRepository userRepository;
  private final ObjectMapper objectMapper;

  public FriendService(JdbcTemplate jdbcTemplate, UserRepository userRepository, ObjectMapper objectMapper) {
    this.jdbcTemplate = jdbcTemplate;
    this.userRepository = userRepository;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public List<FriendResponse> friends(UUID userId) {
    requireUser(userId);
    return jdbcTemplate.query(
      """
        select
          friend.id as user_id,
          friend.public_id,
          coalesce(active_code.code, friend.public_id) as user_code,
          friend.nickname,
          friend.profile_image_url,
          case
            when fs.memo = coalesce(active_code.code, friend.public_id) then ''
            when fs.memo = friend.public_id then ''
            when fs.memo ~ '^[0-9]{8,12}$' then ''
            else coalesce(fs.memo, '')
          end as memo,
          coalesce(friend.preference_profile::jsonb ->> 'introText', '') as intro_text,
          coalesce(fs.is_favorite, false) as favorite
        from friend_settings fs
        join friendships f on f.id = fs.friendship_id
        join users friend on friend.id = fs.friend_user_id
        left join lateral (
          select code
          from user_codes
          where user_id = friend.id
            and status = 'active'
          order by created_at desc
          limit 1
        ) active_code on true
        where fs.user_id = ?
          and coalesce(fs.hidden, false) = false
          and f.status = 'active'
          and f.deleted_at is null
          and friend.deleted_at is null
        order by coalesce(fs.is_favorite, false) desc,
          coalesce(nullif(fs.display_alias, ''), nullif(friend.nickname, ''), friend.public_id)
      """,
      this::friendResponse,
      userId
    );
  }

  @Transactional(readOnly = true)
  public UUID requireActiveFriendUserId(UUID userId, String friendIdentifier) {
    UserEntity user = requireUser(userId);
    UserEntity friend = resolveUserIdentifier(friendIdentifier);
    Integer count = jdbcTemplate.queryForObject(
      """
        select count(*)
        from friend_settings fs
        join friendships f on f.id = fs.friendship_id
        where fs.user_id = ?
          and fs.friend_user_id = ?
          and coalesce(fs.hidden, false) = false
          and f.status = 'active'
          and f.deleted_at is null
      """,
      Integer.class,
      user.getId(),
      friend.getId()
    );
    if (count == null || count == 0) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "friend_not_found");
    }
    return friend.getId();
  }

  @Transactional(readOnly = true)
  public List<FriendResponse> search(UUID userId, String query) {
    requireUser(userId);
    String keyword = query == null ? "" : query.trim();
    if (keyword.length() < 2) {
      return List.of();
    }
    boolean allowNicknameSearch = !keyword.toLowerCase().startsWith("usr_");
    String like = "%" + keyword.toLowerCase() + "%";
    String exact = keyword.toLowerCase();
    return jdbcTemplate.query(
      """
        select
          u.id as user_id,
          u.public_id,
          coalesce(active_code.code, u.public_id) as user_code,
          u.nickname,
          u.profile_image_url,
          '' as memo,
          coalesce(u.preference_profile::jsonb ->> 'introText', '') as intro_text,
          false as favorite
        from users u
        left join lateral (
          select code
          from user_codes
          where user_id = u.id
            and status = 'active'
          order by created_at desc
          limit 1
        ) active_code on true
        where u.id <> ?
          and u.deleted_at is null
          and coalesce((u.preference_profile::jsonb ->> 'searchAllowed')::boolean, true) = true
          and (
            lower(u.public_id) = ?
            or lower(coalesce(active_code.code, '')) = ?
            or (? and lower(coalesce(u.nickname, '')) like ?)
          )
        order by u.nickname
        limit 20
      """,
      this::friendResponse,
      userId,
      exact,
      exact,
      allowNicknameSearch,
      like
    );
  }

  @Transactional
  public FriendResponse addFriend(UUID userId, AddFriendRequest request) {
    UserEntity user = requireUser(userId);
    UserEntity friend = resolveUserIdentifier(request.publicId());
    if (user.getId().equals(friend.getId())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "cannot_add_self");
    }
    if (!isSearchAllowed(friend)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "search_not_allowed");
    }

    UUID lowId = user.getId().compareTo(friend.getId()) < 0 ? user.getId() : friend.getId();
    UUID highId = user.getId().compareTo(friend.getId()) < 0 ? friend.getId() : user.getId();
    Integer activeCount = jdbcTemplate.queryForObject(
      """
        select count(*)
        from friendships
        where user_low_id = ?
          and user_high_id = ?
          and status = 'active'
          and deleted_at is null
      """,
      Integer.class,
      lowId,
      highId
    );
    if (activeCount != null && activeCount > 0) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "already_friend");
    }

    Integer pendingCount = jdbcTemplate.queryForObject(
      """
        select count(*)
        from friend_requests
        where (
            (
              requester_user_id = ?
              and target_user_id = ?
            )
            or (
              requester_user_id = ?
              and target_user_id = ?
            )
          )
          and status = 'pending'
      """,
      Integer.class,
      user.getId(),
      friend.getId(),
      friend.getId(),
      user.getId()
    );
    if (pendingCount != null && pendingCount > 0) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "friend_request_pending");
    }

    UUID requestId = jdbcTemplate.queryForObject(
      """
        insert into friend_requests (requester_user_id, target_user_id, request_channel, status, message)
        values (?, ?, 'user_code', 'pending', ?)
        returning id
      """,
      UUID.class,
      user.getId(),
      friend.getId(),
      request.memo() == null ? null : request.memo().trim()
    );
    createFriendRequestNotification(requestId, user, friend);
    return pendingFriendResponse(friend);
  }

  @Transactional
  public FriendResponse acceptFriendRequest(UUID userId, UUID requestId) {
    UserEntity currentUser = requireUser(userId);
    List<UUID> requesterIds = jdbcTemplate.query(
      """
        select requester_user_id
        from friend_requests
        where id = ?
          and target_user_id = ?
          and status = 'pending'
      """,
      (rs, rowNum) -> rs.getObject("requester_user_id", UUID.class),
      requestId,
      currentUser.getId()
    );
    if (requesterIds.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "friend_request_not_found");
    }
    UUID requesterId = requesterIds.get(0);
    UserEntity requester = userRepository.findByIdAndDeletedAtIsNull(requesterId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "requester_not_found"));

    UUID lowId = currentUser.getId().compareTo(requester.getId()) < 0
      ? currentUser.getId()
      : requester.getId();
    UUID highId = currentUser.getId().compareTo(requester.getId()) < 0
      ? requester.getId()
      : currentUser.getId();
    UUID friendshipId = jdbcTemplate.queryForObject(
      """
        insert into friendships (user_low_id, user_high_id, status, source, accepted_request_id)
        values (?, ?, 'active', 'friend_request', ?)
        on conflict (user_low_id, user_high_id)
        do update set status = 'active',
          source = 'friend_request',
          accepted_request_id = excluded.accepted_request_id,
          deleted_at = null,
          updated_at = now()
        returning id
      """,
      UUID.class,
      lowId,
      highId,
      requestId
    );
    upsertSetting(friendshipId, currentUser.getId(), requester.getId(), null);
    upsertSetting(friendshipId, requester.getId(), currentUser.getId(), null);
    jdbcTemplate.update(
      """
        update friend_requests
        set status = 'accepted',
          responded_at = now()
        where id = ?
      """,
      requestId
    );
    markFriendRequestNotificationsRead(requestId);
    return friend(currentUser.getId(), requester.getId());
  }

  @Transactional
  public void declineFriendRequest(UUID userId, UUID requestId) {
    int updated = jdbcTemplate.update(
      """
        update friend_requests
        set status = 'declined',
          responded_at = now()
        where id = ?
          and target_user_id = ?
          and status = 'pending'
      """,
      requestId,
      userId
    );
    if (updated == 0) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "friend_request_not_found");
    }
    markFriendRequestNotificationsRead(requestId);
  }

  @Transactional
  public FriendResponse updateFriend(UUID userId, String friendIdentifier, UpdateFriendRequest request) {
    UserEntity user = requireUser(userId);
    UserEntity friend = resolveUserIdentifier(friendIdentifier);
    String memo = request.memo() == null ? null : request.memo().trim();
    jdbcTemplate.update(
      """
        update friend_settings
        set memo = coalesce(?, memo),
            is_favorite = coalesce(?, is_favorite),
            updated_at = now()
        where user_id = ?
          and friend_user_id = ?
      """,
      memo,
      request.favorite(),
      user.getId(),
      friend.getId()
    );
    return friend(user.getId(), friend.getId());
  }

  @Transactional
  public void deleteFriend(UUID userId, String friendIdentifier) {
    UserEntity user = requireUser(userId);
    UserEntity friend = resolveUserIdentifier(friendIdentifier);
    jdbcTemplate.update(
      """
        update friendships
        set status = 'deleted',
            deleted_at = now(),
            updated_at = now()
        where id in (
          select friendship_id
          from friend_settings
          where user_id = ?
            and friend_user_id = ?
        )
      """,
      user.getId(),
      friend.getId()
    );
    jdbcTemplate.update(
      """
        update friend_settings
        set hidden = true,
            updated_at = now()
        where friendship_id in (
          select friendship_id
          from friend_settings
          where user_id = ?
            and friend_user_id = ?
        )
      """,
      user.getId(),
      friend.getId()
    );
  }

  private FriendResponse friend(UUID userId, UUID friendUserId) {
    return jdbcTemplate.queryForObject(
      """
        select
          friend.id as user_id,
          friend.public_id,
          coalesce(active_code.code, friend.public_id) as user_code,
          friend.nickname,
          friend.profile_image_url,
          case
            when fs.memo = coalesce(active_code.code, friend.public_id) then ''
            when fs.memo = friend.public_id then ''
            when fs.memo ~ '^[0-9]{8,12}$' then ''
            else coalesce(fs.memo, '')
          end as memo,
          coalesce(friend.preference_profile::jsonb ->> 'introText', '') as intro_text,
          coalesce(fs.is_favorite, false) as favorite
        from friend_settings fs
        join friendships f on f.id = fs.friendship_id
        join users friend on friend.id = fs.friend_user_id
        left join lateral (
          select code
          from user_codes
          where user_id = friend.id
            and status = 'active'
          order by created_at desc
          limit 1
        ) active_code on true
        where fs.user_id = ?
          and fs.friend_user_id = ?
          and f.status = 'active'
          and f.deleted_at is null
      """,
      this::friendResponse,
      userId,
      friendUserId
    );
  }

  private void upsertSetting(UUID friendshipId, UUID userId, UUID friendUserId, String memo) {
    jdbcTemplate.update(
      """
        insert into friend_settings (friendship_id, user_id, friend_user_id, memo, hidden, is_favorite)
        values (?, ?, ?, ?, false, false)
        on conflict (friendship_id, user_id)
        do update set friend_user_id = excluded.friend_user_id,
          memo = coalesce(excluded.memo, friend_settings.memo),
          hidden = false,
          updated_at = now()
      """,
      friendshipId,
      userId,
      friendUserId,
      blankToNull(memo)
    );
  }

  private UserEntity requireUser(UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }

  private UserEntity resolveUserIdentifier(String identifier) {
    String value = identifier == null ? "" : identifier.trim();
    if (value.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_friend_identifier");
    }
    return userRepository.findByPublicIdAndDeletedAtIsNull(value)
      .or(() -> findByUserCode(value))
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "friend_not_found"));
  }

  private java.util.Optional<UserEntity> findByUserCode(String code) {
    List<UUID> ids = jdbcTemplate.query(
      """
        select user_id
        from user_codes
        where lower(code) = lower(?)
          and status = 'active'
        order by created_at desc
        limit 1
      """,
      (rs, rowNum) -> rs.getObject("user_id", UUID.class),
      code
    );
    if (ids.isEmpty()) {
      return java.util.Optional.empty();
    }
    return userRepository.findByIdAndDeletedAtIsNull(ids.get(0));
  }

  private boolean isSearchAllowed(UserEntity user) {
    try {
      Map<String, Object> profile = objectMapper.readValue(
        user.getPreferenceProfile() == null || user.getPreferenceProfile().isBlank()
          ? "{}"
          : user.getPreferenceProfile(),
        new TypeReference<Map<String, Object>>() {}
      );
      Object value = profile.get("searchAllowed");
      return value == null || Boolean.parseBoolean(value.toString());
    } catch (Exception ignored) {
      return true;
    }
  }

  private FriendResponse pendingFriendResponse(UserEntity friend) {
    return new FriendResponse(
      friend.getId().toString(),
      friend.getPublicId(),
      friend.getPublicId(),
      friend.getNickname(),
      friend.getProfileImageUrl(),
      "",
      introText(friend),
      false
    );
  }

  private void createFriendRequestNotification(UUID requestId, UserEntity requester, UserEntity target) {
    jdbcTemplate.update(
      """
        insert into notifications (user_id, notification_type, title, body, payload, status)
        values (?, 'friend_request', ?, ?, ?::jsonb, 'queued')
      """,
      target.getId(),
      "친구 요청이 도착했어요",
      requester.getNickname() + "님이 친구 요청을 보냈어요.",
      jsonPayload(Map.of(
        "friendRequestId", requestId.toString(),
        "requesterUserId", requester.getPublicId(),
        "requesterName", requester.getNickname()
      ))
    );
  }

  private void markFriendRequestNotificationsRead(UUID requestId) {
    jdbcTemplate.update(
      """
        update notifications
        set read_at = coalesce(read_at, now()),
          status = 'read'
        where notification_type = 'friend_request'
          and payload ->> 'friendRequestId' = ?
      """,
      requestId.toString()
    );
  }

  private String jsonPayload(Map<String, String> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (Exception ignored) {
      return "{}";
    }
  }

  private String introText(UserEntity user) {
    try {
      Map<String, Object> profile = objectMapper.readValue(
        user.getPreferenceProfile() == null || user.getPreferenceProfile().isBlank()
          ? "{}"
          : user.getPreferenceProfile(),
        new TypeReference<Map<String, Object>>() {}
      );
      Object value = profile.get("introText");
      return value == null ? "" : value.toString();
    } catch (Exception ignored) {
      return "";
    }
  }

  private FriendResponse friendResponse(ResultSet rs, int rowNum) throws SQLException {
    return new FriendResponse(
      rs.getString("user_id"),
      rs.getString("public_id"),
      rs.getString("user_code"),
      rs.getString("nickname"),
      rs.getString("profile_image_url"),
      rs.getString("memo"),
      rs.getString("intro_text"),
      rs.getBoolean("favorite")
    );
  }

  private String blankToNull(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    return value.trim();
  }
}
