package com.onmu.api.storage;

import java.util.Locale;

public enum ObjectStorageProvider {
  MINIO,
  AZURE_BLOB;

  public static ObjectStorageProvider from(String value) {
    if (value == null || value.isBlank()) {
      return MINIO;
    }
    return switch (value.trim().toLowerCase(Locale.ROOT)) {
      case "minio" -> MINIO;
      case "azure_blob", "azure-blob", "azureblob" -> AZURE_BLOB;
      default -> throw new IllegalArgumentException("Unsupported object storage provider");
    };
  }

  public String dependencyName() {
    return "objectStorage";
  }

  public String detailName() {
    return switch (this) {
      case MINIO -> "minio";
      case AZURE_BLOB -> "azure_blob";
    };
  }
}
