package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.CreateChatMessageRequest;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
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
  private GroupRepository groupRepository;
  @Mock
  private UserRepository userRepository;

  private ChatActivityService service;
  private GroupEntity group;
  private UserEntity currentUser;
  private UserEntity otherUser;

  @BeforeEach
  void setUp() {
    service = new ChatActivityService(
      chatActivityEventRepository,
      groupRepository,
      userRepository,
      new ObjectMapper()
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
    when(chatActivityEventRepository.findByGroupOrderByCreatedAtAsc(group))
      .thenReturn(List.of(otherMessage, myMessage));

    Map<String, Object> response = service.messages("1", currentUser.getId());

    List<Map<String, Object>> messages = messages(response);
    assertThat(messages).hasSize(2);
    assertThat(messages.getFirst())
      .containsEntry("senderUserId", otherUser.getPublicId())
      .containsEntry("senderName", "지민")
      .containsEntry("message", "다들 안녕! 드디어 다음 주에 제주도네 날씨도 좋아 보이더라구.")
      .containsEntry("messageType", "message")
      .containsEntry("isMine", false)
      .containsEntry("timeLabel", "14:00");
    assertThat(messages.get(1))
      .containsEntry("senderUserId", currentUser.getPublicId())
      .containsEntry("message", "기대된다아 ㅎㅎ")
      .containsEntry("isMine", true)
      .containsEntry("timeLabel", "14:01");
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

    assertThatThrownBy(() -> service.messages("missing", currentUser.getId()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  @Test
  void nonMemberCannotReadGroupMessages() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(false);

    assertThatThrownBy(() -> service.messages("1", currentUser.getId()))
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
    when(chatActivityEventRepository.findByGroupOrderByCreatedAtAsc(group))
      .thenReturn(List.of(systemMessage, cardMessage));

    List<Map<String, Object>> messages = messages(service.messages("1", currentUser.getId()));

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

  @SuppressWarnings("unchecked")
  private List<Map<String, Object>> messages(Map<String, Object> response) {
    return (List<Map<String, Object>>) response.get("messages");
  }
}
