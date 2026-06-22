import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/error/onmu_exception.dart';
import '../../../shared/models/group_models.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return ApiMediaRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class MediaRepository {
  Future<GroupMessageAttachment> uploadChatImage(PickedChatImage image);
}

class PickedChatImage {
  const PickedChatImage({
    required this.path,
    required this.fileName,
    this.contentType = 'image/jpeg',
    this.width,
    this.height,
  });

  final String path;
  final String fileName;
  final String contentType;
  final int? width;
  final int? height;
}

class ApiMediaRepository implements MediaRepository {
  ApiMediaRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<GroupMessageAttachment> uploadChatImage(PickedChatImage image) async {
    final response = await _client.postMultipartFile(
      '/api/v1/media/upload',
      fieldName: 'file',
      filePath: image.path,
      fileName: image.fileName,
      contentType: image.contentType,
    );
    final publicUrl = OnmuJson.readString(response, 'publicUrl');
    final storageKey = OnmuJson.readString(response, 'storageKey');
    if (publicUrl.isEmpty) {
      throw OnmuContractException.missingField(
        feature: 'chat',
        field: 'publicUrl',
        endpoint: '/api/v1/media/upload',
      );
    }
    if (storageKey.isEmpty) {
      throw OnmuContractException.missingField(
        feature: 'chat',
        field: 'storageKey',
        endpoint: '/api/v1/media/upload',
      );
    }
    return GroupMessageAttachment(
      type: 'image',
      publicUrl: _absoluteMediaUrl(publicUrl),
      storageKey: storageKey,
      contentType: image.contentType,
      fileName: image.fileName,
      width: image.width,
      height: image.height,
    );
  }

  String _absoluteMediaUrl(String url) {
    if (url.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      return url;
    }
    final baseUri = Uri.tryParse(_client.baseUrl);
    if (baseUri == null || _client.baseUrl.isEmpty) {
      return url;
    }
    return baseUri.resolve(url).toString();
  }
}
