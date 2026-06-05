package com.onmu.api.web;

import com.onmu.api.service.ReadinessProbeService;
import com.onmu.api.service.ReadinessProbeService.ReadinessReport;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
  private final ReadinessProbeService readinessProbeService;
  private final String env;

  public HealthController(ReadinessProbeService readinessProbeService, @Value("${ONMU_ENV:local}") String env) {
    this.readinessProbeService = readinessProbeService;
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
    ReadinessReport report = readinessProbeService.check();

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("ok", report.ok());
    value.put("service", "onmu-api-spring");
    value.put("env", env);
    value.put("dependencies", report.dependencies());
    return ResponseEntity.status(report.ok() ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).body(value);
  }
}
