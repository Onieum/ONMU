package com.onmu.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpHeaders;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

public class SpringAccessLogFilter extends OncePerRequestFilter {
  private static final Logger logger = LoggerFactory.getLogger(SpringAccessLogFilter.class);
  private static final String DEFAULT_ACCESS_LOG_PATH = "logs/api-access.log";
  private static final int MAX_CLIENT_LENGTH = 80;
  private static final int MAX_ORIGIN_LENGTH = 200;
  private static final int MAX_REQUEST_ID_LENGTH = 80;
  private static final Object WRITE_LOCK = new Object();

  private final ObjectMapper objectMapper;
  private final Path accessLogPath;

  public SpringAccessLogFilter(ObjectMapper objectMapper, Environment environment) {
    this.objectMapper = objectMapper;
    this.accessLogPath = Path.of(firstPresent(
      environment.getProperty("ONMU_ACCESS_LOG_PATH"),
      environment.getProperty("onmu.access-log.path"),
      DEFAULT_ACCESS_LOG_PATH
    ));
  }

  @Override
  protected void doFilterInternal(
    HttpServletRequest request,
    HttpServletResponse response,
    FilterChain filterChain
  ) throws ServletException, IOException {
    long started = System.nanoTime();
    String requestId = requestId(request);
    response.setHeader("X-Request-Id", requestId);

    try {
      filterChain.doFilter(request, response);
    } finally {
      writeAccessLog(request, response, requestId, started);
    }
  }

  private void writeAccessLog(
    HttpServletRequest request,
    HttpServletResponse response,
    String requestId,
    long started
  ) {
    long durationMs = Math.max(0L, (System.nanoTime() - started) / 1_000_000L);
    Map<String, Object> fields = new LinkedHashMap<>();
    fields.put("ts", Instant.now().toString());
    fields.put("method", request.getMethod());
    fields.put("path", request.getRequestURI());
    fields.put("status", response.getStatus());
    fields.put("duration_ms", durationMs);
    fields.put("dev_client", devClient(request));
    fields.put("origin", safeValue(request.getHeader(HttpHeaders.ORIGIN), MAX_ORIGIN_LENGTH));
    fields.put("request_id", requestId);
    fields.put("runtime", "spring");

    try {
      appendJsonLine(fields);
    } catch (IOException ex) {
      logger.warn("Spring access log write failed: {}", ex.getClass().getSimpleName());
    }
  }

  private void appendJsonLine(Map<String, Object> fields) throws IOException {
    Path parent = accessLogPath.getParent();
    if (parent != null) {
      Files.createDirectories(parent);
    }

    String line = objectMapper.writeValueAsString(fields) + System.lineSeparator();
    synchronized (WRITE_LOCK) {
      Files.writeString(
        accessLogPath,
        line,
        StandardCharsets.UTF_8,
        StandardOpenOption.CREATE,
        StandardOpenOption.APPEND
      );
    }
  }

  private String devClient(HttpServletRequest request) {
    String queryClient = safeValue(queryParameter(request, "client"), MAX_CLIENT_LENGTH);
    if (StringUtils.hasText(queryClient)) {
      return queryClient;
    }
    return safeValue(request.getHeader("X-Onmu-Dev-Client"), MAX_CLIENT_LENGTH);
  }

  private String queryParameter(HttpServletRequest request, String name) {
    String queryString = request.getQueryString();
    if (!StringUtils.hasText(queryString)) {
      return "";
    }

    for (String pair : queryString.split("&")) {
      int separator = pair.indexOf('=');
      String rawName = separator >= 0 ? pair.substring(0, separator) : pair;
      if (!name.equals(urlDecode(rawName))) {
        continue;
      }
      return separator >= 0 ? urlDecode(pair.substring(separator + 1)) : "";
    }

    return "";
  }

  private String urlDecode(String value) {
    try {
      return URLDecoder.decode(value, StandardCharsets.UTF_8);
    } catch (IllegalArgumentException ex) {
      return value;
    }
  }

  private String requestId(HttpServletRequest request) {
    String requestId = safeValue(request.getHeader("X-Request-Id"), MAX_REQUEST_ID_LENGTH);
    if (StringUtils.hasText(requestId)) {
      return requestId;
    }
    String correlationId = safeValue(request.getHeader("X-Correlation-Id"), MAX_REQUEST_ID_LENGTH);
    if (StringUtils.hasText(correlationId)) {
      return correlationId;
    }
    return UUID.randomUUID().toString();
  }

  private String safeValue(String value, int maxLength) {
    if (!StringUtils.hasText(value)) {
      return "";
    }
    String cleaned = value.replaceAll("[\\r\\n\\t]", " ").trim();
    return cleaned.length() <= maxLength ? cleaned : cleaned.substring(0, maxLength);
  }

  private String firstPresent(String... values) {
    for (String value : values) {
      if (StringUtils.hasText(value)) {
        return value;
      }
    }
    return DEFAULT_ACCESS_LOG_PATH;
  }
}
