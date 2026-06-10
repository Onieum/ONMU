package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
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

  @Column(name = "display_name", nullable = false)
  private String displayName;

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

  @Column(name = "updated_at", insertable = false)
  private Instant updatedAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  protected UserEntity() {
  }

  public UserEntity(String publicId, String displayName, String email, String profileImageUrl) {
    this.id = UUID.randomUUID();
    this.publicId = Objects.requireNonNull(publicId);
    this.displayName = Objects.requireNonNull(displayName);
    this.email = email;
    this.profileImageUrl = profileImageUrl;
    this.pixelCharacter = "{}";
    this.preferenceProfile = "{}";
    this.onboardingStatus = "PENDING";
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public String getDisplayName() {
    return displayName;
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
    String displayName,
    String profileImageUrl,
    String preferenceProfile,
    String pixelCharacter,
    String onboardingStatus
  ) {
    if (displayName != null && !displayName.isBlank()) {
      this.displayName = displayName.trim();
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
}
