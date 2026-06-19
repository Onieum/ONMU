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
import com.onmu.api.domain.SchedulePlaceEntity;
import com.onmu.api.domain.SchedulePlaceRepository;
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
import java.util.UUID;
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
  private final SchedulePlaceRepository schedulePlaceRepository;
  private final OpenRouteServiceProvider openRouteServiceProvider;
  private final DevMockRouteProvider devMockRouteProvider;
  private final RouteRecommendationCache cache;
  private final ObjectMapper objectMapper;

  public RouteRecommendationService(
    GroupRepository groupRepository,
    PlanRepository planRepository,
    PlaceCandidateRepository placeCandidateRepository,
    SchedulePlaceRepository schedulePlaceRepository,
    OpenRouteServiceProvider openRouteServiceProvider,
    DevMockRouteProvider devMockRouteProvider,
    RouteRecommendationCache cache,
    ObjectMapper objectMapper
  ) {
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.placeCandidateRepository = placeCandidateRepository;
    this.schedulePlaceRepository = schedulePlaceRepository;
    this.openRouteServiceProvider = openRouteServiceProvider;
    this.devMockRouteProvider = devMockRouteProvider;
    this.cache = cache;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> recommend(String groupId, String planId, String travelModeValue) {
    return recommend(groupId, planId, travelModeValue, null);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> recommend(String groupId, String planId, String travelModeValue, UUID userId) {
    RouteTravelMode travelMode = RouteTravelMode.fromApiValue(travelModeValue);
    GroupEntity group = groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    if (userId != null && !groupRepository.isUserMember(group.getPublicId(), userId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    PlanEntity plan = planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));

    List<RouteStop> stops = routeStops(plan);
    boolean routeProviderAvailable = openRouteServiceProvider.isAvailable();
    LOGGER.info(
      "Route provider selection: provider={}, available={}, stop_count={}",
      openRouteServiceProvider.provider(),
      routeProviderAvailable,
      stops.size()
    );
    String cacheKey = cacheKey(groupId, planId, travelMode, stops, routeProviderAvailable);
    Optional<Map<String, Object>> cached = cache.get(cacheKey);
    if (cached.isPresent()) {
      return cached.get();
    }

    RouteRecommendationResult result = routeRecommendation(stops, travelMode, routeProviderAvailable);
    RouteRecommendation recommendation = result.recommendation();
    Map<String, Object> value = recommendation.toApiMap();
    value.put("liveProvider", result.liveProvider());
    if (!result.fallbackReason().isBlank()) {
      value.put("fallbackReason", result.fallbackReason());
    }
    if (result.cacheable()) {
      cache.put(cacheKey, value);
    }
    return value;
  }

  private RouteRecommendationResult routeRecommendation(
    List<RouteStop> stops,
    RouteTravelMode travelMode,
    boolean routeProviderAvailable
  ) {
    if (!routeProviderAvailable) {
      LOGGER.info("Using dev mock route fallback: reason=provider_unavailable, stop_count={}", stops.size());
      return new RouteRecommendationResult(
        devMockRouteProvider.recommend(stops, travelMode),
        true,
        false,
        "provider_unavailable"
      );
    }
    if (stops.size() < 2) {
      LOGGER.info("Using dev mock route fallback: reason=insufficient_coordinates, stop_count={}", stops.size());
      return new RouteRecommendationResult(
        devMockRouteProvider.recommend(stops, travelMode),
        true,
        false,
        "insufficient_coordinates"
      );
    }
    try {
      LOGGER.info("Route provider invocation started: provider={}", openRouteServiceProvider.provider());
      RouteRecommendation recommendation = openRouteServiceProvider.recommend(stops, travelMode);
      LOGGER.info(
        "Route provider invocation finished: provider={}, geometry_count={}, distance_present={}, duration_present={}",
        openRouteServiceProvider.provider(),
        recommendation.geometry().size(),
        recommendation.distanceMeters() > 0,
        recommendation.durationSeconds() > 0
      );
      return new RouteRecommendationResult(recommendation, true, true, "");
    } catch (RuntimeException exception) {
      LOGGER.warn(
        "Route provider failed: provider={}, error_type={}",
        openRouteServiceProvider.provider(),
        exception.getClass().getSimpleName()
      );
      LOGGER.info("Using dev mock route fallback: reason=provider_failure, stop_count={}", stops.size());
      return new RouteRecommendationResult(
        devMockRouteProvider.recommend(stops, travelMode),
        false,
        false,
        "provider_failure"
      );
    }
  }

  private List<RouteStop> routeStops(PlanEntity plan) {
    List<SchedulePlaceEntity> schedulePlaces = schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan);
    if (!schedulePlaces.isEmpty()) {
      return routeStopsFromSchedulePlaces(schedulePlaces);
    }
    return routeStopsFromCandidates(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan));
  }

  private List<RouteStop> routeStopsFromSchedulePlaces(List<SchedulePlaceEntity> schedulePlaces) {
    List<RouteStop> stops = new ArrayList<>();
    for (SchedulePlaceEntity schedulePlace : schedulePlaces) {
      PlaceCandidateEntity candidate = schedulePlace.getPlaceCandidate();
      if (candidate == null) {
        continue;
      }
      coordinate(candidate)
        .map(coordinate -> new RouteStop(
          schedulePlace.getPublicId(),
          schedulePlace.getName(),
          coordinate.latitude(),
          coordinate.longitude(),
          stops.size() + 1
        ))
        .ifPresent(stops::add);
    }
    return stops;
  }

  private List<RouteStop> routeStopsFromCandidates(List<PlaceCandidateEntity> candidates) {
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

  private String cacheKey(
    String groupId,
    String planId,
    RouteTravelMode travelMode,
    List<RouteStop> stops,
    boolean routeProviderAvailable
  ) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("groupId", groupId);
    value.put("planId", planId);
    value.put("travelMode", travelMode.apiValue());
    value.put("routeProviderAvailable", routeProviderAvailable);
    value.put("stops", stops.stream()
      .map(stop -> List.of(stop.id(), stop.name(), stop.latitude(), stop.longitude()))
      .toList());
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(value.toString().getBytes(StandardCharsets.UTF_8));
      return "route-recommendation:v2:" + HexFormat.of().formatHex(hash, 0, 16);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is required", exception);
    }
  }

  private record Coordinate(double latitude, double longitude) {
  }

  private record RouteRecommendationResult(
    RouteRecommendation recommendation,
    boolean cacheable,
    boolean liveProvider,
    String fallbackReason
  ) {
  }
}
