package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.domain.UserEntity;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class UserAvatarReadModelMapper {
  private final CharacterProfileRepository characterProfileRepository;
  private final ObjectMapper objectMapper;

  public UserAvatarReadModelMapper(
    CharacterProfileRepository characterProfileRepository,
    ObjectMapper objectMapper
  ) {
    this.characterProfileRepository = characterProfileRepository;
    this.objectMapper = objectMapper;
  }

  public void putAvatar(Map<String, Object> value, UserEntity user) {
    value.put("profileImageUrl", profileImageUrl(user));
    value.put("pixelCharacter", pixelCharacter(user));
  }

  public void putPrefixedAvatar(Map<String, Object> value, String prefix, UserEntity user) {
    value.put(prefix + "ProfileImageUrl", profileImageUrl(user));
    value.put(prefix + "PixelCharacter", pixelCharacter(user));
  }

  public String profileImageUrl(UserEntity user) {
    if (user == null || user.getProfileImageUrl() == null || user.getProfileImageUrl().isBlank()) {
      return "";
    }
    return user.getProfileImageUrl().trim();
  }

  public Map<String, Object> pixelCharacter(UserEntity user) {
    if (user == null || user.getId() == null) {
      return Map.of();
    }
    return characterProfileRepository.findByUserId(user.getId())
      .map(this::characterProfile)
      .orElseGet(() -> readJsonObject(user.getPixelCharacter()));
  }

  private Map<String, Object> characterProfile(CharacterProfileEntity character) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("gender", character.getGender());
    value.put("skinTone", character.getSkinTone());
    value.put("hairStyle", character.getHairStyle());
    value.put("hairColor", character.getHairColor());
    value.put("eyeStyle", character.getEyeStyle());
    value.put("eyeColor", character.getEyeColor());
    value.put("clothes", character.getClothes());
    return value;
  }

  private Map<String, Object> readJsonObject(String payload) {
    if (payload == null || payload.isBlank()) {
      return Map.of();
    }
    try {
      Map<?, ?> parsed = objectMapper.readValue(payload, Map.class);
      Map<String, Object> values = new LinkedHashMap<>();
      parsed.forEach((key, value) -> values.put(String.valueOf(key), value));
      return values;
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }
}
