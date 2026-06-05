package com.onmu.api.web;

import java.sql.Connection;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
  private final DataSource dataSource;
  private final String env;

  public HealthController(DataSource dataSource, @Value("${ONMU_ENV:local}") String env) {
    this.dataSource = dataSource;
    this.env = env;
  }

  @GetMapping("/healthz")
  public Map<String, Object> healthz() {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("ok", true);
    value.put("service", "onmu-api-spring");
    value.put("env", env);
    return value;
  }

  @GetMapping("/readyz")
  public ResponseEntity<Map<String, Object>> readyz() {
    Map<String, Object> checks = new LinkedHashMap<>();
    boolean postgresOk = checkPostgres(checks);
    checks.put("redis", Map.of("ok", true, "mode", "optional", "status", "not_required_yet"));
    checks.put("minio", Map.of("ok", true, "mode", "optional", "status", "not_required_yet"));

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("ok", postgresOk);
    value.put("service", "onmu-api-spring");
    value.put("env", env);
    value.put("dependencies", checks);
    return ResponseEntity.status(postgresOk ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).body(value);
  }

  private boolean checkPostgres(Map<String, Object> checks) {
    try (Connection connection = dataSource.getConnection()) {
      boolean valid = connection.isValid(2);
      checks.put("postgres", Map.of("ok", valid, "required", true));
      return valid;
    } catch (Exception exception) {
      checks.put("postgres", Map.of(
        "ok", false,
        "required", true,
        "error", exception.getClass().getSimpleName()
      ));
      return false;
    }
  }
}
