package com.onmu.api.config;

import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpMethod;
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
public class SecurityConfig {
  private static final List<String> DEFAULT_ALLOWED_ORIGINS = List.of(
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "https://dev-api.onmu.cloud"
  );

  private final DevTokenAuthenticationFilter devTokenAuthenticationFilter;
  private final Environment environment;

  public SecurityConfig(DevTokenAuthenticationFilter devTokenAuthenticationFilter, Environment environment) {
    this.devTokenAuthenticationFilter = devTokenAuthenticationFilter;
    this.environment = environment;
  }

  @Bean
  SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    return http
      .csrf(AbstractHttpConfigurer::disable)
      .httpBasic(AbstractHttpConfigurer::disable)
      .formLogin(AbstractHttpConfigurer::disable)
      .logout(AbstractHttpConfigurer::disable)
      .cors(cors -> {
      })
      .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(authorize -> authorize
        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
        .requestMatchers("/healthz", "/readyz", "/error", "/actuator/**").permitAll()
        .requestMatchers(HttpMethod.GET, "/api/v1/auth/session").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/auth/oauth/*").permitAll()
        .requestMatchers(HttpMethod.POST, "/api/v1/auth/refresh").permitAll()
        .requestMatchers("/api/v1/**").authenticated()
        .anyRequest().denyAll())
      .addFilterBefore(devTokenAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
      .build();
  }

  @Bean
  UserDetailsService userDetailsService() {
    return new InMemoryUserDetailsManager();
  }

  @Bean
  CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(allowedOrigins());
    configuration.setAllowedMethods(List.of("GET", "POST", "PATCH", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(List.of(
      "Authorization",
      "Content-Type",
      "Accept",
      "Origin",
      "X-Requested-With",
      "X-Onmu-Dev-Client"
    ));
    configuration.setExposedHeaders(List.of("Location"));
    configuration.setAllowCredentials(false);
    configuration.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
  }

  private List<String> allowedOrigins() {
    String configured = firstPresent(
      environment.getProperty("ONMU_DEV_CORS_ORIGINS"),
      environment.getProperty("onmu.security.cors.allowed-origins")
    );
    if (!StringUtils.hasText(configured)) {
      return DEFAULT_ALLOWED_ORIGINS;
    }

    List<String> origins = List.of(configured.split(",")).stream()
      .map(String::trim)
      .filter(StringUtils::hasText)
      .toList();
    return origins.isEmpty() ? DEFAULT_ALLOWED_ORIGINS : origins;
  }

  private String firstPresent(String first, String second) {
    if (StringUtils.hasText(first)) {
      return first;
    }
    if (StringUtils.hasText(second)) {
      return second;
    }
    return "";
  }
}
