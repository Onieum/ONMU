import '../../core/api/onmu_api_client.dart';
import '../../core/api/onmu_media_url.dart';

String resolveOnmuProfileImageUrl(
  Map<String, dynamic> json, {
  String primaryKey = 'profileImageUrl',
  String baseUrl = defaultOnmuApiBaseUrl,
}) {
  final url = _firstNonEmpty([
    if (primaryKey.isNotEmpty) OnmuJson.readString(json, primaryKey),
    ..._prefixedProfileImageAliases(json, primaryKey),
    if (primaryKey != 'profileImageUrl')
      OnmuJson.readString(json, 'profileImageUrl'),
    OnmuJson.readString(json, 'profilePhotoUrl'),
    OnmuJson.readString(json, 'avatarUrl'),
  ]);
  return resolveOnmuProfileImageValue(url, baseUrl: baseUrl);
}

String resolveOnmuProfileImageValue(
  String? value, {
  String baseUrl = defaultOnmuApiBaseUrl,
}) {
  return resolveOnmuMediaUrl(value, baseUrl: baseUrl);
}

String _firstNonEmpty(Iterable<String> values) {
  for (final value in values) {
    final clean = value.trim();
    if (clean.isNotEmpty) {
      return clean;
    }
  }
  return '';
}

Iterable<String> _prefixedProfileImageAliases(
  Map<String, dynamic> json,
  String primaryKey,
) {
  const suffix = 'ProfileImageUrl';
  if (!primaryKey.endsWith(suffix) || primaryKey == 'profileImageUrl') {
    return const [];
  }

  final prefix = primaryKey.substring(0, primaryKey.length - suffix.length);
  if (prefix.isEmpty) {
    return const [];
  }

  return [
    OnmuJson.readString(json, '${prefix}ProfilePhotoUrl'),
    OnmuJson.readString(json, '${prefix}AvatarUrl'),
  ];
}
