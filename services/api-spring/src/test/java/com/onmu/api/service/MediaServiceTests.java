package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.onmu.api.web.dto.PresignedUrlResponse;
import com.onmu.api.web.dto.UploadMediaResponse;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.server.ResponseStatusException;

class MediaServiceTests {
  @Test
  void publicSeedMediaAcceptsDevAvatarPrefix() {
    MediaService.validatePublicSeedMediaKey("dev/avatars/user-me.png");
  }

  @Test
  void presignedUrlAcceptsImageContentTypeAndExtension() throws Exception {
    MinioClient minioClient = mock(MinioClient.class);
    when(minioClient.getPresignedObjectUrl(any(GetPresignedObjectUrlArgs.class)))
      .thenReturn("http://localhost:9000/onmu-local/upload-url");
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);

    PresignedUrlResponse response = service.generatePresignedUrl("photo.png", "image/png");

    assertThat(response.uploadUrl()).isEqualTo("http://localhost:9000/onmu-local/upload-url");
    assertThat(response.storageKey()).startsWith("records/media/").endsWith(".png");
    assertThat(response.publicUrl()).startsWith("/api/v1/media/public?key=records%2Fmedia%2F");
    verify(minioClient).getPresignedObjectUrl(any(GetPresignedObjectUrlArgs.class));
  }

  @Test
  void presignedUrlRejectsNonImageContentType() {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);

    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> service.generatePresignedUrl("photo.png", "application/pdf")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(exception.getReason()).isEqualTo("unsupported_media_type");
    verifyNoInteractions(minioClient);
  }

  @Test
  void presignedUrlRejectsNonImageExtension() {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);

    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> service.generatePresignedUrl("photo.pdf", "image/png")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(exception.getReason()).isEqualTo("unsupported_media_type");
    verifyNoInteractions(minioClient);
  }

  @Test
  void presignedUrlRejectsBlankFileName() {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);

    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> service.generatePresignedUrl(" ", "image/jpeg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(exception.getReason()).isEqualTo("unsupported_media_type");
    verifyNoInteractions(minioClient);
  }

  @Test
  void presignedUrlRejectsExtensionlessFileName() {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);

    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> service.generatePresignedUrl("photo", "image/jpeg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(exception.getReason()).isEqualTo("unsupported_media_type");
    verifyNoInteractions(minioClient);
  }

  @Test
  void uploadImageAcceptsImageContentTypeAndExtension() throws Exception {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);
    MockMultipartFile file = new MockMultipartFile(
      "file",
      "photo.jpg",
      "image/jpeg",
      new byte[] {1, 2, 3}
    );

    UploadMediaResponse response = service.uploadFile(file);

    assertThat(response.storageKey()).startsWith("records/media/").endsWith(".jpg");
    assertThat(response.publicUrl()).startsWith("/api/v1/media/public?key=records%2Fmedia%2F");
    verify(minioClient).putObject(any(PutObjectArgs.class));
  }

  @Test
  void uploadImageRejectsNonImageContentType() {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);
    MockMultipartFile file = new MockMultipartFile(
      "file",
      "photo.jpg",
      "text/plain",
      new byte[] {1, 2, 3}
    );

    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> service.uploadFile(file)
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(exception.getReason()).isEqualTo("unsupported_media_type");
    verifyNoInteractions(minioClient);
  }

  @Test
  void uploadImageRejectsNonImageExtension() {
    MinioClient minioClient = mock(MinioClient.class);
    MediaService service = new MediaService("http://localhost:9000", "onmu-local", minioClient);
    MockMultipartFile file = new MockMultipartFile(
      "file",
      "photo.pdf",
      "image/jpeg",
      new byte[] {1, 2, 3}
    );

    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> service.uploadFile(file)
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    assertThat(exception.getReason()).isEqualTo("unsupported_media_type");
    verifyNoInteractions(minioClient);
  }

  @Test
  void publicMediaAllowsUploadedRecordMediaKeys() {
    assertThat(MediaService.publicMediaUrl("records/media/photo.jpg"))
      .isEqualTo("/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg");
  }

  @Test
  void publicMediaRejectsKeysOutsideAllowedPrefixes() {
    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> MediaService.validatePublicSeedMediaKey("private/media/not-public.jpg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
  }

  @Test
  void publicMediaRejectsPathTraversalKeys() {
    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> MediaService.validatePublicSeedMediaKey("records/media/../secret.jpg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
  }
}
