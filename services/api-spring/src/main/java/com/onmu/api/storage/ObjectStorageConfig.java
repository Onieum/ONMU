package com.onmu.api.storage;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

@Configuration
public class ObjectStorageConfig {
  @Bean
  ObjectStorageClient objectStorageClient(Environment environment) {
    ObjectStorageProperties properties = ObjectStorageProperties.from(environment);
    return switch (properties.provider()) {
      case MINIO -> new MinioObjectStorageClient(properties);
      case AZURE_BLOB -> new AzureBlobObjectStorageClient(properties);
    };
  }
}
