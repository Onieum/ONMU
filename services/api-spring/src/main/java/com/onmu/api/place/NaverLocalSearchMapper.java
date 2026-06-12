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
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

@Component
public class NaverLocalSearchMapper {
  private static final Pattern TAG_PATTERN = Pattern.compile("<[^>]+>");

  private final ObjectMapper objectMapper;

  public NaverLocalSearchMapper(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  public List<PlaceSearchResult> map(String json, Instant fetchedAt) {
    try {
      JsonNode items = objectMapper.readTree(json).path("items");
      if (!items.isArray()) {
        return List.of();
      }
      List<PlaceSearchResult> results = new ArrayList<>();
      for (JsonNode item : items) {
        String name = cleanText(text(item, "title"));
        if (name.isBlank()) {
          continue;
        }
        String roadAddress = blankToNull(cleanText(text(item, "roadAddress")));
        String address = blankToNull(cleanText(text(item, "address")));
        String sourceUrl = blankToNull(text(item, "link"));
        String providerPlaceId = "naver-" + stableId(name, roadAddress, address, sourceUrl);
        results.add(new PlaceSearchResult(
          "naver",
          providerPlaceId,
          name,
          blankToNull(cleanText(text(item, "category"))),
          address,
          roadAddress,
          null,
          null,
          sourceUrl,
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

  private String cleanText(String value) {
    String unescaped = HtmlUtils.htmlUnescape(value == null ? "" : value);
    return TAG_PATTERN.matcher(unescaped)
      .replaceAll("")
      .replace(">", " > ")
      .replaceAll("\\s+", " ")
      .trim();
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
