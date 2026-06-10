package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.CharacterGenerateRequest;
import com.onmu.api.web.dto.CharacterSkipRequest;
import com.onmu.api.web.dto.UpdateCharacterRequest;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CharacterServiceTests {
  @Mock
  private CharacterProfileRepository characterProfileRepository;

  @Mock
  private UserRepository userRepository;

  private CharacterService service;
  private UserEntity user;

  @BeforeEach
  void setUp() {
    service = new CharacterService(characterProfileRepository, userRepository);
    user = org.mockito.Mockito.mock(UserEntity.class);
    when(user.getId()).thenReturn(UUID.fromString("11111111-1111-1111-1111-111111111111"));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
  }

  @Test
  void getMyCharacterReturnsSuccessfully() {
    CharacterProfileEntity entity = new CharacterProfileEntity(
      user.getId(), "warm", "short", "black", "round", "brown", "tshirt"
    );
    when(characterProfileRepository.findByUserId(user.getId())).thenReturn(Optional.of(entity));

    var response = service.getMyCharacter();

    assertThat(response.userId()).isEqualTo(user.getId());
    assertThat(response.skinTone()).isEqualTo("warm");
    assertThat(response.hairStyle()).isEqualTo("short");
  }

  @Test
  void saveMyCharacterSavesAndReturns() {
    UpdateCharacterRequest request = new UpdateCharacterRequest(
      "warm", "neat_parted", "blonde", "round", "blue", "suit"
    );
    when(characterProfileRepository.findByUserId(user.getId())).thenReturn(Optional.empty());
    when(characterProfileRepository.save(any(CharacterProfileEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.saveMyCharacter(request);

    assertThat(response.userId()).isEqualTo(user.getId());
    assertThat(response.hairStyle()).isEqualTo("neat_parted");
    assertThat(response.hairColor()).isEqualTo("blonde");
    verify(characterProfileRepository).save(any(CharacterProfileEntity.class));
  }

  @Test
  void generateCharacterWithGlassKeywords() {
    CharacterGenerateRequest request = new CharacterGenerateRequest("안경 쓴 개발자");
    when(characterProfileRepository.findByUserId(user.getId())).thenReturn(Optional.empty());
    when(characterProfileRepository.save(any(CharacterProfileEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.generateCharacter(request);

    assertThat(response.hairStyle()).isEqualTo("neat_parted");
    assertThat(response.eyeColor()).isEqualTo("dark_gray");
  }

  @Test
  void updateSkipStatusUpdatesSuccessfully() {
    CharacterSkipRequest request = new CharacterSkipRequest(true);
    when(characterProfileRepository.findByUserId(user.getId())).thenReturn(Optional.empty());
    when(characterProfileRepository.save(any(CharacterProfileEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.updateSkipStatus(request);

    assertThat(response.skipped()).isTrue();
  }
}
