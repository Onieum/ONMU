package com.onmu.api.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.http.MediaType;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class SpringAccessLogFilterTests {
  private final ObjectMapper objectMapper = new ObjectMapper();

  @TempDir
  private Path tempDir;

  @Test
  void writesRequestLevelAccessLogWithoutSecrets() throws Exception {
    Path accessLogPath = tempDir.resolve("api-access.log");
    SpringAccessLogFilter filter = new SpringAccessLogFilter(
      objectMapper,
      new MockEnvironment().withProperty("onmu.access-log.path", accessLogPath.toString())
    );
    MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/groups/1/votes");
    request.setQueryString("client=spring-access-log-test");
    request.setContentType(MediaType.APPLICATION_FORM_URLENCODED_VALUE);
    request.setContent("client=body-client".getBytes(StandardCharsets.UTF_8));
    request.addHeader("Origin", "http://localhost:5173");
    request.addHeader("X-Request-Id", "request-123");
    request.addHeader("Authorization", "Bearer super-secret-token");
    MockHttpServletResponse response = new MockHttpServletResponse();
    FilterChain chain = (servletRequest, servletResponse) -> response.setStatus(201);

    filter.doFilter(request, response, chain);

    String line = Files.readString(accessLogPath, StandardCharsets.UTF_8);
    JsonNode log = objectMapper.readTree(line);
    assertThat(log.get("method").asText()).isEqualTo("POST");
    assertThat(log.get("path").asText()).isEqualTo("/api/v1/groups/1/votes");
    assertThat(log.get("status").asInt()).isEqualTo(201);
    assertThat(log.get("dev_client").asText()).isEqualTo("spring-access-log-test");
    assertThat(log.get("origin").asText()).isEqualTo("http://localhost:5173");
    assertThat(log.get("request_id").asText()).isEqualTo("request-123");
    assertThat(log.get("runtime").asText()).isEqualTo("spring");
    assertThat(log.has("duration_ms")).isTrue();
    assertThat(line).doesNotContain("body-client");
    assertThat(line).doesNotContain("super-secret-token");
    assertThat(line).doesNotContain("Authorization");
  }

  @Test
  void fallsBackToDevClientHeaderAndGeneratedRequestId() throws Exception {
    Path accessLogPath = tempDir.resolve("api-access.log");
    SpringAccessLogFilter filter = new SpringAccessLogFilter(
      objectMapper,
      new MockEnvironment().withProperty("onmu.access-log.path", accessLogPath.toString())
    );
    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/healthz");
    request.addHeader("X-Onmu-Dev-Client", "header-client");
    MockHttpServletResponse response = new MockHttpServletResponse();
    FilterChain chain = (servletRequest, servletResponse) -> response.setStatus(200);

    filter.doFilter(request, response, chain);

    JsonNode log = objectMapper.readTree(Files.readString(accessLogPath, StandardCharsets.UTF_8));
    assertThat(log.get("dev_client").asText()).isEqualTo("header-client");
    assertThat(log.get("request_id").asText()).isNotBlank();
    assertThat(response.getHeader("X-Request-Id")).isEqualTo(log.get("request_id").asText());
  }

  @Test
  void ignoresClientFormParameterWhenQueryClientIsMissing() throws Exception {
    Path accessLogPath = tempDir.resolve("api-access.log");
    SpringAccessLogFilter filter = new SpringAccessLogFilter(
      objectMapper,
      new MockEnvironment().withProperty("onmu.access-log.path", accessLogPath.toString())
    );
    MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/groups");
    request.setContentType(MediaType.APPLICATION_FORM_URLENCODED_VALUE);
    request.setContent("client=body-client".getBytes(StandardCharsets.UTF_8));
    MockHttpServletResponse response = new MockHttpServletResponse();
    FilterChain chain = (servletRequest, servletResponse) -> response.setStatus(201);

    filter.doFilter(request, response, chain);

    String line = Files.readString(accessLogPath, StandardCharsets.UTF_8);
    JsonNode log = objectMapper.readTree(line);
    assertThat(log.get("dev_client").asText()).isEmpty();
    assertThat(line).doesNotContain("body-client");
  }

  @Test
  void trimsLongClientOriginAndRequestIdFields() throws Exception {
    Path accessLogPath = tempDir.resolve("api-access.log");
    SpringAccessLogFilter filter = new SpringAccessLogFilter(
      objectMapper,
      new MockEnvironment().withProperty("onmu.access-log.path", accessLogPath.toString())
    );
    String longClient = "c".repeat(120);
    String longOrigin = "https://" + "origin".repeat(40) + ".example";
    String longRequestId = "r".repeat(120);
    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/healthz");
    request.setQueryString("client=" + longClient);
    request.addHeader("Origin", longOrigin);
    request.addHeader("X-Request-Id", longRequestId);
    MockHttpServletResponse response = new MockHttpServletResponse();
    FilterChain chain = (servletRequest, servletResponse) -> response.setStatus(200);

    filter.doFilter(request, response, chain);

    JsonNode log = objectMapper.readTree(Files.readString(accessLogPath, StandardCharsets.UTF_8));
    assertThat(log.get("dev_client").asText()).hasSize(80);
    assertThat(log.get("origin").asText()).hasSize(200);
    assertThat(log.get("request_id").asText()).hasSize(80);
    assertThat(response.getHeader("X-Request-Id")).hasSize(80);
  }
}
