package com.onmu.api.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ExternalPlaceEntity;
import com.onmu.api.domain.ExternalPlaceRepository;
import com.onmu.api.place.PlaceImageHttpClient;
import com.onmu.api.place.PlaceImageSupport;
import java.net.URI;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PlaceImageService {
  private final ExternalPlaceRepository externalPlaceRepository;
  private final ObjectMapper objectMapper;
  private final PlaceImageHttpClient httpClient;

  public PlaceImageService(
    ExternalPlaceRepository externalPlaceRepository,
    ObjectMapper objectMapper,
    PlaceImageHttpClient httpClient
  ) {
    this.externalPlaceRepository = externalPlaceRepository;
    this.objectMapper = objectMapper;
    this.httpClient = httpClient;
  }

  public PublicPlaceImage readPublicPlaceImage(String provider, String providerPlaceId) {
    String storedProvider = PlaceImageSupport.normalizeStoredProvider(provider);
    String normalizedProviderPlaceId = providerPlaceId == null ? "" : providerPlaceId.trim();
    if (!PlaceImageSupport.supportsPublicProxy(provider) || normalizedProviderPlaceId.isBlank()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "place_image_not_found");
    }

    ExternalPlaceEntity place = externalPlaceRepository.findByProviderAndProviderPlaceId(storedProvider, normalizedProviderPlaceId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "place_image_not_found"));

    String remoteImageUrl = PlaceImageSupport.firstImageReference(readPayload(place.getProviderPayload()));
    if (remoteImageUrl.isBlank()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "place_image_not_found");
    }

    URI remoteUri = parseAndValidateRemoteUri(remoteImageUrl);
    try {
      PlaceImageHttpClient.PlaceImageResponse response = httpClient.get(remoteUri);
      MediaType contentType = response.contentType() == null ? MediaType.APPLICATION_OCTET_STREAM : response.contentType();
      if (!contentType.toString().toLowerCase().startsWith("image/")) {
        throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "place_image_invalid_content_type");
      }
      if (response.content() == null || response.content().length == 0) {
        throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "place_image_empty_body");
      }
      return new PublicPlaceImage(response.content(), contentType.toString());
    } catch (RestClientResponseException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "place_image_upstream_http_error");
    } catch (RestClientException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "place_image_upstream_unavailable");
    }
  }

  private JsonNode readPayload(String providerPayload) {
    if (providerPayload == null || providerPayload.isBlank()) {
      return objectMapper.createObjectNode();
    }
    try {
      return objectMapper.readTree(providerPayload);
    } catch (Exception exception) {
      return objectMapper.createObjectNode();
    }
  }

  private URI parseAndValidateRemoteUri(String remoteImageUrl) {
    URI remoteUri;
    try {
      remoteUri = URI.create(remoteImageUrl);
    } catch (IllegalArgumentException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "place_image_invalid_uri");
    }
    if (!PlaceImageSupport.isAllowedTourApiImageUri(remoteUri)) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "place_image_disallowed_host");
    }
    return remoteUri;
  }

  public record PublicPlaceImage(byte[] content, String contentType) {
  }
}
