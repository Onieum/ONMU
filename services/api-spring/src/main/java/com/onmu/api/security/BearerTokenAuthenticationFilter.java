package com.onmu.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.server.ResponseStatusException;

@Component
public class BearerTokenAuthenticationFilter extends OncePerRequestFilter {
  private final AccessTokenVerifier accessTokenVerifier;
  private final UserRepository userRepository;
  private final ObjectMapper objectMapper;

  public BearerTokenAuthenticationFilter(
    AccessTokenVerifier accessTokenVerifier,
    UserRepository userRepository,
    ObjectMapper objectMapper
  ) {
    this.accessTokenVerifier = accessTokenVerifier;
    this.userRepository = userRepository;
    this.objectMapper = objectMapper;
  }

  @Override
  protected void doFilterInternal(
    HttpServletRequest request,
    HttpServletResponse response,
    FilterChain filterChain
  ) throws ServletException, IOException {
    String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
    if (authorization == null || authorization.isBlank()) {
      filterChain.doFilter(request, response);
      return;
    }
    if (!authorization.startsWith("Bearer ")) {
      writeUnauthorized(response, "invalid_authorization_header");
      return;
    }

    try {
      String publicId = accessTokenVerifier.verify(authorization.substring("Bearer ".length()).trim());
      UserEntity activeUser = userRepository.findByPublicIdAndDeletedAtIsNull(publicId)
        .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "user_not_found"));
      AuthenticatedUser user = new AuthenticatedUser(activeUser.getId(), activeUser.getPublicId());
      UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
        user,
        null,
        List.of(new SimpleGrantedAuthority("ROLE_USER"))
      );
      SecurityContextHolder.getContext().setAuthentication(authentication);
      filterChain.doFilter(request, response);
    } catch (ResponseStatusException exception) {
      SecurityContextHolder.clearContext();
      writeUnauthorized(response, exception.getReason() == null ? "invalid_token" : exception.getReason());
    }
  }

  private void writeUnauthorized(HttpServletResponse response, String code) throws IOException {
    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    objectMapper.writeValue(response.getWriter(), Map.of(
      "ok", false,
      "error", code
    ));
  }
}
