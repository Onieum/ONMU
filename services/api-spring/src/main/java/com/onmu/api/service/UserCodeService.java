package com.onmu.api.service;

import com.onmu.api.domain.UserEntity;
import java.security.SecureRandom;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class UserCodeService {
  public static final String CODE_FORMAT = "NUMERIC_10";
  private static final int CODE_LENGTH = 10;
  private static final int MAX_GENERATION_ATTEMPTS = 12;
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  private final JdbcTemplate jdbcTemplate;
  private final Supplier<String> codeSupplier;

  public UserCodeService(JdbcTemplate jdbcTemplate) {
    this(jdbcTemplate, UserCodeService::randomNumericCode);
  }

  UserCodeService(JdbcTemplate jdbcTemplate, Supplier<String> codeSupplier) {
    this.jdbcTemplate = jdbcTemplate;
    this.codeSupplier = codeSupplier;
  }

  public String ensureActiveCode(UserEntity user) {
    Optional<String> existing = findActiveCode(user.getId());
    if (existing.isPresent()) {
      return existing.get();
    }

    for (int attempt = 0; attempt < MAX_GENERATION_ATTEMPTS; attempt += 1) {
      String candidate = codeSupplier.get();
      if (!isNumeric10(candidate)) {
        throw new IllegalStateException("Generated user code does not match NUMERIC_10");
      }
      List<String> inserted = jdbcTemplate.queryForList(
        """
          insert into user_codes (user_id, code, code_format, status)
          values (?, ?, ?, 'active')
          on conflict do nothing
          returning code
        """,
        String.class,
        user.getId(),
        candidate,
        CODE_FORMAT
      );
      if (!inserted.isEmpty()) {
        return inserted.getFirst();
      }
      existing = findActiveCode(user.getId());
      if (existing.isPresent()) {
        return existing.get();
      }
    }
    throw new IllegalStateException("Could not allocate unique user code");
  }

  public Optional<String> findActiveCode(UUID userId) {
    List<String> codes = jdbcTemplate.queryForList(
      """
        select code
        from user_codes
        where user_id = ?
          and status = 'active'
        order by created_at desc
        limit 1
      """,
      String.class,
      userId
    );
    return codes.stream().findFirst();
  }

  private static String randomNumericCode() {
    StringBuilder value = new StringBuilder(CODE_LENGTH);
    for (int index = 0; index < CODE_LENGTH; index += 1) {
      value.append(SECURE_RANDOM.nextInt(10));
    }
    return value.toString();
  }

  private boolean isNumeric10(String value) {
    return value != null && value.matches("\\d{10}");
  }
}
