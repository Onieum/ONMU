package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.sql.Connection;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.env.MockEnvironment;

class ReadinessProbeServiceTests {
  @Test
  void parsesRedisUrl() throws Exception {
    AtomicReference<String> host = new AtomicReference<>();
    AtomicInteger port = new AtomicInteger();
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_URL", "redis://localhost:6379/0")
        .withProperty("MINIO_ENDPOINT", "http://localhost:9000"),
      (targetHost, targetPort, timeoutMillis) -> {
        host.set(targetHost);
        port.set(targetPort);
      },
      (uri, timeout) -> 200
    );

    var report = service.check();

    assertThat(report.ok()).isTrue();
    assertThat(host.get()).isEqualTo("localhost");
    assertThat(port.get()).isEqualTo(6379);
  }

  @Test
  void fallsBackToRedisHostAndPort() throws Exception {
    AtomicReference<String> host = new AtomicReference<>();
    AtomicInteger port = new AtomicInteger();
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_HOST", "redis.local")
        .withProperty("REDIS_PORT", "6380")
        .withProperty("MINIO_ENDPOINT", "http://localhost:9000"),
      (targetHost, targetPort, timeoutMillis) -> {
        host.set(targetHost);
        port.set(targetPort);
      },
      (uri, timeout) -> 200
    );

    var report = service.check();

    assertThat(report.ok()).isTrue();
    assertThat(host.get()).isEqualTo("redis.local");
    assertThat(port.get()).isEqualTo(6380);
  }

  @Test
  void invalidRedisPortMarksRedisAsDown() throws Exception {
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_HOST", "redis.local")
        .withProperty("REDIS_PORT", "not-a-port")
        .withProperty("MINIO_ENDPOINT", "http://localhost:9000"),
      (targetHost, targetPort, timeoutMillis) -> {
        throw new AssertionError("Redis connector should not be called for invalid config");
      },
      (uri, timeout) -> 200
    );

    var report = service.check();

    assertThat(report.ok()).isFalse();
    assertThat(report.dependencies().get("redis").toString()).contains("invalid_redis_config");
  }

  @Test
  void appendsMinioHealthPath() throws Exception {
    AtomicReference<URI> calledUri = new AtomicReference<>();
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_URL", "redis://localhost:6379/0")
        .withProperty("MINIO_ENDPOINT", "http://localhost:9000"),
      (targetHost, targetPort, timeoutMillis) -> {
      },
      (uri, timeout) -> {
        calledUri.set(uri);
        return 200;
      }
    );

    var report = service.check();

    assertThat(report.ok()).isTrue();
    assertThat(calledUri.get()).isEqualTo(URI.create("http://localhost:9000/minio/health/live"));
  }

  @Test
  void schemeLessMinioEndpointMarksMinioAsDownWithoutEchoingEndpoint() throws Exception {
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_URL", "redis://localhost:6379/0")
        .withProperty("MINIO_ENDPOINT", "localhost:9000"),
      (targetHost, targetPort, timeoutMillis) -> {
      },
      (uri, timeout) -> 200
    );

    var report = service.check();

    assertThat(report.ok()).isFalse();
    assertThat(report.dependencies().get("minio").toString())
      .contains("invalid_minio_config")
      .doesNotContain("localhost:9000");
  }

  private ReadinessProbeService service(
    MockEnvironment environment,
    ReadinessProbeService.TcpConnector tcpConnector,
    ReadinessProbeService.HttpStatusReader httpStatusReader
  ) throws Exception {
    DataSource dataSource = Mockito.mock(DataSource.class);
    Connection connection = Mockito.mock(Connection.class);
    when(dataSource.getConnection()).thenReturn(connection);
    when(connection.isValid(2)).thenReturn(true);
    return new ReadinessProbeService(dataSource, environment, tcpConnector, httpStatusReader);
  }
}
