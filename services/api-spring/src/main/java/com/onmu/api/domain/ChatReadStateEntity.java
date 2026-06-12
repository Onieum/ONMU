package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "chat_read_states")
public class ChatReadStateEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id", nullable = false)
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "last_read_event_id")
  private ChatActivityEventEntity lastReadEvent;

  @Column(name = "last_read_at", nullable = false)
  private Instant lastReadAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected ChatReadStateEntity() {
  }

  public ChatReadStateEntity(GroupEntity group, UserEntity user, ChatActivityEventEntity lastReadEvent, Instant now) {
    this.id = UUID.randomUUID();
    this.group = group;
    this.user = user;
    markRead(lastReadEvent, now);
  }

  public void markRead(ChatActivityEventEntity event, Instant now) {
    this.lastReadEvent = event;
    this.lastReadAt = event == null ? now : event.getCreatedAt();
    this.updatedAt = now;
  }

  public ChatActivityEventEntity getLastReadEvent() {
    return lastReadEvent;
  }

  public Instant getLastReadAt() {
    return lastReadAt;
  }
}
