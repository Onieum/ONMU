package com.onmu.api.place;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import org.springframework.web.util.UriComponentsBuilder;

public final class PlaceImageSupport {
  public static final String API_CATALOG_PROVIDER = "onmu_catalog";
  public static final String STORED_CATALOG_PROVIDER = "ONMU_CATALOG";

  private static final List<String> ALLOWED_TOUR_API_HOST_SUFFIXES = List.of("visitkorea.or.kr");

  private PlaceImageSupport() {
  }

  public static String normalizeStoredProvider(String provider) {
    String normalized = normalizeProvider(provider);
    if (normalized == null) {
      return null;
    }
    if (API_CATALOG_PROVIDER.equals(normalized) || STORED_CATALOG_PROVIDER.equals(normalized.toUpperCase(Locale.ROOT))) {
      return STORED_CATALOG_PROVIDER;
    }
    return normalized.toUpperCase(Locale.ROOT);
  }

  public static String normalizeApiProvider(String provider) {
    String normalized = normalizeProvider(provider);
    if (normalized == null) {
      return null;
    }
    if (API_CATALOG_PROVIDER.equals(normalized) || STORED_CATALOG_PROVIDER.equals(normalized.toUpperCase(Locale.ROOT))) {
      return API_CATALOG_PROVIDER;
    }
    return normalized;
  }

  public static boolean supportsPublicProxy(String provider) {
    return API_CATALOG_PROVIDER.equals(normalizeApiProvider(provider));
  }

  public static String publicImagePath(String provider, String providerPlaceId) {
    String normalizedProvider = normalizeApiProvider(provider);
    if (normalizedProvider == null || providerPlaceId == null || providerPlaceId.isBlank()) {
      return "";
    }
    return UriComponentsBuilder.fromPath("/api/v1/place-images/public")
      .queryParam("provider", normalizedProvider)
      .queryParam("providerPlaceId", providerPlaceId.trim())
      .build()
      .toUriString();
  }

  public static String firstImageReference(JsonNode payload) {
    if (payload == null || payload.isMissingNode() || payload.isNull()) {
      return "";
    }
    String direct = firstNonBlank(
      text(payload, "imageUrl"),
      text(payload, "image_url"),
      text(payload, "firstimage"),
      text(payload, "firstImage")
    );
    if (!direct.isBlank()) {
      return direct;
    }
    JsonNode imageUrls = payload.get("imageUrls");
    if (imageUrls != null && imageUrls.isArray()) {
      for (JsonNode imageUrl : imageUrls) {
        if (imageUrl != null && imageUrl.isTextual() && !imageUrl.asText().isBlank()) {
          return imageUrl.asText().trim();
        }
      }
    }
    return "";
  }

  public static boolean isAllowedTourApiImageUri(URI uri) {
    if (uri == null) {
      return false;
    }
    String scheme = uri.getScheme();
    String host = uri.getHost();
    if (scheme == null || host == null) {
      return false;
    }
    String normalizedScheme = scheme.toLowerCase(Locale.ROOT);
    if (!"http".equals(normalizedScheme) && !"https".equals(normalizedScheme)) {
      return false;
    }
    String normalizedHost = host.toLowerCase(Locale.ROOT);
    return ALLOWED_TOUR_API_HOST_SUFFIXES.stream().anyMatch(suffix ->
      normalizedHost.equals(suffix) || normalizedHost.endsWith("." + suffix));
  }

  private static String normalizeProvider(String provider) {
    if (provider == null || provider.isBlank()) {
      return null;
    }
    return provider.trim().toLowerCase(Locale.ROOT);
  }

  private static String text(JsonNode payload, String field) {
    JsonNode value = payload.get(field);
    return value != null && value.isTextual() ? value.asText().trim() : "";
  }

  private static String firstNonBlank(String... values) {
    for (String value : values) {
      if (value != null && !value.isBlank()) {
        return value.trim();
      }
    }
    return "";
  }
}
