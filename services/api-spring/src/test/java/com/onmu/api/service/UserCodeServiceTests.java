package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.onmu.api.domain.UserEntity;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

@ExtendWith(MockitoExtension.class)
class UserCodeServiceTests {
  @Mock
  private JdbcTemplate jdbcTemplate;

  @Test
  void createsNumericTenDigitCodeForNewUser() {
    UserEntity user = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000099"), "ONMU User");
    UserCodeService service = new UserCodeService(jdbcTemplate, () -> "4839201746");
    when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq(user.getId())))
      .thenReturn(List.of());
    when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq(user.getId()), eq("4839201746"), eq(UserCodeService.CODE_FORMAT)))
      .thenReturn(List.of("4839201746"));

    String code = service.ensureActiveCode(user);

    assertThat(code).isEqualTo("4839201746").matches("\\d{10}");
  }

  @Test
  void returnsExistingActiveCodeWithoutCreatingAnother() {
    UserEntity user = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000099"), "ONMU User");
    UserCodeService service = new UserCodeService(jdbcTemplate, () -> "4839201746");
    when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq(user.getId())))
      .thenReturn(List.of("1234567890"));

    String code = service.ensureActiveCode(user);

    assertThat(code).isEqualTo("1234567890");
    verify(jdbcTemplate, never()).queryForList(anyString(), eq(String.class), any(), any(), any());
  }

  @Test
  void retriesWhenGeneratedCodeCollides() {
    UserEntity user = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000099"), "ONMU User");
    String[] candidates = {"1111111111", "2222222222"};
    int[] index = {0};
    UserCodeService service = new UserCodeService(jdbcTemplate, () -> candidates[index[0]++]);
    when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq(user.getId())))
      .thenReturn(List.of(), List.of(), List.of());
    when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq(user.getId()), eq("1111111111"), eq(UserCodeService.CODE_FORMAT)))
      .thenReturn(List.of());
    when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq(user.getId()), eq("2222222222"), eq(UserCodeService.CODE_FORMAT)))
      .thenReturn(List.of("2222222222"));

    String code = service.ensureActiveCode(user);

    assertThat(code).isEqualTo("2222222222");
    verify(jdbcTemplate, times(2)).queryForList(anyString(), eq(String.class), eq(user.getId()), any(), eq(UserCodeService.CODE_FORMAT));
  }
}
