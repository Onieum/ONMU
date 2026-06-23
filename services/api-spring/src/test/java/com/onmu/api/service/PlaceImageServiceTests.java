package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ExternalPlaceEntity;
import com.onmu.api.domain.ExternalPlaceRepository;
import com.onmu.api.place.PlaceImageHttpClient;
import java.net.URI;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.server.ResponseStatusException;

class PlaceImageServiceTests {
  private final ExternalPlaceRepository repository = mock(ExternalPlaceRepository.class);
  private final CapturingPlaceImageHttpClient httpClient = new CapturingPlaceImageHttpClient();
  private final PlaceImageService service = new PlaceImageService(repository, new ObjectMapper(), httpClient);

  @Test
  void readsCatalogImageThroughAllowedTourApiHost() {
    when(repository.findByProviderAndProviderPlaceId("ONMU_CATALOG", "tour-1"))
      .thenReturn(Optional.of(new ExternalPlaceEntity(
        "ONMU_CATALOG",
        "tour-1",
        "망원 한강공원",
        "관광명소",
        "서울 마포구",
        "서울 마포구",
        37.555,
        126.895,
        "https://example.test/places/tour-1",
        "{\"firstimage\":\"https://tong.visitkorea.or.kr/cms/resource/tour-1.jpg\"}"
      )));
    httpClient.response = new PlaceImageHttpClient.PlaceImageResponse(new byte[] {1, 2, 3}, MediaType.IMAGE_JPEG);

    var image = service.readPublicPlaceImage("onmu_catalog", "tour-1");

    assertThat(httpClient.requestedUri).isEqualTo(URI.create("https://tong.visitkorea.or.kr/cms/resource/tour-1.jpg"));
    assertThat(image.contentType()).isEqualTo("image/jpeg");
    assertThat(image.content()).containsExactly(1, 2, 3);
  }

  @Test
  void missingCatalogImageReferenceReturnsNotFound() {
    when(repository.findByProviderAndProviderPlaceId("ONMU_CATALOG", "tour-404"))
      .thenReturn(Optional.of(new ExternalPlaceEntity(
        "ONMU_CATALOG",
        "tour-404",
        "이미지 없는 장소",
        "관광명소",
        "서울",
        "서울",
        37.55,
        126.89,
        "https://example.test/places/tour-404",
        "{\"summary\":\"image missing\"}"
      )));

    assertThatThrownBy(() -> service.readPublicPlaceImage("onmu_catalog", "tour-404"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  @Test
  void disallowedRemoteImageHostReturnsBadGateway() {
    when(repository.findByProviderAndProviderPlaceId("ONMU_CATALOG", "tour-bad"))
      .thenReturn(Optional.of(new ExternalPlaceEntity(
        "ONMU_CATALOG",
        "tour-bad",
        "허용되지 않은 이미지 호스트",
        "관광명소",
        "서울",
        "서울",
        37.55,
        126.89,
        "https://example.test/places/tour-bad",
        "{\"firstimage\":\"https://example.com/not-allowed.jpg\"}"
      )));

    assertThatThrownBy(() -> service.readPublicPlaceImage("onmu_catalog", "tour-bad"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_GATEWAY));
  }

  @Test
  void unsupportedProviderReturnsNotFound() {
    assertThatThrownBy(() -> service.readPublicPlaceImage("naver", "naver-1"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  private static final class CapturingPlaceImageHttpClient implements PlaceImageHttpClient {
    private URI requestedUri;
    private PlaceImageResponse response = new PlaceImageResponse(new byte[] {9}, MediaType.IMAGE_PNG);

    @Override
    public PlaceImageResponse get(URI uri) {
      requestedUri = uri;
      return response;
    }
  }
}
