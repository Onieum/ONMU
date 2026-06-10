package com.onmu.api.service;

public interface KakaoUserInfoClient {
  KakaoUserInfo fetch(String providerAccessToken);
}
