package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.ChatReadStateEntity;
import com.onmu.api.domain.ChatReadStateRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.ChatMessageAttachmentRequest;
import com.onmu.api.web.dto.CreateChatMessageRequest;
import com.onmu.api.web.dto.UpdateChatReadStateRequest;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class ChatActivityServiceTests {
  @Mock
  private ChatActivityEventRepository chatActivityEventRepository;
  @Mock
  private ChatReadStateRepository chatReadStateRepository;
  @Mock
  private GroupRepository groupRepository;
  @Mock
  private UserRepository userRepository;
  @Mock
  private ChatRealtimePublisher chatRealtimePublisher;
  @Mock
  private OutboxService outboxService;

  private ChatActivityService service;
  private GroupEntity group;
  private UserEntity currentUser;
  private UserEntity otherUser;

  @BeforeEach
  void setUp() {
    service = new ChatActivityService(
      chatActivityEventRepository,
      chatReadStateRepository,
      groupRepository,
      userRepository,
      new ObjectMapper(),
      chatRealtimePublisher,
      outboxService
    );
    currentUser = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000001"), "나");
    otherUser = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000002"), "지민");
    group = new GroupEntity("1", "제주 여행 모임", currentUser);
  }

  @Test
  void getMessagesMapsV9SeedChatActivityEvents() {
    ChatActivityEventEntity otherMessage = new ChatActivityEventEntity(
      group,
      otherUser,
      "chat.message",
      "{\"senderName\":\"지민\",\"message\":\"다들 안녕! 드디어 다음 주에 제주도네 날씨도 좋아 보이더라구.\",\"source\":\"flutter_mock\"}",
      Instant.parse("2026-06-09T05:00:00Z")
    );
    ChatActivityEventEntity myMessage = new ChatActivityEventEntity(
      group,
      currentUser,
      "chat.message",
      "{\"senderName\":\"나\",\"message\":\"기대된다아 ㅎㅎ\",\"source\":\"flutter_mock\"}",
      Instant.parse("2026-06-09T05:01:00Z")
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(chatActivityEventRepository.findPageBefore(eq(group), isNull(), any(Pageable.class)))
      .thenReturn(List.of(myMessage, otherMessage));
    stubUnread(1L);

    Map<String, Object> response = service.messages("1", currentUser.getId(), null, null);

    List<Map<String, Object>> messages = messages(response);
    assertThat(messages).hasSize(2);
    assertThat(response)
      .containsEntry("hasMore", false)
      .containsEntry("unreadCount", 1L);
    assertThat(messages.getFirst())
      .containsEntry("senderUserId", otherUser.getPublicId())
      .containsEntry("senderName", "지민")
      .containsEntry("message", "다들 안녕! 드디어 다음 주에 제주도네 날씨도 좋아 보이더라구.")
      .containsEntry("messageType", "message")
      .containsEntry("cursor", "2026-06-09T05:00:00Z")
      .containsEntry("isMine", false)
      .containsEntry("sendStatus", "sent")
      .containsEntry("timeLabel", "14:00");
    assertThat(messages.get(1))
      .containsEntry("senderUserId", currentUser.getPublicId())
      .containsEntry("message", "기대된다아 ㅎㅎ")
      .containsEntry("isMine", true)
      .containsEntry("timeLabel", "14:01");
  }

  @Test
  void getMessagesReturnsNextCursorWhenOlderMessagesRemain() {
    ChatActivityEventEntity olderMessage = new ChatActivityEventEntity(
      group,
      otherUser,
      "chat.message",
      "{\"message\":\"이전 메시지\"}",
      Instant.parse("2026-06-09T05:00:00Z")
    );
    ChatActivityEventEntity newerMessage = new ChatActivityEventEntity(
      group,
      currentUser,
      "chat.message",
      "{\"message\":\"새 메시지\"}",
      Instant.parse("2026-06-09T05:01:00Z")
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(chatActivityEventRepository.findPageBefore(
      eq(group),
      eq(Instant.parse("2026-06-09T05:02:00Z")),
      any(Pageable.class)
    )).thenReturn(List.of(newerMessage, olderMessage));
    stubUnread(0L);

    Map<String, Object> response = service.messages(
      "1",
      currentUser.getId(),
      "2026-06-09T05:02:00Z",
      1
    );

    List<Map<String, Object>> messages = messages(response);
    assertThat(messages).hasSize(1);
    assertThat(messages.getFirst()).containsEntry("message", "새 메시지");
    assertThat(response)
      .containsEntry("hasMore", true)
      .containsEntry("nextCursor", "2026-06-09T05:01:00Z")
      .containsEntry("limit", 1);
  }

  @Test
  void postMessageCreatesChatActivityEventAndReturnsCreatedMessage() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(chatActivityEventRepository.save(any(ChatActivityEventEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = service.createMessage(
      "1",
      currentUser.getId(),
      new CreateChatMessageRequest("  새 메시지입니다  ")
    );

    assertThat(response)
      .containsEntry("senderUserId", currentUser.getPublicId())
      .containsEntry("senderName", "나")
      .containsEntry("message", "새 메시지입니다")
      .containsEntry("messageType", "message")
      .containsEntry("isMine", true);

    ArgumentCaptor<ChatActivityEventEntity> eventCaptor = ArgumentCaptor.forClass(ChatActivityEventEntity.class);
    verify(chatActivityEventRepository).save(eventCaptor.capture());
    assertThat(eventCaptor.getValue().getGroup()).isEqualTo(group);
    assertThat(eventCaptor.getValue().getActorUser()).isEqualTo(currentUser);
    assertThat(eventCaptor.getValue().getEventType()).isEqualTo("chat.message");
    assertThat(eventCaptor.getValue().getPayload()).contains("\"message\":\"새 메시지입니다\"");
    verify(outboxService).record(eq("chat.message"), eq("chat_activity_event"), eq(eventCaptor.getValue().getId()), any());
    verify(chatRealtimePublisher).publishMessage(eq("1"), any());
  }

  @Test
  void postMessageAllowsBlankTextWhenImageAttachmentExists() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(chatActivityEventRepository.save(any(ChatActivityEventEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = service.createMessage(
      "1",
      currentUser.getId(),
      new CreateChatMessageRequest(
        " ",
        List.of(new ChatMessageAttachmentRequest(
          "image",
          "records/media/photo-1.jpg",
          "/api/v1/media/public?key=records%2Fmedia%2Fphoto-1.jpg",
          "image/jpeg",
          "photo.jpg",
          null,
          null
        ))
      )
    );

    assertThat(response)
      .containsEntry("message", "")
      .containsEntry("messageType", "message");
    List<Map<String, Object>> responseAttachments = attachments(response);
    assertThat(responseAttachments).hasSize(1);
    assertThat(responseAttachments.getFirst())
      .containsEntry("type", "image")
      .containsEntry("storageKey", "records/media/photo-1.jpg")
      .containsEntry("publicUrl", "/api/v1/media/public?key=records%2Fmedia%2Fphoto-1.jpg")
      .containsEntry("contentType", "image/jpeg")
      .containsEntry("fileName", "photo.jpg");

    ArgumentCaptor<ChatActivityEventEntity> eventCaptor = ArgumentCaptor.forClass(ChatActivityEventEntity.class);
    verify(chatActivityEventRepository).save(eventCaptor.capture());
    assertThat(eventCaptor.getValue().getPayload()).contains("\"attachments\"");
    verify(outboxService).record(eq("chat.message"), eq("chat_activity_event"), eq(eventCaptor.getValue().getId()), any());
    verify(chatRealtimePublisher).publishMessage(eq("1"), any());
  }

  @Test
  void postMessageRejectsUnsupportedAttachmentType() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);

    assertThatThrownBy(() -> service.createMessage(
        "1",
        currentUser.getId(),
        new CreateChatMessageRequest(
          "파일",
          List.of(new ChatMessageAttachmentRequest(
            "file",
            "records/media/file.pdf",
            "/api/v1/media/public?key=records%2Fmedia%2Ffile.pdf",
            "application/pdf",
            "file.pdf",
            null,
            null
          ))
        )
      ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
  }

  @Test
  void eventsChecksMembershipAndReplaysMessagesAfterCursor() {
    ChatActivityEventEntity replayMessage = new ChatActivityEventEntity(
      group,
      otherUser,
      "chat.message",
      "{\"senderName\":\"지민\",\"message\":\"놓친 메시지\"}",
      Instant.parse("2026-06-09T05:03:00Z")
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(chatActivityEventRepository.findPageAfter(
      eq(group),
      eq(Instant.parse("2026-06-09T05:02:00Z")),
      any(Pageable.class)
    )).thenReturn(List.of(replayMessage));

    service.events("1", currentUser.getId(), "2026-06-09T05:02:00Z");

    @SuppressWarnings({ "rawtypes", "unchecked" })
    ArgumentCaptor<List<Map<String, Object>>> replayCaptor = ArgumentCaptor.forClass((Class) List.class);
    verify(chatRealtimePublisher).subscribe(eq("1"), eq(currentUser.getPublicId()), replayCaptor.capture());
    assertThat(replayCaptor.getValue()).hasSize(1);
    assertThat(replayCaptor.getValue().getFirst())
      .containsEntry("id", replayMessage.getId().toString())
      .containsEntry("message", "놓친 메시지")
      .containsEntry("isMine", false);
  }

  @Test
  void nonMemberCannotSubscribeGroupEvents() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(false);

    assertThatThrownBy(() -> service.events("1", currentUser.getId(), null))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));
  }

  @Test
  void postMessageRejectsBlankMessage() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);

    assertThatThrownBy(() -> service.createMessage("1", currentUser.getId(), new CreateChatMessageRequest(" ")))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
  }

  @Test
  void missingGroupReturnsNotFound() {
    when(groupRepository.findByPublicId("missing")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.messages("missing", currentUser.getId(), null, null))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  @Test
  void nonMemberCannotReadGroupMessages() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(false);

    assertThatThrownBy(() -> service.messages("1", currentUser.getId(), null, null))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));
  }

  @Test
  void nonMemberCannotCreateGroupMessage() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(false);

    assertThatThrownBy(() -> service.createMessage("1", currentUser.getId(), new CreateChatMessageRequest("안녕")))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));
  }

  @Test
  void systemMessagesAndCardPayloadUseSafeFallbacks() {
    ChatActivityEventEntity systemMessage = new ChatActivityEventEntity(
      group,
      null,
      "system.message",
      "{}",
      Instant.parse("2026-06-09T05:03:00Z")
    );
    ChatActivityEventEntity cardMessage = new ChatActivityEventEntity(
      group,
      null,
      "vote.created",
      "{\"cardType\":\"vote_card\",\"content\":\"\"}",
      Instant.parse("2026-06-09T05:04:00Z")
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(chatActivityEventRepository.findPageBefore(eq(group), isNull(), any(Pageable.class)))
      .thenReturn(List.of(cardMessage, systemMessage));
    stubUnread(0L);

    List<Map<String, Object>> messages = messages(service.messages("1", currentUser.getId(), null, null));

    assertThat(messages.getFirst())
      .containsEntry("senderUserId", null)
      .containsEntry("senderName", "ONMU")
      .containsEntry("message", "새 활동이 있어요.")
      .containsEntry("messageType", "system")
      .containsEntry("isMine", false);
    assertThat(messages.get(1))
      .containsEntry("message", "새 활동이 있어요.")
      .containsEntry("messageType", "vote_card")
      .containsEntry("cardType", "vote_card");
  }

  @Test
  void markReadUpdatesLastReadCursorAndReturnsUnreadCount() {
    ChatActivityEventEntity lastMessage = new ChatActivityEventEntity(
      group,
      otherUser,
      "chat.message",
      "{\"message\":\"읽은 메시지\"}",
      Instant.parse("2026-06-09T05:05:00Z")
    );
    ChatReadStateEntity readState = new ChatReadStateEntity(
      group,
      currentUser,
      null,
      Instant.parse("2026-06-09T05:04:00Z")
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(chatActivityEventRepository.findByIdAndGroup(lastMessage.getId(), group)).thenReturn(Optional.of(lastMessage));
    when(chatReadStateRepository.findByGroupAndUser(group, currentUser)).thenReturn(Optional.of(readState));
    when(chatReadStateRepository.save(any(ChatReadStateEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(chatActivityEventRepository.countUnreadAfter(group, currentUser.getId(), lastMessage.getCreatedAt()))
      .thenReturn(0L);

    Map<String, Object> response = service.markRead(
      "1",
      currentUser.getId(),
      new UpdateChatReadStateRequest(lastMessage.getId().toString())
    );

    assertThat(response)
      .containsEntry("lastReadMessageId", lastMessage.getId().toString())
      .containsEntry("lastReadAt", "2026-06-09T05:05:00Z")
      .containsEntry("unreadCount", 0L);
  }

  @SuppressWarnings("unchecked")
  private List<Map<String, Object>> messages(Map<String, Object> response) {
    return (List<Map<String, Object>>) response.get("messages");
  }

  @SuppressWarnings("unchecked")
  private List<Map<String, Object>> attachments(Map<String, Object> response) {
    return (List<Map<String, Object>>) response.get("attachments");
  }

  private void stubUnread(long count) {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(chatReadStateRepository.findByGroupAndUser(group, currentUser)).thenReturn(Optional.empty());
    when(chatActivityEventRepository.countUnreadAfter(group, currentUser.getId(), null)).thenReturn(count);
  }
}
