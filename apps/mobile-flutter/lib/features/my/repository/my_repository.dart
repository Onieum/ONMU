import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../domain/korea_region.dart';
import '../domain/my_profile.dart';

final myRepositoryProvider = Provider<MyRepository>((ref) {
  return ApiMyRepository(ref.watch(onmuApiClientProvider));
});

final myProfileProvider = FutureProvider<MyProfile>((ref) {
  return ref.watch(myRepositoryProvider).fetchMyProfile();
});

abstract interface class MyRepository {
  Future<MyProfile> fetchMyProfile();

  Future<MyProfile> updateMyProfile(
    MyProfile profile, {
    String? onboardingStatus,
  });

  Future<MyProfile> updateOnboardingStatus(String onboardingStatus);

  Future<String> uploadProfileImage(Uint8List bytes, String fileName);
}

class ApiMyRepository implements MyRepository {
  ApiMyRepository(this._client);

  static const _defaultIntroText = '';

  final OnmuApiClient _client;

  @override
  Future<MyProfile> fetchMyProfile() async {
    final json = await _client.getObject('/api/v1/users/me');
    return _profileFromJson(json);
  }

  @override
  Future<MyProfile> updateMyProfile(
    MyProfile profile, {
    String? onboardingStatus,
  }) async {
    final body = {
      'nickname': profile.realName,
      'profileImageUrl': profile.profileImageUrl,
      'preferenceProfile': _preferenceProfileJson(profile),
    };
    if (onboardingStatus != null) {
      body['onboardingStatus'] = onboardingStatus;
    }
    final json = await _client.patchObject('/api/v1/users/me', body: body);
    return _profileFromJson(json);
  }

  @override
  Future<MyProfile> updateOnboardingStatus(String onboardingStatus) async {
    final json = await _client.patchObject(
      '/api/v1/users/me',
      body: {'onboardingStatus': onboardingStatus},
    );
    return _profileFromJson(json);
  }

  MyProfile _profileFromJson(Map<String, dynamic> json) {
    final preference = OnmuJson.asMap(json['preferenceProfile']);
    final nickname = resolveOnmuDisplayName([
      OnmuJson.readString(json, 'nickname'),
      OnmuJson.readString(json, 'displayName'),
    ], fallback: '');
    final regionSelection = _safeRegionSelection(preference['region']);
    return MyProfile(
      realName: nickname,
      profileImageUrl: _absoluteApiUrl(
        OnmuJson.readString(json, 'profileImageUrl'),
      ),
      introText: _readProfileText(preference, 'introText', _defaultIntroText),
      region: regionSelection.displayName,
      regionSelection: regionSelection,
      regionVisibility: RegionVisibility.fromJson(
        preference['regionVisibility'],
      ),
      visibility: ProfileVisibility.fromJson(preference['profileVisibility']),
      searchAllowed: OnmuJson.readBool(preference, 'searchAllowed', true),
      favoriteKeywords: _readProfileStringList(preference['favoriteKeywords']),
      dislikedKeywords: _readProfileStringList(preference['dislikedKeywords']),
      preferredTimes: _readProfileStringList(preference['preferredTimes']),
      availableDays: _readProfileStringList(preference['availableDays']),
      unavailableDates: _readProfileStringList(preference['unavailableDates']),
      favoritePlaces: const [],
      wantToGoPlaces: const [],
      dislikedPlaces: const [],
      favoriteFoodTags: _readProfileStringList(preference['favoriteFoodTags']),
      dislikedFoodTags: _readProfileStringList(preference['dislikedFoodTags']),
      favoritePlaceTags: _readProfileStringList(
        preference['favoritePlaceTags'],
      ),
      dislikedPlaceTags: _readProfileStringList(
        preference['dislikedPlaceTags'],
      ),
      planStyles: _readProfileStringList(preference['planStyles']),
      preferredWeekdays: _readProfileStringList(
        preference['preferredWeekdays'],
      ),
    );
  }

  @override
  Future<String> uploadProfileImage(Uint8List bytes, String fileName) async {
    final json = await _client.uploadMultipart(
      '/api/v1/media/upload',
      bytes,
      fileName,
    );
    final publicUrl = OnmuJson.readString(json, 'publicUrl');
    if (publicUrl.isEmpty) {
      throw StateError('profile_image_upload_public_url_missing');
    }
    return _absoluteApiUrl(publicUrl);
  }

  Map<String, Object?> _preferenceProfileJson(MyProfile profile) {
    final regionSelection = _safeRegionSelection(
      profile.effectiveRegionSelection.toJson(),
    );
    return {
      'favoriteKeywords': _safeProfileStringList(profile.favoriteKeywords),
      'introText': _safeProfileText(profile.introText),
      'profileVisibility': profile.visibility.value,
      'searchAllowed': profile.searchAllowed,
      'region': regionSelection.toJson(),
      'regionVisibility': profile.regionVisibility.value,
      'dislikedKeywords': _safeProfileStringList(profile.dislikedKeywords),
      'preferredTimes': _safeProfileStringList(profile.preferredTimes),
      'availableDays': _safeProfileStringList(profile.availableDays),
      'unavailableDates': _safeProfileStringList(profile.unavailableDates),
      'favoriteFoodTags': _safeProfileStringList(profile.favoriteFoodTags),
      'dislikedFoodTags': _safeProfileStringList(profile.dislikedFoodTags),
      'favoritePlaceTags': _safeProfileStringList(profile.favoritePlaceTags),
      'dislikedPlaceTags': _safeProfileStringList(profile.dislikedPlaceTags),
      'planStyles': _safeProfileStringList(profile.planStyles),
      'preferredWeekdays': _safeProfileStringList(profile.preferredWeekdays),
    };
  }

  String _readProfileText(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    return _safeProfileText(OnmuJson.readString(json, key, fallback), fallback);
  }

  List<String> _readProfileStringList(Object? value) {
    return _safeProfileStringList(OnmuJson.stringList(value));
  }

  List<String> _safeProfileStringList(List<String> values) {
    return values.where(_isSafeProfileText).toList(growable: false);
  }

  String _safeProfileText(String value, [String fallback = '']) {
    return _isSafeProfileText(value) ? value : fallback;
  }

  KoreaRegionSelection _safeRegionSelection(Object? value) {
    final selection = KoreaRegionSelection.fromJson(value);
    if (selection.displayName.trim().isEmpty) {
      return KoreaRegionSelection.empty;
    }
    if (_isSafeProfileText(selection.sido) &&
        _isSafeProfileText(selection.sigungu) &&
        _isSafeProfileText(selection.displayName)) {
      return selection;
    }
    return KoreaRegionSelection.fallback;
  }

  bool _isSafeProfileText(String value) {
    final trimmed = value.trim();
    return !_looksLikeMojibake(trimmed) &&
        !_looksLikeStructuredJsonText(trimmed);
  }

  String _absoluteApiUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (!trimmed.startsWith('/')) return trimmed;
    final baseUrl = _client.baseUrl.endsWith('/')
        ? _client.baseUrl.substring(0, _client.baseUrl.length - 1)
        : _client.baseUrl;
    return '$baseUrl$trimmed';
  }

  bool _looksLikeMojibake(String value) {
    var hasUtf8LeadByteGlyph = false;
    var hasUtf8ContinuationByteGlyph = false;
    for (final codePoint in value.runes) {
      if (codePoint == 0xFFFD || (codePoint >= 0x0080 && codePoint <= 0x009F)) {
        return true;
      }
      if (codePoint == 0x00C2 ||
          codePoint == 0x00C3 ||
          codePoint == 0x00EA ||
          codePoint == 0x00EB ||
          codePoint == 0x00EC ||
          codePoint == 0x00ED ||
          codePoint == 0x00EE ||
          codePoint == 0x00EF ||
          codePoint == 0x00F0) {
        hasUtf8LeadByteGlyph = true;
      }
      if ((codePoint >= 0x2018 && codePoint <= 0x201D) ||
          codePoint == 0x201A ||
          codePoint == 0x201E ||
          codePoint == 0x2026 ||
          codePoint == 0x2039 ||
          codePoint == 0x203A ||
          codePoint == 0x0152 ||
          codePoint == 0x0153 ||
          codePoint == 0x0160 ||
          codePoint == 0x0161 ||
          codePoint == 0x017D ||
          codePoint == 0x017E ||
          codePoint == 0x00A0 ||
          codePoint == 0x00A4 ||
          codePoint == 0x00A9 ||
          codePoint == 0x00B0 ||
          codePoint == 0x00B4 ||
          codePoint == 0x00B5 ||
          codePoint == 0x00B8) {
        hasUtf8ContinuationByteGlyph = true;
      }
    }
    return hasUtf8LeadByteGlyph && hasUtf8ContinuationByteGlyph;
  }

  bool _looksLikeStructuredJsonText(String value) {
    if (value.length < 2) {
      return false;
    }
    final objectLike = value.startsWith('{') && value.endsWith('}');
    final arrayLike = value.startsWith('[') && value.endsWith(']');
    if (!objectLike && !arrayLike) {
      return false;
    }
    try {
      final decoded = jsonDecode(value);
      return decoded is Map || decoded is List;
    } on FormatException {
      return false;
    }
  }
}
