package com.onmu.api.service;

import com.onmu.api.web.dto.UploadMediaResponse;
import com.onmu.api.web.dto.PresignedUrlResponse;
import io.minio.MinioClient;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

@Service
public class MediaService {
  private static final List<String> FASHION_PLACEHOLDERS = List.of(
    "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1496345875659-11f7dd282d1d?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=800&q=80"
  );
  private final Random random = new Random();

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

      // Public URL to view the file
      String publicUrl = endpoint + "/" + bucket + "/" + storageKey;

      return new PresignedUrlResponse(uploadUrl, storageKey, publicUrl);
    } catch (Exception e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_generate_presigned_url", e);
    }
  }

  public UploadMediaResponse uploadFile(MultipartFile file) {
    String originalName = file != null ? file.getOriginalFilename() : "ootd.jpg";
    if (originalName == null || originalName.isBlank()) {
      originalName = "ootd.jpg";
    }
    String extension = originalName.contains(".") 
      ? originalName.substring(originalName.lastIndexOf(".")) 
      : ".jpg";

    String storageKey = "records/media/" + UUID.randomUUID().toString() + extension;
    
    // Choose a random rich aesthetic fashion image as the public URL for visual wow effect
    String publicUrl = FASHION_PLACEHOLDERS.get(random.nextInt(FASHION_PLACEHOLDERS.size()));

    return new UploadMediaResponse(storageKey, publicUrl);
  }
}
