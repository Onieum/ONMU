package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.web.dto.NotificationItemResponse;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTests {
  @Mock
  private NotificationRepository notificationRepository;

  private NotificationService service;
  private UserEntity currentUser;
  private UserEntity otherUser;
  private GroupEntity group;
  private PlanEntity plan;

  @BeforeEach
  void setUp() {
    service = new NotificationService(notificationRepository, new ObjectMapper());
    currentUser = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000002"), "지민");
    otherUser = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000003"), "민수");
    group = new GroupEntity("1", "제주 여행 모임", currentUser);
    plan = new PlanEntity("101", group, "제주도 여행", Instant.parse("2026-06-20T02:00:00Z"), "scheduled");
  }

  @Test
  void inboxRequestsOnlyCurrentUserNotificationsWithBoundedLimit() {
    when(notificationRepository.findInboxByUserId(eq(currentUser.getId()), any(Pageable.class)))
      .thenReturn(List.of(notification(
        currentUser,
        group,
        plan,
        "vote_created",
        "{\"groupId\":\"legacy-group\",\"planId\":\"legacy-plan\",\"voteId\":\"501\"}",
        null,
        Instant.parse("2026-06-09T05:11:00Z")
      )));

    List<NotificationItemResponse> notifications = service.inbox(currentUser.getId(), 1000);

    ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
    org.mockito.Mockito.verify(notificationRepository)
      .findInboxByUserId(eq(currentUser.getId()), pageableCaptor.capture());
    assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(100);
    assertThat(notifications).singleElement().satisfies(notification -> {
      assertThat(notification.notificationType()).isEqualTo("vote_created");
      assertThat(notification.type()).isEqualTo("vote_created");
      assertThat(notification.groupId()).isEqualTo("1");
      assertThat(notification.planId()).isEqualTo("101");
      assertThat(notification.payload()).containsEntry("voteId", "501");
      assertThat(notification.isRead()).isFalse();
      assertThat(notification.timeLabel()).isEqualTo("14:11");
    });
  }

  @Test
  void inboxPreservesRepositoryOrderAndPayloadFallbackIds() {
    NotificationEntity newest = notification(
      currentUser,
      null,
      null,
      "settlement_created",
      "{\"groupId\":\"1\",\"planId\":\"103\",\"settlementId\":\"301\"}",
      Instant.parse("2026-06-09T05:13:00Z"),
      Instant.parse("2026-06-09T05:13:00Z")
    );
    NotificationEntity older = notification(
      currentUser,
      group,
      plan,
      "record_created",
      "{\"recordId\":\"memory-1002\"}",
      null,
      Instant.parse("2026-06-09T05:12:00Z")
    );
    when(notificationRepository.findInboxByUserId(eq(currentUser.getId()), any(Pageable.class)))
      .thenReturn(List.of(newest, older));

    List<NotificationItemResponse> notifications = service.inbox(currentUser.getId(), 2);

    assertThat(notifications).extracting(NotificationItemResponse::notificationType)
      .containsExactly("settlement_created", "record_created");
    assertThat(notifications.getFirst())
      .satisfies(notification -> {
        assertThat(notification.groupId()).isEqualTo("1");
        assertThat(notification.planId()).isEqualTo("103");
        assertThat(notification.payload()).containsEntry("settlementId", "301");
        assertThat(notification.isRead()).isTrue();
      });
  }

  @Test
  void inboxDoesNotMixOtherUsersWhenRepositoryReceivesCurrentUserId() {
    when(notificationRepository.findInboxByUserId(eq(otherUser.getId()), any(Pageable.class)))
      .thenReturn(List.of(notification(
        otherUser,
        group,
        plan,
        "place_candidate_created",
        "{\"groupId\":\"1\",\"planId\":\"101\",\"candidateId\":\"204\"}",
        null,
        Instant.parse("2026-06-09T05:10:00Z")
      )));

    List<NotificationItemResponse> notifications = service.inbox(otherUser.getId(), null);

    assertThat(notifications).hasSize(1);
    org.mockito.Mockito.verify(notificationRepository)
      .findInboxByUserId(eq(otherUser.getId()), any(Pageable.class));
  }

  @Test
  void unreadCountReturnsCurrentUserUnreadCount() {
    when(notificationRepository.countByUser_IdAndReadAtIsNull(currentUser.getId()))
      .thenReturn(3L);

    var response = service.unreadCount(currentUser.getId());

    assertThat(response.unreadCount()).isEqualTo(3L);
  }

  @Test
  void markReadUpdatesOnlyCurrentUserNotification() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001211");
    NotificationEntity notification = notification(
      currentUser,
      group,
      plan,
      "chat_message",
      "{\"groupId\":\"1\",\"messageId\":\"message-1\"}",
      null,
      Instant.parse("2026-06-09T05:12:00Z")
    );
    when(notificationRepository.findInboxItemByIdAndUserId(notificationId, currentUser.getId()))
      .thenReturn(Optional.of(notification));

    NotificationItemResponse response = service.markRead(currentUser.getId(), notificationId);

    assertThat(response.id()).isEqualTo(notification.getId().toString());
    assertThat(response.isRead()).isTrue();
    assertThat(response.readAt()).isNotBlank();
    assertThat(response.status()).isEqualTo("read");
  }

  @Test
  void markReadRejectsOtherUsersNotification() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001212");
    when(notificationRepository.findInboxItemByIdAndUserId(notificationId, currentUser.getId()))
      .thenReturn(Optional.empty());

    org.assertj.core.api.Assertions.assertThatThrownBy(
        () -> service.markRead(currentUser.getId(), notificationId)
      )
      .isInstanceOf(ResponseStatusException.class)
      .hasMessageContaining("notification_not_found");
  }

  @Test
  void markAllReadReturnsUpdatedCount() {
    when(notificationRepository.markUnreadAsReadByUserId(eq(currentUser.getId()), any(Instant.class)))
      .thenReturn(2);

    var response = service.markAllRead(currentUser.getId());

    assertThat(response.updatedCount()).isEqualTo(2);
  }

  private NotificationEntity notification(
    UserEntity user,
    GroupEntity group,
    PlanEntity plan,
    String type,
    String payload,
    Instant readAt,
    Instant createdAt
  ) {
    return new NotificationEntity(
      user,
      group,
      plan,
      type,
      "알림 제목",
      "알림 본문",
      payload,
      readAt == null ? "queued" : "read",
      readAt,
      createdAt
    );
  }
}
