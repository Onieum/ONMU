package com.onmu.api.service;

import com.onmu.api.storage.ObjectStorageClient;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.sql.Connection;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

@Service
public class ReadinessProbeService {
  private static final int TCP_TIMEOUT_MILLIS = 1500;

  private final DataSource dataSource;
  private final Environment environment;
  private final ObjectStorageClient objectStorageClient;
  private final TcpConnector tcpConnector;

  @Autowired
  public ReadinessProbeService(
    DataSource dataSource,
    Environment environment,
    ObjectStorageClient objectStorageClient
  ) {
    this(dataSource, environment, objectStorageClient, defaultTcpConnector());
  }

  ReadinessProbeService(
    DataSource dataSource,
    Environment environment,
    ObjectStorageClient objectStorageClient,
    TcpConnector tcpConnector
  ) {
    this.dataSource = dataSource;
    this.environment = environment;
    this.objectStorageClient = objectStorageClient;
    this.tcpConnector = tcpConnector;
  }

  public ReadinessReport check() {
    Map<String, Object> dependencies = new LinkedHashMap<>();
    boolean postgresOk = checkPostgres(dependencies);
    boolean redisOk = checkRedis(dependencies);
    boolean objectStorageOk = checkObjectStorage(dependencies);
    return new ReadinessReport(postgresOk && redisOk && objectStorageOk, dependencies);
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

    try {
      tcpConnector.connect(target.host(), target.port(), TCP_TIMEOUT_MILLIS);
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

  private boolean checkObjectStorage(Map<String, Object> dependencies) {
    ObjectStorageClient.ReadinessResult result = objectStorageClient.checkReadiness();
    if (result.ok()) {
      dependencies.put(objectStorageClient.provider().dependencyName(), Map.of(
        "ok", true,
        "required", true,
        "provider", objectStorageClient.provider().detailName(),
        "detail", result.detail()
      ));
      return true;
    }

    dependencies.put(objectStorageClient.provider().dependencyName(), Map.of(
      "ok", false,
      "required", true,
      "provider", objectStorageClient.provider().detailName(),
      "error", result.error()
    ));
    return false;
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

  @FunctionalInterface
  interface TcpConnector {
    void connect(String host, int port, int timeoutMillis) throws Exception;
  }

  private record RedisTarget(String host, int port) {
  }

  private static TcpConnector defaultTcpConnector() {
    return (host, port, timeoutMillis) -> {
      try (Socket socket = new Socket()) {
        socket.connect(new InetSocketAddress(host, port), timeoutMillis);
      }
    };
  }

}
