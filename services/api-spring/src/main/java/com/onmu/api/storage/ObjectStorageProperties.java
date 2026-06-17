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
    return new ObjectStorageProperties(
      provider,
      endpoint,
      bucket,
      accessKey,
      secretKey,
      managedIdentityClientId,
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
