package com.onmu.api.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.config.AuthProperties;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class AccessTokenVerifier {
  private static final Base64.Decoder BASE64_URL_DECODER = Base64.getUrlDecoder();
  private static final Base64.Encoder BASE64_URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };

  private final AuthProperties properties;
  private final ObjectMapper objectMapper;

  public AccessTokenVerifier(AuthProperties properties, ObjectMapper objectMapper) {
    this.properties = properties;
    this.objectMapper = objectMapper;
  }

  public String verify(String token) {
    try {
      String[] parts = token == null ? new String[0] : token.split("\\.");
      if (parts.length != 3) {
        throw unauthorized("malformed_token");
      }

      Map<String, Object> header = readJson(parts[0]);
      if (!"HS256".equals(header.get("alg"))) {
        throw unauthorized("unsupported_token_algorithm");
      }
      verifySignature(parts);

      Map<String, Object> claims = readJson(parts[1]);
      requireEquals(claims.get("iss"), properties.issuer(), "invalid_token_issuer");
      requireAudience(claims.get("aud"));
      requireNotExpired(claims.get("exp"));
      requireEquals(claims.get("typ"), "access", "invalid_token_type");

      return stringClaim(claims.get("sub"), "missing_token_subject");
    } catch (ResponseStatusException exception) {
      throw exception;
    } catch (RuntimeException exception) {
      throw unauthorized("invalid_token");
    }
  }

  private Map<String, Object> readJson(String encoded) {
    try {
      return objectMapper.readValue(BASE64_URL_DECODER.decode(encoded), MAP_TYPE);
    } catch (Exception exception) {
      throw unauthorized("invalid_token_json");
    }
  }

  private void verifySignature(String[] parts) {
    String signingInput = parts[0] + "." + parts[1];
    String expected = hmacSha256(signingInput);
    boolean ok = MessageDigest.isEqual(
      expected.getBytes(StandardCharsets.US_ASCII),
      parts[2].getBytes(StandardCharsets.US_ASCII)
    );
    if (!ok) {
      throw unauthorized("invalid_token_signature");
    }
  }

  private String hmacSha256(String signingInput) {
    try {
      Mac mac = Mac.getInstance("HmacSHA256");
      mac.init(new SecretKeySpec(properties.accessTokenSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
      return BASE64_URL_ENCODER.encodeToString(mac.doFinal(signingInput.getBytes(StandardCharsets.US_ASCII)));
    } catch (Exception exception) {
      throw new IllegalStateException("access token verifier is not initialized", exception);
    }
  }

  private void requireEquals(Object actual, String expected, String reason) {
    if (!expected.equals(actual)) {
      throw unauthorized(reason);
    }
  }

  private void requireAudience(Object value) {
    if (value instanceof String audience && properties.audience().equals(audience)) {
      return;
    }
    if (value instanceof List<?> audiences && audiences.contains(properties.audience())) {
      return;
    }
    throw unauthorized("invalid_token_audience");
  }

  private void requireNotExpired(Object value) {
    if (!(value instanceof Number number)) {
      throw unauthorized("missing_token_expiry");
    }
    Instant expiresAt = Instant.ofEpochSecond(number.longValue());
    if (expiresAt.plus(properties.clockSkew()).isBefore(Instant.now())) {
      throw unauthorized("token_expired");
    }
  }

  private String stringClaim(Object value, String reason) {
    if (value instanceof String text && !text.isBlank()) {
      return text;
    }
    throw unauthorized(reason);
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
