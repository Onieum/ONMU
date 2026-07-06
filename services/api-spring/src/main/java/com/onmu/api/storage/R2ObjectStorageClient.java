package com.onmu.api.storage;

import java.io.InputStream;
import java.net.URI;
import java.time.Duration;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

/**
 * Cloudflare R2(S3 호환) 저장소 클라이언트.
 * R2 는 S3 API 와 호환되므로 AWS SDK v2 의 S3Client/S3Presigner 에
 * R2 엔드포인트를 override 해서 사용한다.
 */
public class R2ObjectStorageClient implements ObjectStorageClient {
  private static final Duration READINESS_TIMEOUT = Duration.ofSeconds(2);

  private final String bucket;
  private final S3Client s3Client;
  private final S3Presigner s3Presigner;

  public R2ObjectStorageClient(ObjectStorageProperties properties) {
    this(properties.bucket(), buildS3Client(properties), buildPresigner(properties));
  }

  R2ObjectStorageClient(String bucket, S3Client s3Client, S3Presigner s3Presigner) {
    this.bucket = bucket;
    this.s3Client = s3Client;
    this.s3Presigner = s3Presigner;
  }

  private static URI endpointUri(ObjectStorageProperties properties) {
    String endpoint = properties.endpoint();
    if (!StringUtils.hasText(endpoint)) {
      throw new IllegalArgumentException(
        "R2/S3 requires OBJECT_STORAGE_ENDPOINT (e.g. https://<accountid>.r2.cloudflarestorage.com)");
    }
    return URI.create(endpoint);
  }

  private static AwsBasicCredentials credentials(ObjectStorageProperties properties) {
    return AwsBasicCredentials.create(properties.accessKeyId(), properties.secretAccessKey());
  }

  private static S3Client buildS3Client(ObjectStorageProperties properties) {
    return S3Client.builder()
      .endpointOverride(endpointUri(properties))
      .region(Region.of(properties.region()))
      .credentialsProvider(StaticCredentialsProvider.create(credentials(properties)))
      .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
      .httpClientBuilder(UrlConnectionHttpClient.builder())
      .build();
  }

  private static S3Presigner buildPresigner(ObjectStorageProperties properties) {
    return S3Presigner.builder()
      .endpointOverride(endpointUri(properties))
      .region(Region.of(properties.region()))
      .credentialsProvider(StaticCredentialsProvider.create(credentials(properties)))
      .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
      .build();
  }

  @Override
  public ObjectStorageObject read(String objectKey) {
    try (ResponseInputStream<GetObjectResponse> response = s3Client.getObject(
      GetObjectRequest.builder().bucket(bucket).key(objectKey).build())) {
      String contentType = response.response().contentType();
      if (!StringUtils.hasText(contentType)) {
        contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
      }
      return new ObjectStorageObject(response.readAllBytes(), contentType);
    } catch (NoSuchKeyException exception) {
      throw new ObjectStorageNotFoundException("media_not_found", exception);
    } catch (S3Exception exception) {
      if (exception.statusCode() == 404) {
        throw new ObjectStorageNotFoundException("media_not_found", exception);
      }
      throw new ObjectStorageException("failed_to_read_media", exception);
    } catch (Exception exception) {
      throw new ObjectStorageException("failed_to_read_media", exception);
    }
  }

  @Override
  public String createUploadUrl(String objectKey, String contentType, Duration ttl) {
    try {
      PutObjectRequest objectRequest = PutObjectRequest.builder()
        .bucket(bucket)
        .key(objectKey)
        .contentType(contentType)
        .build();
      PresignedPutObjectRequest presigned = s3Presigner.presignPutObject(parameters -> parameters
        .signatureDuration(ttl)
        .putObjectRequest(objectRequest));
      return presigned.url().toString();
    } catch (Exception exception) {
      throw new ObjectStorageException("failed_to_generate_presigned_url", exception);
    }
  }

  @Override
  public void upload(String objectKey, InputStream inputStream, long size, String contentType) {
    try {
      s3Client.putObject(
        PutObjectRequest.builder()
          .bucket(bucket)
          .key(objectKey)
          .contentType(contentType)
          .build(),
        RequestBody.fromInputStream(inputStream, size));
    } catch (Exception exception) {
      throw new ObjectStorageException("failed_to_upload_media", exception);
    }
  }

  @Override
  public ReadinessResult checkReadiness() {
    try {
      // headBucket 는 실패 시 예외를 던지므로, 정상 리턴되면 버킷 접근 가능.
      s3Client.headBucket(
        HeadBucketRequest.builder()
          .bucket(bucket)
          .overrideConfiguration(configuration -> configuration.apiCallTimeout(READINESS_TIMEOUT))
          .build());
      return ReadinessResult.ok("r2_bucket_ok");
    } catch (Exception exception) {
      return ReadinessResult.down(exception.getClass().getSimpleName());
    }
  }

  @Override
  public ObjectStorageProvider provider() {
    return ObjectStorageProvider.R2;
  }
}
