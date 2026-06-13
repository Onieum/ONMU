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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "notification_preferences")
public class NotificationPreferenceEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "notification_type", nullable = false)
  private String notificationType;

  @Column(nullable = false)
  private String channel;

  @Column(nullable = false)
  private boolean enabled;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "quiet_hours", columnDefinition = "jsonb", nullable = false)
  private String quietHours;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected NotificationPreferenceEntity() {
  }

  public NotificationPreferenceEntity(
    UserEntity user,
    String notificationType,
    String channel,
    boolean enabled,
    String quietHours
  ) {
    this.id = UUID.randomUUID();
    this.user = user;
    this.notificationType = notificationType;
    this.channel = channel;
    this.enabled = enabled;
    this.quietHours = quietHours == null || quietHours.isBlank() ? "{}" : quietHours;
    this.updatedAt = Instant.now();
  }

  public UserEntity getUser() {
    return user;
  }

  public String getNotificationType() {
    return notificationType;
  }

  public String getChannel() {
    return channel;
  }

  public boolean isEnabled() {
    return enabled;
  }

  public String getQuietHours() {
    return quietHours;
  }

  public void update(boolean enabled, String quietHours) {
    this.enabled = enabled;
    this.quietHours = quietHours == null || quietHours.isBlank() ? "{}" : quietHours;
    this.updatedAt = Instant.now();
  }
}
