package com.onmu.api.storage;

import java.time.Duration;
import org.springframework.core.env.Environment;
import org.springframework.util.StringUtils;

public record ObjectStorageProperties(
  ObjectStorageProvider provider,
  String endpoint,
  String bucket,
  String minioAccessKey,
  String minioSecretKey,
  String managedIdentityClientId,
  String accessKeyId,
  String secretAccessKey,
  String region,
  Duration presignedUrlTtl
) {
  public static ObjectStorageProperties from(Environment environment) {
    ObjectStorageProvider provider = ObjectStorageProvider.from(firstText(environment, "OBJECT_STORAGE_PROVIDER"));
    String endpoint = firstText(environment, "OBJECT_STORAGE_ENDPOINT", "MINIO_ENDPOINT");
    if (!StringUtils.hasText(endpoint)) {
      endpoint = "http://localhost:9000";
    }

    String bucket = firstText(environment, "OBJECT_STORAGE_BUCKET");
    if (!StringUtils.hasText(bucket)) {
      bucket = "onmu-local";
    }

    String accessKey = firstText(environment, "MINIO_ROOT_USER");
    if (!StringUtils.hasText(accessKey)) {
      accessKey = "onmu";
    }

    String secretKey = firstText(environment, "MINIO_ROOT_PASSWORD");
    if (!StringUtils.hasText(secretKey)) {
      secretKey = "onmu-local-only";
    }

    String managedIdentityClientId = firstText(environment, "OBJECT_STORAGE_MANAGED_IDENTITY_CLIENT_ID", "AZURE_CLIENT_ID");

    // R2 / S3 호환 자격증명. R2 Access Key ID / Secret Access Key 를 여기에 넣는다.
    String accessKeyId = firstText(environment, "OBJECT_STORAGE_ACCESS_KEY_ID");
    String secretAccessKey = firstText(environment, "OBJECT_STORAGE_SECRET_ACCESS_KEY");

    // R2 는 region "auto" 사용. 명시 없으면 "auto".
    String region = firstText(environment, "OBJECT_STORAGE_REGION");
    if (!StringUtils.hasText(region)) {
      region = "auto";
    }

    return new ObjectStorageProperties(
      provider,
      endpoint,
      bucket,
      accessKey,
      secretKey,
      managedIdentityClientId,
      accessKeyId,
      secretAccessKey,
      region,
      Duration.ofHours(1)
    );
  }

  private static String firstText(Environment environment, String... names) {
    for (String name : names) {
      String value = environment.getProperty(name);
      if (StringUtils.hasText(value)) {
        return value.trim();
      }
    }
    return null;
  }
}
