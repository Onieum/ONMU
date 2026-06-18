package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.CharacterService;
import com.onmu.api.web.dto.CharacterGenerateRequest;
import com.onmu.api.web.dto.CharacterProfileResponse;
import com.onmu.api.web.dto.CharacterSkipRequest;
import com.onmu.api.web.dto.UpdateCharacterRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1")
public class CharacterController {
  private final CharacterService characterService;

  public CharacterController(CharacterService characterService) {
    this.characterService = characterService;
  }

  @GetMapping("/users/me/character")
  public ResponseEntity<CharacterProfileResponse> getMyCharacter(
      @AuthenticationPrincipal AuthenticatedUser user
  ) {
    CharacterProfileResponse response = characterService.getMyCharacter(user.userId());
    return ResponseEntity.ok(response);
  }

  @PutMapping("/users/me/character")
  public ResponseEntity<CharacterProfileResponse> saveMyCharacter(
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody UpdateCharacterRequest request
  ) {
    CharacterProfileResponse response = characterService.saveMyCharacter(user.userId(), request);
    return ResponseEntity.ok(response);
  }

  @PostMapping("/users/me/character/generate")
  public ResponseEntity<CharacterProfileResponse> generateCharacter(
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody CharacterGenerateRequest request
  ) {
    CharacterProfileResponse response = characterService.generateCharacter(user.userId(), request);
    return ResponseEntity.ok(response);
  }

  @PatchMapping("/users/me/onboarding/character-skip")
  public ResponseEntity<CharacterProfileResponse> updateSkipStatus(
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody CharacterSkipRequest request
  ) {
    CharacterProfileResponse response = characterService.updateSkipStatus(user.userId(), request);
    return ResponseEntity.ok(response);
  }
}
