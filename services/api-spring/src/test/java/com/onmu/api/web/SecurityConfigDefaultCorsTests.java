package com.onmu.api.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.config.SecurityConfig;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AccessTokenVerifier;
import com.onmu.api.security.BearerTokenAuthenticationFilter;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = SessionController.class)
@Import({SecurityConfig.class, BearerTokenAuthenticationFilter.class})
@TestPropertySource(properties = {
  "ONMU_CORS_ORIGINS=",
  "ONMU_DEV_CORS_ORIGINS=",
  "onmu.security.cors.allowed-origins=",
  "onmu.auth.access-token-secret=test-access-token-secret-with-enough-length",
  "onmu.access-log.path=target/test-security-config-default-cors-api-access.log"
})
class SecurityConfigDefaultCorsTests {
  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private AccessTokenVerifier accessTokenVerifier;

  @MockitoBean
  private UserRepository userRepository;

  @Test
  void defaultCorsOriginsAllowLocalFrontendPreflight() throws Exception {
    mvc.perform(options("/api/v1/auth/session")
        .header(HttpHeaders.ORIGIN, "http://localhost:3000")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization,content-type"))
      .andExpect(status().isOk())
      .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:3000"))
      .andExpect(header().string(
        HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS,
        Matchers.containsString("authorization")
      ));
  }
}
