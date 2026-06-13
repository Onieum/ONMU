package com.onmu.api.service;

public interface GoogleIdTokenInfoClient {
  GoogleIdTokenInfo fetch(String providerIdToken);
}
