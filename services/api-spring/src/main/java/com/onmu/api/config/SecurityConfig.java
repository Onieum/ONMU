package com.onmu.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.security.BearerTokenAuthenticationFilter;
import jakarta.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableConfigurationProperties(AuthProperties.class)
public class SecurityConfig {
  private static final List<String> DEFAULT_ALLOWED_ORIGINS = List.of(
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "https://dev-api.onmu.cloud",
    "https://int-api.onmu.cloud"
  );

  private final Environment environment;

  public SecurityConfig(Environment environment) {
    this.environment = environment;
  }

  @Bean
  SecurityFilterChain securityFilterChain(
    HttpSecurity http,
    BearerTokenAuthenticationFilter bearerTokenAuthenticationFilter,
    ObjectMapper objectMapper
  ) throws Exception {
    return http
      .csrf(AbstractHttpConfigurer::disable)
      .httpBasic(AbstractHttpConfigurer::disable)
      .formLogin(AbstractHttpConfigurer::disable)
      .logout(AbstractHttpConfigurer::disable)
      .cors(cors -> {
      })
      .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .exceptionHandling(exceptions -> exceptions.authenticationEntryPoint((request, response, exception) -> {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getWriter(), java.util.Map.of(
          "ok", false,
          "error", "authentication_required"
        ));
      }))
      .authorizeHttpRequests(authorize -> authorize
        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
        .requestMatchers("/healthz", "/readyz", "/error", "/actuator/**").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/auth/oauth/**").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/auth/oauth/naver/callback").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/auth/oauth/naver/disconnect/callback").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/auth/oauth/kakao/callback").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/auth/oauth/kakao/logout").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/auth/oauth/kakao/logout/callback").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/auth/refresh").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/auth/logout").permitAll()
        .requestMatchers(HttpMethod.DELETE, "/api/v1/auth/session").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/media/public").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/place-images/public").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/internal/callbacks/**").permitAll()
        .requestMatchers("/api/v1/**").authenticated()
        .anyRequest().denyAll())
      .addFilterBefore(bearerTokenAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
      .addFilterBefore(new SpringAccessLogFilter(objectMapper, environment), BearerTokenAuthenticationFilter.class)
      .build();
  }

  @Bean
  UserDetailsService userDetailsService() {
    return new InMemoryUserDetailsManager();
  }

  @Bean
  CorsConfigurationSource corsConfigurationSource(AuthProperties authProperties) {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOriginPatterns(allowedOrigins(authProperties));
    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(List.of(
      "Authorization",
      "Content-Type",
      "Accept",
      "Origin",
      "X-Requested-With",
      "X-Onmu-Dev-Client",
      "X-Request-Id",
      "X-Correlation-Id"
    ));
    configuration.setExposedHeaders(List.of("Location", "X-Request-Id"));
    configuration.setAllowCredentials(false);
    configuration.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
  }

  private List<String> allowedOrigins(AuthProperties authProperties) {
    String configured = firstPresent(
      environment.getProperty("ONMU_CORS_ORIGINS"),
      environment.getProperty("ONMU_DEV_CORS_ORIGINS"),
      environment.getProperty("onmu.security.cors.allowed-origins")
    );
    List<String> origins = new ArrayList<>();
    if (StringUtils.hasText(configured)) {
      origins.addAll(List.of(configured.split(",")).stream()
        .map(String::trim)
        .filter(StringUtils::hasText)
        .toList());
    }
    if (authProperties.allowedOrigins() != null && !authProperties.allowedOrigins().isEmpty()) {
      origins.addAll(authProperties.allowedOrigins());
    }
    origins.addAll(DEFAULT_ALLOWED_ORIGINS);
    return new ArrayList<>(new LinkedHashSet<>(origins));
  }

  private String firstPresent(String... candidates) {
    for (String candidate : candidates) {
      if (StringUtils.hasText(candidate)) {
        return candidate;
      }
    }
    return "";
  }
}
