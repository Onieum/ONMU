package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.FriendResponse;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

@ExtendWith(MockitoExtension.class)
class FriendServiceTests {
  @Mock
  private JdbcTemplate jdbcTemplate;

  @Mock
  private UserRepository userRepository;

  @Test
  void friendsUseSavedCharacterProfileBeforeLegacyUserPixelCharacter() {
    UUID userId = UUID.fromString("00000000-0000-0000-0000-000000000099");
    UserEntity user = new UserEntity(userId, "viewer");
    FriendService service = new FriendService(jdbcTemplate, userRepository, new ObjectMapper());
    when(userRepository.findByIdAndDeletedAtIsNull(userId)).thenReturn(Optional.of(user));
    when(jdbcTemplate.query(
      anyString(),
      any(RowMapper.class),
      eq(userId),
      eq(userId),
      eq(userId),
      eq(userId)
    )).thenReturn(List.<FriendResponse>of());

    service.friends(userId);

    ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
    verify(jdbcTemplate).query(
      sql.capture(),
      any(RowMapper.class),
      eq(userId),
      eq(userId),
      eq(userId),
      eq(userId)
    );
    assertThat(sql.getValue())
      .contains("left join character_profiles cp on cp.user_id = friend.id")
      .contains("jsonb_build_object")
      .contains("'eyeStyle', cp.eye_style")
      .contains("when cp.user_id is null then friend.pixel_character");
  }
}
