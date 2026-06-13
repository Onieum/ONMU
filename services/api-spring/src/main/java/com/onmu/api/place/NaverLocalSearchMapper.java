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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

@Component
public class NaverLocalSearchMapper {
  private static final Logger LOGGER = LoggerFactory.getLogger(NaverLocalSearchMapper.class);
  private static final Pattern TAG_PATTERN = Pattern.compile("<[^>]+>");
  private static final double NAVER_COORDINATE_SCALE = 10_000_000.0;
  private static final double KOREA_MIN_LONGITUDE = 124.0;
  private static final double KOREA_MAX_LONGITUDE = 132.0;
  private static final double KOREA_MIN_LATITUDE = 33.0;
  private static final double KOREA_MAX_LATITUDE = 39.0;

  private final ObjectMapper objectMapper;

  public NaverLocalSearchMapper(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  public List<PlaceSearchResult> map(String json, Instant fetchedAt) {
    try {
      JsonNode items = objectMapper.readTree(json).path("items");
      if (!items.isArray()) {
        LOGGER.warn("Naver local search response did not include an items array");
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
        Coordinates coordinates = coordinates(item);
        String providerPlaceId = "naver-" + stableId(name, roadAddress, address, sourceUrl);
        results.add(new PlaceSearchResult(
          "naver",
          providerPlaceId,
          name,
          blankToNull(cleanText(text(item, "category"))),
          address,
          roadAddress,
          coordinates == null ? null : coordinates.latitude(),
          coordinates == null ? null : coordinates.longitude(),
          sourceUrl,
          fetchedAt
        ));
      }
      if (results.isEmpty() && !items.isEmpty()) {
        LOGGER.warn("Naver local search mapped zero usable results: item_count={}", items.size());
      } else {
        LOGGER.debug("Naver local search mapped results: item_count={}, result_count={}", items.size(), results.size());
      }
      return results;
    } catch (Exception exception) {
      LOGGER.warn("Naver local search response could not be parsed: error_type={}", exception.getClass().getSimpleName());
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

  private Coordinates coordinates(JsonNode item) {
    Double longitude = coordinateValue(text(item, "mapx"));
    Double latitude = coordinateValue(text(item, "mapy"));
    if (longitude == null || latitude == null) {
      return null;
    }
    if (isKoreaCoordinate(longitude, latitude)) {
      return new Coordinates(latitude, longitude);
    }
    double scaledLongitude = longitude / NAVER_COORDINATE_SCALE;
    double scaledLatitude = latitude / NAVER_COORDINATE_SCALE;
    if (isKoreaCoordinate(scaledLongitude, scaledLatitude)) {
      return new Coordinates(scaledLatitude, scaledLongitude);
    }
    return null;
  }

  private Double coordinateValue(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    try {
      return Double.parseDouble(value.trim());
    } catch (NumberFormatException exception) {
      return null;
    }
  }

  private boolean isKoreaCoordinate(double longitude, double latitude) {
    return longitude >= KOREA_MIN_LONGITUDE &&
      longitude <= KOREA_MAX_LONGITUDE &&
      latitude >= KOREA_MIN_LATITUDE &&
      latitude <= KOREA_MAX_LATITUDE;
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

  private record Coordinates(Double latitude, Double longitude) {
  }
}
