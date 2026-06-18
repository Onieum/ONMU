package com.onmu.api.service;

import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.CharacterGenerateRequest;
import com.onmu.api.web.dto.CharacterProfileResponse;
import com.onmu.api.web.dto.CharacterSkipRequest;
import com.onmu.api.web.dto.UpdateCharacterRequest;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CharacterService {
  private final CharacterProfileRepository characterProfileRepository;
  private final UserRepository userRepository;

  public CharacterService(
      CharacterProfileRepository characterProfileRepository,
      UserRepository userRepository
  ) {
    this.characterProfileRepository = characterProfileRepository;
    this.userRepository = userRepository;
  }

  @Transactional(readOnly = true)
  public CharacterProfileResponse getMyCharacter(UUID userId) {
    UserEntity user = user(userId);
    CharacterProfileEntity entity = characterProfileRepository.findByUserId(user.getId())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "character_profile_not_found"));
    return mapToResponse(entity);
  }

  @Transactional
  public CharacterProfileResponse saveMyCharacter(UUID userId, UpdateCharacterRequest request) {
    UserEntity user = user(userId);
    CharacterProfileEntity entity = characterProfileRepository.findByUserId(user.getId())
        .orElseGet(() -> new CharacterProfileEntity(
            user.getId(),
            request.gender(),
            request.skinTone(),
            request.hairStyle(),
            request.hairColor(),
            request.eyeStyle(),
            request.eyeColor(),
            request.clothes()
        ));

    entity.setGender(request.gender());
    entity.setSkinTone(request.skinTone());
    entity.setHairStyle(request.hairStyle());
    entity.setHairColor(request.hairColor());
    entity.setEyeStyle(request.eyeStyle());
    entity.setEyeColor(request.eyeColor());
    entity.setClothes(request.clothes());
    entity.setUpdatedAt(Instant.now());

    CharacterProfileEntity saved = characterProfileRepository.save(entity);
    return mapToResponse(saved);
  }

  @Transactional
  public CharacterProfileResponse generateCharacter(UUID userId, CharacterGenerateRequest request) {
    UserEntity user = user(userId);
    String kw = request.keyword().toLowerCase();
    String gender = "male";
    String skin = "type_warm";
    String hairStyle = "short_curly";
    String hairColor = "dark_brown";
    String eyeStyle = "round";
    String eyeColor = "brown";
    String clothes = "casual_tshirt";

    if (kw.contains("안경") || kw.contains("차분")) {
      hairStyle = "neat_parted";
      eyeColor = "dark_gray";
    }
    if (kw.contains("여성") || kw.contains("여자") || kw.contains("화려")) {
      gender = "female";
      hairStyle = "long_wavy";
      hairColor = "gold";
      eyeColor = "hazel";
    }
    if (kw.contains("힙") || kw.contains("스트릿")) {
      hairStyle = "dreadlocks";
      hairColor = "neon_green";
      clothes = "hoodie";
    }

    final String fGender = gender;
    final String fSkin = skin;
    final String fHairStyle = hairStyle;
    final String fHairColor = hairColor;
    final String fEyeStyle = eyeStyle;
    final String fEyeColor = eyeColor;
    final String fClothes = clothes;

    CharacterProfileEntity entity = characterProfileRepository.findByUserId(user.getId())
        .orElseGet(() -> new CharacterProfileEntity(user.getId(), fGender, fSkin, fHairStyle, fHairColor, fEyeStyle, fEyeColor, fClothes));

    entity.setGender(gender);
    entity.setSkinTone(skin);
    entity.setHairStyle(hairStyle);
    entity.setHairColor(hairColor);
    entity.setEyeStyle(eyeStyle);
    entity.setEyeColor(eyeColor);
    entity.setClothes(clothes);
    entity.setUpdatedAt(Instant.now());

    CharacterProfileEntity saved = characterProfileRepository.save(entity);
    return mapToResponse(saved);
  }

  @Transactional
  public CharacterProfileResponse updateSkipStatus(UUID userId, CharacterSkipRequest request) {
    UserEntity user = user(userId);
    CharacterProfileEntity entity = characterProfileRepository.findByUserId(user.getId())
        .orElseGet(() -> new CharacterProfileEntity(
            user.getId(),
            "female",
            "type_warm",
            "short_black",
            "black",
            "round",
            "brown",
            "casual_tshirt"
        ));

    entity.setSkipped(request.skipped());
    entity.setUpdatedAt(Instant.now());

    CharacterProfileEntity saved = characterProfileRepository.save(entity);
    return mapToResponse(saved);
  }

  private CharacterProfileResponse mapToResponse(CharacterProfileEntity entity) {
    return new CharacterProfileResponse(
        entity.getUserId(),
        entity.getGender(),
        entity.getSkinTone(),
        entity.getHairStyle(),
        entity.getHairColor(),
        entity.getEyeStyle(),
        entity.getEyeColor(),
        entity.getClothes(),
        entity.isSkipped(),
        entity.getUpdatedAt()
    );
  }

  private UserEntity user(UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }
}
