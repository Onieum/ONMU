package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import java.util.UUID;
import org.springframework.core.MethodParameter;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

class TestAuthenticatedUserArgumentResolver implements HandlerMethodArgumentResolver {
  static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000002");
  private static final AuthenticatedUser USER = new AuthenticatedUser(USER_ID, "user-2");

  @Override
  public boolean supportsParameter(MethodParameter parameter) {
    return parameter.hasParameterAnnotation(AuthenticationPrincipal.class)
      && AuthenticatedUser.class.isAssignableFrom(parameter.getParameterType());
  }

  @Override
  public Object resolveArgument(
    MethodParameter parameter,
    ModelAndViewContainer mavContainer,
    NativeWebRequest webRequest,
    WebDataBinderFactory binderFactory
  ) {
    return USER;
  }
}
