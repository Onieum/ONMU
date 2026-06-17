package com.onmu.api.storage;

import com.azure.core.http.rest.Response;
import com.azure.core.util.Context;
import com.azure.core.util.BinaryData;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobHttpHeaders;
import com.azure.storage.blob.models.BlobProperties;
import com.azure.storage.blob.models.BlobStorageException;
import com.azure.storage.blob.models.UserDelegationKey;
import com.azure.storage.blob.sas.BlobSasPermission;
import com.azure.storage.blob.sas.BlobServiceSasSignatureValues;
import java.io.InputStream;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;

public class AzureBlobObjectStorageClient implements ObjectStorageClient {
  private final BlobServiceClient serviceClient;
  private final BlobContainerClient containerClient;

  public AzureBlobObjectStorageClient(ObjectStorageProperties properties) {
    DefaultAzureCredentialBuilder credentialBuilder = new DefaultAzureCredentialBuilder();
    if (StringUtils.hasText(properties.managedIdentityClientId())) {
      credentialBuilder.managedIdentityClientId(properties.managedIdentityClientId());
    }
    this.serviceClient = new BlobServiceClientBuilder()
      .endpoint(properties.endpoint())
      .credential(credentialBuilder.build())
      .buildClient();
    this.containerClient = serviceClient.getBlobContainerClient(properties.bucket());
  }

  AzureBlobObjectStorageClient(BlobServiceClient serviceClient, BlobContainerClient containerClient) {
    this.serviceClient = serviceClient;
    this.containerClient = containerClient;
  }

  @Override
  public ObjectStorageObject read(String objectKey) {
    try {
      BlobClient blobClient = containerClient.getBlobClient(objectKey);
      BlobProperties properties = blobClient.getProperties();
      String contentType = properties.getContentType();
      if (!StringUtils.hasText(contentType)) {
        contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
      }
      BinaryData content = blobClient.downloadContent();
      return new ObjectStorageObject(content.toBytes(), contentType);
    } catch (BlobStorageException exception) {
      if (exception.getStatusCode() == 404) {
        throw new ObjectStorageNotFoundException("media_not_found", exception);
      }
      throw new ObjectStorageException("failed_to_read_media", exception);
    } catch (RuntimeException exception) {
      throw new ObjectStorageException("failed_to_read_media", exception);
    }
  }

  @Override
  public String createUploadUrl(String objectKey, String contentType, Duration ttl) {
    try {
      BlobClient blobClient = containerClient.getBlobClient(objectKey);
      OffsetDateTime startsOn = OffsetDateTime.now(ZoneOffset.UTC).minusMinutes(5);
      OffsetDateTime expiresOn = OffsetDateTime.now(ZoneOffset.UTC).plus(ttl);
      UserDelegationKey delegationKey = serviceClient.getUserDelegationKey(startsOn, expiresOn);
      BlobSasPermission permission = new BlobSasPermission()
        .setCreatePermission(true)
        .setWritePermission(true);
      BlobServiceSasSignatureValues values = new BlobServiceSasSignatureValues(expiresOn, permission)
        .setStartTime(startsOn)
        .setContentType(contentType);
      return blobClient.getBlobUrl() + "?" + blobClient.generateUserDelegationSas(values, delegationKey);
    } catch (RuntimeException exception) {
      throw new ObjectStorageException("failed_to_generate_presigned_url", exception);
    }
  }

  @Override
  public void upload(String objectKey, InputStream inputStream, long size, String contentType) {
    try {
      BlobClient blobClient = containerClient.getBlobClient(objectKey);
      blobClient.upload(inputStream, size, true);
      blobClient.setHttpHeaders(new BlobHttpHeaders().setContentType(contentType));
    } catch (RuntimeException exception) {
      throw new ObjectStorageException("failed_to_upload_media", exception);
    }
  }

  @Override
  public ReadinessResult checkReadiness() {
    try {
      Response<Boolean> response = containerClient.existsWithResponse(Duration.ofSeconds(2), Context.NONE);
      return Boolean.TRUE.equals(response.getValue())
        ? ReadinessResult.ok("azure_blob_container_exists")
        : ReadinessResult.down("azure_blob_container_missing");
    } catch (RuntimeException exception) {
      return ReadinessResult.down(exception.getClass().getSimpleName());
    }
  }

  @Override
  public ObjectStorageProvider provider() {
    return ObjectStorageProvider.AZURE_BLOB;
  }
}
