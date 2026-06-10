package com.onmu.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.config.AuthProperties;
import com.onmu.api.domain.UserEntity;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Component;

@Component
public class AccessTokenIssuer {
  private static final Base64.Encoder BASE64_URL_ENCODER = Base64.getUrlEncoder().withoutPadding();

  private final AuthProperties properties;
  private final ObjectMapper objectMapper;

  public AccessTokenIssuer(AuthProperties properties, ObjectMapper objectMapper) {
    this.properties = properties;
    this.objectMapper = objectMapper;
  }

  public IssuedAccessToken issue(UserEntity user) {
    Instant issuedAt = Instant.now();
    Instant expiresAt = issuedAt.plus(properties.accessTokenTtl());

    Map<String, Object> header = new LinkedHashMap<>();
    header.put("alg", "HS256");
    header.put("typ", "JWT");

    Map<String, Object> claims = new LinkedHashMap<>();
    claims.put("iss", properties.issuer());
    claims.put("aud", properties.audience());
    claims.put("sub", user.getPublicId());
    claims.put("iat", issuedAt.getEpochSecond());
    claims.put("exp", expiresAt.getEpochSecond());
    claims.put("typ", "access");

    String encodedHeader = encodeJson(header);
    String encodedClaims = encodeJson(claims);
    String signingInput = encodedHeader + "." + encodedClaims;
    return new IssuedAccessToken(signingInput + "." + hmacSha256(signingInput), expiresAt);
  }

  private String encodeJson(Map<String, Object> value) {
    try {
      return BASE64_URL_ENCODER.encodeToString(objectMapper.writeValueAsBytes(value));
    } catch (Exception exception) {
      throw new IllegalStateException("Could not encode access token", exception);
    }
  }

  private String hmacSha256(String signingInput) {
    try {
      Mac mac = Mac.getInstance("HmacSHA256");
      mac.init(new SecretKeySpec(properties.accessTokenSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
      return BASE64_URL_ENCODER.encodeToString(mac.doFinal(signingInput.getBytes(StandardCharsets.US_ASCII)));
    } catch (Exception exception) {
      throw new IllegalStateException("access token issuer is not initialized", exception);
    }
  }

  public record IssuedAccessToken(String token, Instant expiresAt) {
  }
}
