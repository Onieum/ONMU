package com.onmu.api.service;

public interface NaverUserInfoClient {
  NaverUserInfo fetch(String providerAccessToken);
}
