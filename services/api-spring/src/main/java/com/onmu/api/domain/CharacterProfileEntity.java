package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "character_profiles")
public class CharacterProfileEntity {
  @Id
  private UUID id;

  @Column(name = "user_id", nullable = false, unique = true)
  private UUID userId;

  @Column(name = "skin_tone", nullable = false)
  private String skinTone;

  @Column(name = "hair_style", nullable = false)
  private String hairStyle;

  @Column(name = "hair_color", nullable = false)
  private String hairColor;

  @Column(name = "eye_style", nullable = false)
  private String eyeStyle;

  @Column(name = "eye_color", nullable = false)
  private String eyeColor;

  @Column(nullable = false)
  private String clothes;

  @Column(nullable = false)
  private boolean skipped;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected CharacterProfileEntity() {
  }

  public CharacterProfileEntity(UUID userId, String skinTone, String hairStyle, String hairColor, String eyeStyle, String eyeColor, String clothes) {
    this.id = UUID.randomUUID();
    this.userId = userId;
    this.skinTone = skinTone;
    this.hairStyle = hairStyle;
    this.hairColor = hairColor;
    this.eyeStyle = eyeStyle;
    this.eyeColor = eyeColor;
    this.clothes = clothes;
    this.skipped = false;
    this.updatedAt = Instant.now();
  }

  public UUID getId() {
    return id;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getSkinTone() {
    return skinTone;
  }

  public void setSkinTone(String skinTone) {
    this.skinTone = skinTone;
  }

  public String getHairStyle() {
    return hairStyle;
  }

  public void setHairStyle(String hairStyle) {
    this.hairStyle = hairStyle;
  }

  public String getHairColor() {
    return hairColor;
  }

  public void setHairColor(String hairColor) {
    this.hairColor = hairColor;
  }

  public String getEyeStyle() {
    return eyeStyle;
  }

  public void setEyeStyle(String eyeStyle) {
    this.eyeStyle = eyeStyle;
  }

  public String getEyeColor() {
    return eyeColor;
  }

  public void setEyeColor(String eyeColor) {
    this.eyeColor = eyeColor;
  }

  public String getClothes() {
    return clothes;
  }

  public void setClothes(String clothes) {
    this.clothes = clothes;
  }

  public boolean isSkipped() {
    return skipped;
  }

  public void setSkipped(boolean skipped) {
    this.skipped = skipped;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void setUpdatedAt(Instant updatedAt) {
    this.updatedAt = updatedAt;
  }
}
