package com.onmu.api.service;

import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.Connection;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

@Service
public class ReadinessProbeService {
  private static final int TCP_TIMEOUT_MILLIS = 1500;
  private static final Duration HTTP_TIMEOUT = Duration.ofSeconds(2);

  private final DataSource dataSource;
  private final Environment environment;
  private final HttpClient httpClient;

  @Autowired
  public ReadinessProbeService(DataSource dataSource, Environment environment) {
    this(dataSource, environment, HttpClient.newBuilder()
      .connectTimeout(HTTP_TIMEOUT)
      .build());
  }

  ReadinessProbeService(DataSource dataSource, Environment environment, HttpClient httpClient) {
    this.dataSource = dataSource;
    this.environment = environment;
    this.httpClient = httpClient;
  }

  public ReadinessReport check() {
    Map<String, Object> dependencies = new LinkedHashMap<>();
    boolean postgresOk = checkPostgres(dependencies);
    boolean redisOk = checkRedis(dependencies);
    boolean minioOk = checkMinio(dependencies);
    return new ReadinessReport(postgresOk && redisOk && minioOk, dependencies);
  }

  private boolean checkPostgres(Map<String, Object> dependencies) {
    try (Connection connection = dataSource.getConnection()) {
      boolean valid = connection.isValid(2);
      dependencies.put("postgres", Map.of(
        "ok", valid,
        "required", true,
        "detail", valid ? "connection_valid" : "connection_invalid"
      ));
      return valid;
    } catch (Exception exception) {
      dependencies.put("postgres", Map.of(
        "ok", false,
        "required", true,
        "error", exception.getClass().getSimpleName()
      ));
      return false;
    }
  }

  private boolean checkRedis(Map<String, Object> dependencies) {
    RedisTarget target;
    try {
      target = redisTarget();
    } catch (RuntimeException exception) {
      dependencies.put("redis", Map.of(
        "ok", false,
        "required", true,
        "error", "invalid_redis_config"
      ));
      return false;
    }

    try (Socket socket = new Socket()) {
      socket.connect(new InetSocketAddress(target.host(), target.port()), TCP_TIMEOUT_MILLIS);
      dependencies.put("redis", Map.of(
        "ok", true,
        "required", true,
        "detail", "tcp_connect_ok"
      ));
      return true;
    } catch (Exception exception) {
      dependencies.put("redis", Map.of(
        "ok", false,
        "required", true,
        "error", exception.getClass().getSimpleName()
      ));
      return false;
    }
  }

  private boolean checkMinio(Map<String, Object> dependencies) {
    URI healthUri;
    try {
      healthUri = minioHealthUri();
    } catch (RuntimeException exception) {
      dependencies.put("minio", Map.of(
        "ok", false,
        "required", true,
        "error", "invalid_minio_config"
      ));
      return false;
    }

    try {
      HttpRequest request = HttpRequest.newBuilder(healthUri)
        .timeout(HTTP_TIMEOUT)
        .GET()
        .build();
      int status = httpClient.send(request, HttpResponse.BodyHandlers.discarding()).statusCode();
      boolean ok = status >= 200 && status < 400;
      dependencies.put("minio", Map.of(
        "ok", ok,
        "required", true,
        "detail", "http_" + status
      ));
      return ok;
    } catch (Exception exception) {
      dependencies.put("minio", Map.of(
        "ok", false,
        "required", true,
        "error", exception.getClass().getSimpleName()
      ));
      return false;
    }
  }

  private RedisTarget redisTarget() {
    String redisUrl = firstText("REDIS_URL");
    if (redisUrl != null) {
      URI uri = URI.create(redisUrl);
      String host = uri.getHost();
      if (host == null || host.isBlank()) {
        throw new IllegalArgumentException("REDIS_URL host is missing");
      }
      int port = uri.getPort() > 0 ? uri.getPort() : 6379;
      return new RedisTarget(host, port);
    }

    String host = firstText("REDIS_HOST");
    int port = parsePort(firstText("REDIS_PORT"), 6379);
    return new RedisTarget(host == null ? "localhost" : host, port);
  }

  private URI minioHealthUri() {
    String endpoint = firstText("OBJECT_STORAGE_ENDPOINT", "MINIO_ENDPOINT");
    URI base = URI.create(endpoint == null ? "http://localhost:9000" : endpoint);
    String baseText = base.toString().replaceAll("/+$", "");
    return URI.create(baseText + "/minio/health/live");
  }

  private int parsePort(String value, int defaultPort) {
    if (value == null || value.isBlank()) {
      return defaultPort;
    }
    int port = Integer.parseInt(value);
    if (port <= 0 || port > 65535) {
      throw new IllegalArgumentException("port out of range");
    }
    return port;
  }

  private String firstText(String... names) {
    for (String name : names) {
      String value = environment.getProperty(name);
      if (value != null && !value.isBlank()) {
        return value.trim();
      }
    }
    return null;
  }

  public record ReadinessReport(boolean ok, Map<String, Object> dependencies) {
  }

  private record RedisTarget(String host, int port) {
  }
}
