package com.onmu.api.security;

import java.util.UUID;

public record AuthenticatedUser(UUID userId, String publicId) {
}
