package com.onmu.api.place;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class KakaoKeywordSearchMapper {
  private final ObjectMapper objectMapper;

  public KakaoKeywordSearchMapper(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  public List<PlaceSearchResult> map(String json, Instant fetchedAt) {
    try {
      JsonNode documents = objectMapper.readTree(json).path("documents");
      if (!documents.isArray()) {
        return List.of();
      }
      List<PlaceSearchResult> results = new ArrayList<>();
      for (JsonNode document : documents) {
        String name = blankToNull(text(document, "place_name"));
        if (name == null) {
          continue;
        }
        String providerPlaceId = blankToNull(text(document, "id"));
        if (providerPlaceId == null) {
          providerPlaceId = "kakao-" + stableId(name, text(document, "road_address_name"), text(document, "address_name"));
        }
        results.add(new PlaceSearchResult(
          "kakao",
          providerPlaceId,
          name,
          blankToNull(text(document, "category_name")),
          blankToNull(text(document, "address_name")),
          blankToNull(text(document, "road_address_name")),
          parseDouble(text(document, "y")),
          parseDouble(text(document, "x")),
          blankToNull(text(document, "place_url")),
          fetchedAt
        ));
      }
      return results;
    } catch (Exception exception) {
      return List.of();
    }
  }

  private String text(JsonNode node, String fieldName) {
    JsonNode value = node.path(fieldName);
    return value.isMissingNode() || value.isNull() ? "" : value.asText("");
  }

  private Double parseDouble(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    try {
      return Double.parseDouble(value);
    } catch (NumberFormatException exception) {
      return null;
    }
  }

  private String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }

  private String stableId(String... parts) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      for (String part : parts) {
        if (part != null && !part.isBlank()) {
          digest.update(part.getBytes(StandardCharsets.UTF_8));
          digest.update((byte) '|');
        }
      }
      byte[] hash = digest.digest();
      return HexFormat.of().formatHex(hash, 0, 8);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is required", exception);
    }
  }
}
