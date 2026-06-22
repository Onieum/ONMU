package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "users")
public class UserEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @Column(name = "nickname", nullable = false)
  private String nickname;

  @Column(name = "email")
  private String email;

  @Column(name = "profile_image_url")
  private String profileImageUrl;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "pixel_character", columnDefinition = "jsonb", nullable = false)
  private String pixelCharacter;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "preference_profile", columnDefinition = "jsonb", nullable = false)
  private String preferenceProfile;

  @Column(name = "onboarding_status", nullable = false)
  private String onboardingStatus;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  protected UserEntity() {
  }

  public UserEntity(String publicId, String nickname, String email, String profileImageUrl) {
    this.id = UUID.randomUUID();
    this.publicId = Objects.requireNonNull(publicId);
    this.nickname = Objects.requireNonNull(nickname);
    this.email = email;
    this.profileImageUrl = profileImageUrl;
    this.pixelCharacter = "{}";
    this.preferenceProfile = "{}";
    this.onboardingStatus = "PENDING";
    this.updatedAt = Instant.now();
  }

  public UserEntity(UUID id, String nickname) {
    this.id = Objects.requireNonNull(id);
    this.publicId = "usr_" + id.toString().replace("-", "");
    this.nickname = Objects.requireNonNull(nickname);
    this.pixelCharacter = "{}";
    this.preferenceProfile = "{}";
    this.onboardingStatus = "PENDING";
    this.updatedAt = Instant.now();
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public String getNickname() {
    return nickname;
  }

  public String getEmail() {
    return email;
  }

  public String getProfileImageUrl() {
    return profileImageUrl;
  }

  public String getPixelCharacter() {
    return pixelCharacter;
  }

  public String getPreferenceProfile() {
    return preferenceProfile;
  }

  public String getOnboardingStatus() {
    return onboardingStatus;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public Instant getDeletedAt() {
    return deletedAt;
  }

  public void updateProfile(
    String nickname,
    String profileImageUrl,
    String preferenceProfile,
    String pixelCharacter,
    String onboardingStatus
  ) {
    if (nickname != null && !nickname.isBlank()) {
      this.nickname = nickname.trim();
    }
    if (profileImageUrl != null) {
      this.profileImageUrl = profileImageUrl.isBlank() ? null : profileImageUrl.trim();
    }
    if (preferenceProfile != null) {
      this.preferenceProfile = preferenceProfile;
    }
    if (pixelCharacter != null) {
      this.pixelCharacter = pixelCharacter;
    }
    if (onboardingStatus != null && !onboardingStatus.isBlank()) {
      this.onboardingStatus = onboardingStatus.trim();
    }
  }

  public void markDeleted(Instant deletedAt) {
    this.deletedAt = Objects.requireNonNull(deletedAt);
  }

  @PrePersist
  @PreUpdate
  void touchUpdatedAt() {
    this.updatedAt = Instant.now();
  }
}
