package com.onmu.api.web;

import com.onmu.api.service.PlaceImageService;
import jakarta.validation.constraints.NotBlank;
import java.time.Duration;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/place-images")
public class PlaceImageController {
  private final PlaceImageService placeImageService;

  public PlaceImageController(PlaceImageService placeImageService) {
    this.placeImageService = placeImageService;
  }

  @GetMapping("/public")
  public ResponseEntity<byte[]> getPublicPlaceImage(
    @RequestParam("provider") @NotBlank String provider,
    @RequestParam("providerPlaceId") @NotBlank String providerPlaceId
  ) {
    PlaceImageService.PublicPlaceImage image = placeImageService.readPublicPlaceImage(provider, providerPlaceId);
    return ResponseEntity.ok()
      .cacheControl(CacheControl.maxAge(Duration.ofHours(24)).cachePublic())
      .header(HttpHeaders.CONTENT_TYPE, image.contentType())
      .body(image.content());
  }
}
