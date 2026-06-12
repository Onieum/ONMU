package com.onmu.api.service;

import com.onmu.api.web.dto.UploadMediaResponse;
import com.onmu.api.web.dto.PresignedUrlResponse;
import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.GetObjectResponse;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.errors.ErrorResponseException;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
public class MediaService {
  private static final String PUBLIC_SEED_MEDIA_PREFIX = "dev/media/records/";
  private static final String UPLOADED_MEDIA_PREFIX = "records/media/";
  private static final Set<String> ALLOWED_IMAGE_EXTENSIONS = Set.of(
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".gif",
    ".heic",
    ".heif"
  );

  private final String endpoint;
  private final String bucket;
  private final MinioClient minioClient;

  public MediaService(
      @Value("${OBJECT_STORAGE_ENDPOINT:http://localhost:9000}") String endpoint,
      @Value("${OBJECT_STORAGE_BUCKET:onmu-local}") String bucket,
      @Value("${MINIO_ROOT_USER:onmu}") String accessKey,
      @Value("${MINIO_ROOT_PASSWORD:onmu-local-only}") String secretKey
  ) {
    this.endpoint = endpoint;
    this.bucket = bucket;
    this.minioClient = MinioClient.builder()
        .endpoint(endpoint)
        .credentials(accessKey, secretKey)
        .build();
    ensureBucketExists();
  }

  MediaService(String endpoint, String bucket, MinioClient minioClient) {
    this.endpoint = endpoint;
    this.bucket = bucket;
    this.minioClient = minioClient;
  }

  private void ensureBucketExists() {
    try {
      boolean exists = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
      if (!exists) {
        minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
      }
    } catch (Exception e) {
      // Log error but do not prevent application startup
      System.err.println("Warning: Failed to ensure MinIO bucket existence: " + e.getMessage());
    }
  }

  public PublicMediaObject readPublicSeedMedia(String objectKey) {
    validatePublicSeedMediaKey(objectKey);

    try (GetObjectResponse response = minioClient.getObject(
        GetObjectArgs.builder()
            .bucket(bucket)
            .object(objectKey)
            .build())) {
      String contentType = response.headers().get("Content-Type");
      if (!StringUtils.hasText(contentType)) {
        contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
      }
      return new PublicMediaObject(response.readAllBytes(), contentType);
    } catch (ErrorResponseException e) {
      String code = e.errorResponse() != null ? e.errorResponse().code() : "";
      int statusCode = e.response() != null ? e.response().code() : 0;
      if ("NoSuchKey".equals(code) || "NoSuchObject".equals(code) || statusCode == 404) {
        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "media_not_found", e);
      }
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_read_media", e);
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_read_media", e);
    } catch (Exception e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_read_media", e);
    }
  }

  public static String publicMediaUrl(String objectKey) {
    validatePublicMediaKey(objectKey);
    return "/api/v1/media/public?key=" + URLEncoder.encode(objectKey, StandardCharsets.UTF_8);
  }

  static void validatePublicSeedMediaKey(String objectKey) {
    validatePublicMediaKey(objectKey);
  }

  public static void validatePublicMediaKey(String objectKey) {
    if (!isAllowedPublicMediaKey(objectKey)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_media_key_prefix");
    }
  }

  public static boolean isAllowedPublicMediaKey(String objectKey) {
    if (!StringUtils.hasText(objectKey)) {
      return false;
    }
    String key = objectKey.trim();
    if (key.contains("..") || key.startsWith("/") || key.contains("\\")) {
      return false;
    }
    return key.startsWith(PUBLIC_SEED_MEDIA_PREFIX) || key.startsWith(UPLOADED_MEDIA_PREFIX);
  }

  public PresignedUrlResponse generatePresignedUrl(String fileName, String contentType) {
    String originalName = fileName != null ? fileName : "ootd.jpg";
    if (originalName.isBlank()) {
      originalName = "ootd.jpg";
    }
    String extension = originalName.contains(".") 
      ? originalName.substring(originalName.lastIndexOf(".")) 
      : ".jpg";

    String storageKey = "records/media/" + UUID.randomUUID().toString() + extension;

    try {
      String uploadUrl = minioClient.getPresignedObjectUrl(
          GetPresignedObjectUrlArgs.builder()
              .method(io.minio.http.Method.PUT)
              .bucket(bucket)
              .object(storageKey)
              .expiry(60 * 60) // 1 hour
              .extraQueryParams(contentType != null && !contentType.isBlank() 
                  ? Map.of("Content-Type", contentType) 
                  : Collections.emptyMap())
              .build());

      String publicUrl = publicMediaUrl(storageKey);

      return new PresignedUrlResponse(uploadUrl, storageKey, publicUrl);
    } catch (Exception e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_generate_presigned_url", e);
    }
  }

  public UploadMediaResponse uploadFile(MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "media_file_required");
    }

    String originalName = file != null ? file.getOriginalFilename() : "ootd.jpg";
    if (originalName == null || originalName.isBlank()) {
      originalName = "ootd.jpg";
    }
    String extension = originalName.contains(".") 
      ? originalName.substring(originalName.lastIndexOf(".")) 
      : ".jpg";
    String contentType = validateImageUpload(file, extension);

    String storageKey = "records/media/" + UUID.randomUUID().toString() + extension;

    try {
      minioClient.putObject(
          PutObjectArgs.builder()
              .bucket(bucket)
              .object(storageKey)
              .stream(file.getInputStream(), file.getSize(), -1)
              .contentType(contentType)
              .build());

      String publicUrl = publicMediaUrl(storageKey);
      return new UploadMediaResponse(storageKey, publicUrl);
    } catch (Exception e) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "failed_to_upload_media", e);
    }
  }

  private String validateImageUpload(MultipartFile file, String extension) {
    String contentType = file.getContentType();
    String normalizedExtension = extension == null ? "" : extension.toLowerCase(Locale.ROOT);
    if (!StringUtils.hasText(contentType)
      || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")
      || !ALLOWED_IMAGE_EXTENSIONS.contains(normalizedExtension)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_media_type");
    }
    return contentType;
  }

  public record PublicMediaObject(byte[] content, String contentType) {
  }
}
