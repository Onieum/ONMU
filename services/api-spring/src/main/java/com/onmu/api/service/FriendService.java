package com.onmu.api.service;

import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.AddFriendRequest;
import com.onmu.api.web.dto.FriendResponse;
import com.onmu.api.web.dto.UpdateFriendRequest;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
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

  public FriendService(JdbcTemplate jdbcTemplate, UserRepository userRepository) {
    this.jdbcTemplate = jdbcTemplate;
    this.userRepository = userRepository;
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
          friend.display_name,
          friend.nickname,
          friend.profile_image_url,
          coalesce(nullif(fs.memo, ''), coalesce(active_code.code, friend.public_id)) as memo,
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
          coalesce(nullif(fs.display_alias, ''), nullif(friend.nickname, ''), friend.display_name)
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
    String like = "%" + keyword.toLowerCase() + "%";
    return jdbcTemplate.query(
      """
        select
          u.id as user_id,
          u.public_id,
          coalesce(active_code.code, u.public_id) as user_code,
          u.display_name,
          u.nickname,
          u.profile_image_url,
          coalesce(active_code.code, u.public_id) as memo,
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
          and (
            lower(u.public_id) like ?
            or lower(coalesce(active_code.code, '')) like ?
            or lower(coalesce(u.display_name, '')) like ?
            or lower(coalesce(u.nickname, '')) like ?
          )
        order by u.display_name
        limit 20
      """,
      this::friendResponse,
      userId,
      like,
      like,
      like,
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

    UUID lowId = user.getId().compareTo(friend.getId()) < 0 ? user.getId() : friend.getId();
    UUID highId = user.getId().compareTo(friend.getId()) < 0 ? friend.getId() : user.getId();
    UUID friendshipId = jdbcTemplate.queryForObject(
      """
        insert into friendships (user_low_id, user_high_id, status, source)
        values (?, ?, 'active', 'user_code')
        on conflict (user_low_id, user_high_id)
        do update set status = 'active', deleted_at = null, updated_at = now()
        returning id
      """,
      UUID.class,
      lowId,
      highId
    );

    upsertSetting(friendshipId, user.getId(), friend.getId(), request.memo());
    upsertSetting(friendshipId, friend.getId(), user.getId(), null);
    return friend(user.getId(), friend.getId());
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
          friend.display_name,
          friend.nickname,
          friend.profile_image_url,
          coalesce(nullif(fs.memo, ''), coalesce(active_code.code, friend.public_id)) as memo,
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

  private FriendResponse friendResponse(ResultSet rs, int rowNum) throws SQLException {
    return new FriendResponse(
      rs.getString("user_id"),
      rs.getString("public_id"),
      rs.getString("user_code"),
      rs.getString("display_name"),
      rs.getString("nickname"),
      rs.getString("profile_image_url"),
      rs.getString("memo"),
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
