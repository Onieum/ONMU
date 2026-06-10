package com.onmu.api.web;

import com.onmu.api.service.MediaService;
import com.onmu.api.web.dto.UploadMediaResponse;
import com.onmu.api.web.dto.PresignedUrlRequest;
import com.onmu.api.web.dto.PresignedUrlResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@Validated
@RestController
@RequestMapping("/api/v1")
public class MediaController {
  private final MediaService mediaService;

  public MediaController(MediaService mediaService) {
    this.mediaService = mediaService;
  }

  @PostMapping(value = "/media/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public ResponseEntity<UploadMediaResponse> uploadMedia(
    @RequestParam(value = "file", required = false) MultipartFile file
  ) {
    UploadMediaResponse response = mediaService.uploadFile(file);
    return ResponseEntity.ok(response);
  }

  @GetMapping("/media/public")
  public ResponseEntity<byte[]> getPublicMedia(@RequestParam("key") String key) {
    MediaService.PublicMediaObject media = mediaService.readPublicSeedMedia(key);
    return ResponseEntity.ok()
      .header(HttpHeaders.CONTENT_TYPE, media.contentType())
      .body(media.content());
  }

  @PostMapping(value = "/uploads/presigned-url", consumes = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<PresignedUrlResponse> getPresignedUrl(
    @Valid @RequestBody PresignedUrlRequest request
  ) {
    PresignedUrlResponse response = mediaService.generatePresignedUrl(
      request.fileName(),
      request.contentType()
    );
    return ResponseEntity.ok(response);
  }
}
