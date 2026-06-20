package com.onmu.api.service;

import com.onmu.api.storage.ObjectStorageClient;
import com.onmu.api.storage.ObjectStorageException;
import com.onmu.api.storage.ObjectStorageNotFoundException;
import com.onmu.api.storage.ObjectStorageObject;
import com.onmu.api.web.dto.UploadMediaResponse;
import com.onmu.api.web.dto.PresignedUrlResponse;
import java.io.ByteArrayInputStream;
import java.time.Duration;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
public class MediaService {
  private static final String PUBLIC_AVATAR_MEDIA_PREFIX = "dev/avatars/";
  private static final String PUBLIC_SEED_MEDIA_PREFIX = "dev/media/records/";
  private static final String UPLOADED_MEDIA_PREFIX = "records/media/";
  private static final Set<String> ALLOWED_IMAGE_EXTENSIONS = Set.of(
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".gif",
    ".heic",
    ".heif"
  );

  private static final Duration PRESIGNED_URL_TTL = Duration.ofHours(1);

  private final ObjectStorageClient objectStorageClient;

  public MediaService(ObjectStorageClient objectStorageClient) {
    this.objectStorageClient = objectStorageClient;
  }

  public PublicMediaObject readPublicSeedMedia(String objectKey) {
    validatePublicSeedMediaKey(objectKey);

    try {
      ObjectStorageObject object = objectStorageClient.read(objectKey);
      return new PublicMediaObject(object.content(), object.contentType());
    } catch (ObjectStorageNotFoundException exception) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "media_not_found", exception);
    } catch (ObjectStorageException exception) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_read_media", exception);
    }
  }

  public static String publicMediaUrl(String objectKey) {
    validatePublicMediaKey(objectKey);
    return "/api/v1/media/public?key=" + URLEncoder.encode(objectKey, StandardCharsets.UTF_8);
  }

  static void validatePublicSeedMediaKey(String objectKey) {
    validatePublicMediaKey(objectKey);
  }

  public static void validatePublicMediaKey(String objectKey) {
    if (!isAllowedPublicMediaKey(objectKey)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_media_key_prefix");
    }
  }

  public static boolean isAllowedPublicMediaKey(String objectKey) {
    if (!StringUtils.hasText(objectKey)) {
      return false;
    }
    String key = objectKey.trim();
    if (key.contains("..") || key.startsWith("/") || key.contains("\\")) {
      return false;
    }
    return key.startsWith(PUBLIC_SEED_MEDIA_PREFIX)
      || key.startsWith(PUBLIC_AVATAR_MEDIA_PREFIX)
      || key.startsWith(UPLOADED_MEDIA_PREFIX);
  }

  public PresignedUrlResponse generatePresignedUrl(String fileName, String contentType) {
    String extension = presignedImageExtension(fileName);
    String imageContentType = validateImageUpload(contentType, extension);

    String storageKey = "records/media/" + UUID.randomUUID().toString() + extension;

    try {
      String uploadUrl = objectStorageClient.createUploadUrl(storageKey, imageContentType, PRESIGNED_URL_TTL);

      String publicUrl = publicMediaUrl(storageKey);

      return new PresignedUrlResponse(uploadUrl, storageKey, publicUrl);
    } catch (ObjectStorageException exception) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "failed_to_generate_presigned_url", exception);
    }
  }

  public UploadMediaResponse uploadFile(MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "media_file_required");
    }

    String originalName = file != null ? file.getOriginalFilename() : "ootd.jpg";
    if (originalName == null || originalName.isBlank()) {
      originalName = "ootd.jpg";
    }
    String extension = originalName.contains(".") 
      ? originalName.substring(originalName.lastIndexOf(".")) 
      : ".jpg";
    String contentType = validateImageUpload(file.getContentType(), extension);

    String storageKey = "records/media/" + UUID.randomUUID().toString() + extension;

    try {
      objectStorageClient.upload(storageKey, file.getInputStream(), file.getSize(), contentType);
      String publicUrl = publicMediaUrl(storageKey);
      return new UploadMediaResponse(storageKey, publicUrl);
    } catch (Exception exception) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "failed_to_upload_media", exception);
    }
  }

  public UploadMediaResponse uploadGeneratedImage(byte[] content, String contentType) {
    if (content == null || content.length == 0) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "media_file_required");
    }
    String normalizedContentType = StringUtils.hasText(contentType) ? contentType.trim().toLowerCase(Locale.ROOT) : "image/png";
    String extension = switch (normalizedContentType) {
      case "image/jpeg", "image/jpg" -> ".jpg";
      case "image/webp" -> ".webp";
      default -> ".png";
    };
    String imageContentType = validateImageUpload(normalizedContentType, extension);
    String storageKey = "records/media/generated/ootd/" + UUID.randomUUID().toString() + extension;

    try {
      objectStorageClient.upload(storageKey, new ByteArrayInputStream(content), content.length, imageContentType);
      String publicUrl = publicMediaUrl(storageKey);
      return new UploadMediaResponse(storageKey, publicUrl);
    } catch (Exception exception) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "failed_to_upload_media", exception);
    }
  }

  private String presignedImageExtension(String fileName) {
    if (!StringUtils.hasText(fileName)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_media_type");
    }
    String originalName = fileName.trim();
    int extensionStart = originalName.lastIndexOf(".");
    if (extensionStart < 0 || extensionStart == originalName.length() - 1) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_media_type");
    }
    return originalName.substring(extensionStart).toLowerCase(Locale.ROOT);
  }

  private String validateImageUpload(String contentType, String extension) {
    String normalizedExtension = extension == null ? "" : extension.toLowerCase(Locale.ROOT);
    if (!StringUtils.hasText(contentType)
      || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")
      || !ALLOWED_IMAGE_EXTENSIONS.contains(normalizedExtension)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_media_type");
    }
    return contentType;
  }

  public record PublicMediaObject(byte[] content, String contentType) {
  }
}
