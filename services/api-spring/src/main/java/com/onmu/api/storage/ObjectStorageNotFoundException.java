package com.onmu.api.storage;

public class ObjectStorageNotFoundException extends RuntimeException {
  public ObjectStorageNotFoundException(String message, Throwable cause) {
    super(message, cause);
  }
}
