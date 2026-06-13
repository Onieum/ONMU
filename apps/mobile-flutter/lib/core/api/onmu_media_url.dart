import 'onmu_api_client.dart';

String resolveOnmuMediaUrl(
  String? url, {
  String baseUrl = defaultOnmuApiBaseUrl,
}) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    return trimmed;
  }

  final baseUri = Uri.tryParse(baseUrl);
  if (baseUri == null || baseUrl.trim().isEmpty) {
    return trimmed;
  }

  if (_isPublicSeedMediaKey(trimmed)) {
    final mediaUri = Uri(
      path: '/api/v1/media/public',
      queryParameters: {'key': trimmed},
    );
    return baseUri.resolveUri(mediaUri).toString();
  }

  return baseUri.resolve(trimmed).toString();
}

bool _isPublicSeedMediaKey(String value) {
  return value.startsWith('dev/media/records/') ||
      value.startsWith('dev/avatars/');
}
