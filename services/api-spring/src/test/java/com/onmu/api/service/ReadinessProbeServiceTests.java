package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.onmu.api.storage.ObjectStorageClient;
import com.onmu.api.storage.ObjectStorageProvider;
import java.sql.Connection;
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
      readyStorage(ObjectStorageProvider.MINIO, "minio_http_200")
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
      readyStorage(ObjectStorageProvider.MINIO, "minio_http_200")
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
      readyStorage(ObjectStorageProvider.MINIO, "minio_http_200")
    );

    var report = service.check();

    assertThat(report.ok()).isFalse();
    assertThat(report.dependencies().get("redis").toString()).contains("invalid_redis_config");
  }

  @Test
  void reportsObjectStorageProviderWhenReady() throws Exception {
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_URL", "redis://localhost:6379/0"),
      (targetHost, targetPort, timeoutMillis) -> {
      },
      readyStorage(ObjectStorageProvider.AZURE_BLOB, "azure_blob_container_exists")
    );

    var report = service.check();

    assertThat(report.ok()).isTrue();
    assertThat(report.dependencies().get("objectStorage").toString())
      .contains("azure_blob")
      .contains("azure_blob_container_exists");
  }

  @Test
  void failedObjectStorageReadinessDoesNotEchoEndpoint() throws Exception {
    ReadinessProbeService service = service(
      new MockEnvironment()
        .withProperty("REDIS_URL", "redis://localhost:6379/0"),
      (targetHost, targetPort, timeoutMillis) -> {
      },
      downStorage(ObjectStorageProvider.MINIO, "invalid_minio_config")
    );

    var report = service.check();

    assertThat(report.ok()).isFalse();
    assertThat(report.dependencies().get("objectStorage").toString())
      .contains("invalid_minio_config")
      .doesNotContain("localhost:9000");
  }

  private ReadinessProbeService service(
    MockEnvironment environment,
    ReadinessProbeService.TcpConnector tcpConnector,
    ObjectStorageClient objectStorageClient
  ) throws Exception {
    DataSource dataSource = Mockito.mock(DataSource.class);
    Connection connection = Mockito.mock(Connection.class);
    when(dataSource.getConnection()).thenReturn(connection);
    when(connection.isValid(2)).thenReturn(true);
    return new ReadinessProbeService(dataSource, environment, objectStorageClient, tcpConnector);
  }

  private ObjectStorageClient readyStorage(ObjectStorageProvider provider, String detail) {
    ObjectStorageClient client = Mockito.mock(ObjectStorageClient.class);
    when(client.provider()).thenReturn(provider);
    when(client.checkReadiness()).thenReturn(ObjectStorageClient.ReadinessResult.ok(detail));
    return client;
  }

  private ObjectStorageClient downStorage(ObjectStorageProvider provider, String error) {
    ObjectStorageClient client = Mockito.mock(ObjectStorageClient.class);
    when(client.provider()).thenReturn(provider);
    when(client.checkReadiness()).thenReturn(ObjectStorageClient.ReadinessResult.down(error));
    return client;
  }
}
