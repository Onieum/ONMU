package com.onmu.api.storage;

import java.io.InputStream;
import java.time.Duration;

public interface ObjectStorageClient {
  ObjectStorageObject read(String objectKey);

  String createUploadUrl(String objectKey, String contentType, Duration ttl);

  void upload(String objectKey, InputStream inputStream, long size, String contentType);

  ReadinessResult checkReadiness();

  ObjectStorageProvider provider();

  record ReadinessResult(boolean ok, String detail, String error) {
    public static ReadinessResult ok(String detail) {
      return new ReadinessResult(true, detail, null);
    }

    public static ReadinessResult down(String error) {
      return new ReadinessResult(false, null, error);
    }
  }
}
