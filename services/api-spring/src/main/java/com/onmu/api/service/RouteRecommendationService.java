package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ExternalPlaceEntity;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.route.DevMockRouteProvider;
import com.onmu.api.route.OpenRouteServiceProvider;
import com.onmu.api.route.RouteRecommendation;
import com.onmu.api.route.RouteRecommendationCache;
import com.onmu.api.route.RouteStop;
import com.onmu.api.route.RouteTravelMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class RouteRecommendationService {
  private static final Logger LOGGER = LoggerFactory.getLogger(RouteRecommendationService.class);
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };

  private final GroupRepository groupRepository;
  private final PlanRepository planRepository;
  private final PlaceCandidateRepository placeCandidateRepository;
  private final OpenRouteServiceProvider openRouteServiceProvider;
  private final DevMockRouteProvider devMockRouteProvider;
  private final RouteRecommendationCache cache;
  private final ObjectMapper objectMapper;

  public RouteRecommendationService(
    GroupRepository groupRepository,
    PlanRepository planRepository,
    PlaceCandidateRepository placeCandidateRepository,
    OpenRouteServiceProvider openRouteServiceProvider,
    DevMockRouteProvider devMockRouteProvider,
    RouteRecommendationCache cache,
    ObjectMapper objectMapper
  ) {
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.placeCandidateRepository = placeCandidateRepository;
    this.openRouteServiceProvider = openRouteServiceProvider;
    this.devMockRouteProvider = devMockRouteProvider;
    this.cache = cache;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> recommend(String groupId, String planId, String travelModeValue) {
    RouteTravelMode travelMode = RouteTravelMode.fromApiValue(travelModeValue);
    GroupEntity group = groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    PlanEntity plan = planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));

    List<RouteStop> stops = routeStops(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan));
    String cacheKey = cacheKey(groupId, planId, travelMode, stops);
    Optional<Map<String, Object>> cached = cache.get(cacheKey);
    if (cached.isPresent()) {
      return cached.get();
    }

    RouteRecommendation recommendation = useOpenRouteService(stops)
      ? openRouteService(stops, travelMode)
      : devMockRouteProvider.recommend(stops, travelMode);
    Map<String, Object> value = recommendation.toApiMap();
    cache.put(cacheKey, value);
    return value;
  }

  private boolean useOpenRouteService(List<RouteStop> stops) {
    return openRouteServiceProvider.isAvailable() && stops.size() >= 2;
  }

  private RouteRecommendation openRouteService(List<RouteStop> stops, RouteTravelMode travelMode) {
    try {
      return openRouteServiceProvider.recommend(stops, travelMode);
    } catch (RuntimeException exception) {
      LOGGER.warn("Route provider failed: provider={}, message={}", openRouteServiceProvider.provider(), exception.getClass().getSimpleName());
      return devMockRouteProvider.recommend(stops, travelMode);
    }
  }

  private List<RouteStop> routeStops(List<PlaceCandidateEntity> candidates) {
    List<RouteStop> stops = new ArrayList<>();
    for (PlaceCandidateEntity candidate : candidates) {
      coordinate(candidate)
        .map(coordinate -> new RouteStop(
          candidate.getPublicId(),
          candidate.getName(),
          coordinate.latitude(),
          coordinate.longitude(),
          stops.size() + 1
        ))
        .ifPresent(stops::add);
    }
    return stops;
  }

  private Optional<Coordinate> coordinate(PlaceCandidateEntity candidate) {
    ExternalPlaceEntity externalPlace = candidate.getExternalPlace();
    Double latitude = externalPlace == null ? null : externalPlace.getLatitude();
    Double longitude = externalPlace == null ? null : externalPlace.getLongitude();
    if (isCoordinate(latitude, longitude)) {
      return Optional.of(new Coordinate(latitude, longitude));
    }

    Map<String, Object> payload = readPayload(candidate.getPayload());
    latitude = doubleOrNull(firstNonNull(payload.get("lat"), payload.get("latitude")));
    longitude = doubleOrNull(firstNonNull(payload.get("lng"), payload.get("longitude")));
    return isCoordinate(latitude, longitude) ? Optional.of(new Coordinate(latitude, longitude)) : Optional.empty();
  }

  private Map<String, Object> readPayload(String payload) {
    if (payload == null || payload.isBlank()) {
      return Map.of();
    }
    try {
      return objectMapper.readValue(payload, MAP_TYPE);
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }

  private boolean isCoordinate(Double latitude, Double longitude) {
    return latitude != null && longitude != null
      && latitude >= -90 && latitude <= 90
      && longitude >= -180 && longitude <= 180;
  }

  private Object firstNonNull(Object first, Object second) {
    return first == null ? second : first;
  }

  private Double doubleOrNull(Object value) {
    if (value instanceof Number number) {
      return number.doubleValue();
    }
    try {
      return value == null ? null : Double.parseDouble(value.toString());
    } catch (NumberFormatException exception) {
      return null;
    }
  }

  private String cacheKey(String groupId, String planId, RouteTravelMode travelMode, List<RouteStop> stops) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("groupId", groupId);
    value.put("planId", planId);
    value.put("travelMode", travelMode.apiValue());
    value.put("stops", stops.stream()
      .map(stop -> List.of(stop.id(), stop.latitude(), stop.longitude()))
      .toList());
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(value.toString().getBytes(StandardCharsets.UTF_8));
      return "route-recommendation:v1:" + HexFormat.of().formatHex(hash, 0, 16);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is required", exception);
    }
  }

  private record Coordinate(double latitude, double longitude) {
  }
}
