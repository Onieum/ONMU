package com.onmu.api.storage;

import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.GetObjectResponse;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.errors.ErrorResponseException;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;

public class MinioObjectStorageClient implements ObjectStorageClient {
  private static final Duration READINESS_TIMEOUT = Duration.ofSeconds(2);

  private final String endpoint;
  private final String bucket;
  private final MinioClient minioClient;
  private final HttpClient httpClient;

  public MinioObjectStorageClient(ObjectStorageProperties properties) {
    this(
      properties.endpoint(),
      properties.bucket(),
      MinioClient.builder()
        .endpoint(properties.endpoint())
        .credentials(properties.minioAccessKey(), properties.minioSecretKey())
        .build(),
      HttpClient.newBuilder().connectTimeout(READINESS_TIMEOUT).build()
    );
  }

  MinioObjectStorageClient(String endpoint, String bucket, MinioClient minioClient, HttpClient httpClient) {
    this.endpoint = endpoint;
    this.bucket = bucket;
    this.minioClient = minioClient;
    this.httpClient = httpClient;
    ensureBucketExists();
  }

  @Override
  public ObjectStorageObject read(String objectKey) {
    try (GetObjectResponse response = minioClient.getObject(
      GetObjectArgs.builder()
        .bucket(bucket)
        .object(objectKey)
        .build())) {
      String contentType = response.headers().get("Content-Type");
      if (!StringUtils.hasText(contentType)) {
        contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
      }
      return new ObjectStorageObject(response.readAllBytes(), contentType);
    } catch (ErrorResponseException exception) {
      String code = exception.errorResponse() != null ? exception.errorResponse().code() : "";
      int statusCode = exception.response() != null ? exception.response().code() : 0;
      if ("NoSuchKey".equals(code) || "NoSuchObject".equals(code) || statusCode == 404) {
        throw new ObjectStorageNotFoundException("media_not_found", exception);
      }
      throw new ObjectStorageException("failed_to_read_media", exception);
    } catch (IOException exception) {
      throw new ObjectStorageException("failed_to_read_media", exception);
    } catch (Exception exception) {
      throw new ObjectStorageException("failed_to_read_media", exception);
    }
  }

  @Override
  public String createUploadUrl(String objectKey, String contentType, Duration ttl) {
    try {
      return minioClient.getPresignedObjectUrl(
        GetPresignedObjectUrlArgs.builder()
          .method(io.minio.http.Method.PUT)
          .bucket(bucket)
          .object(objectKey)
          .expiry(Math.toIntExact(ttl.toSeconds()))
          .extraQueryParams(Map.of("Content-Type", contentType))
          .build());
    } catch (Exception exception) {
      throw new ObjectStorageException("failed_to_generate_presigned_url", exception);
    }
  }

  @Override
  public void upload(String objectKey, InputStream inputStream, long size, String contentType) {
    try {
      minioClient.putObject(
        PutObjectArgs.builder()
          .bucket(bucket)
          .object(objectKey)
          .stream(inputStream, size, -1)
          .contentType(contentType)
          .build());
    } catch (Exception exception) {
      throw new ObjectStorageException("failed_to_upload_media", exception);
    }
  }

  @Override
  public ReadinessResult checkReadiness() {
    URI healthUri;
    try {
      healthUri = minioHealthUri();
    } catch (RuntimeException exception) {
      return ReadinessResult.down("invalid_minio_config");
    }

    try {
      HttpRequest request = HttpRequest.newBuilder(healthUri)
        .timeout(READINESS_TIMEOUT)
        .GET()
        .build();
      int status = httpClient.send(request, HttpResponse.BodyHandlers.discarding()).statusCode();
      boolean ok = status >= 200 && status < 400;
      return ok ? ReadinessResult.ok("minio_http_" + status) : ReadinessResult.down("minio_http_" + status);
    } catch (Exception exception) {
      return ReadinessResult.down(exception.getClass().getSimpleName());
    }
  }

  @Override
  public ObjectStorageProvider provider() {
    return ObjectStorageProvider.MINIO;
  }

  private void ensureBucketExists() {
    try {
      boolean exists = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
      if (!exists) {
        minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
      }
    } catch (Exception exception) {
      System.err.println("Warning: Failed to ensure MinIO bucket existence: " + exception.getClass().getSimpleName());
    }
  }

  private URI minioHealthUri() {
    URI base = URI.create(endpoint);
    if (base.getScheme() == null || base.getHost() == null) {
      throw new IllegalArgumentException("MinIO endpoint must include scheme and host");
    }
    String baseText = base.toString().replaceAll("/+$", "");
    return URI.create(baseText + "/minio/health/live");
  }
}
