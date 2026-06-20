import '../../../shared/models/character_model.dart';
import 'korea_region.dart';

enum ProfileVisibility {
  private('PRIVATE', '비공개'),
  friends('FRIENDS', '친구 공개'),
  public('PUBLIC', '전체 공개');

  const ProfileVisibility(this.value, this.label);

  final String value;
  final String label;

  static ProfileVisibility fromJson(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return switch (normalized) {
      'PRIVATE' => ProfileVisibility.private,
      'PUBLIC' => ProfileVisibility.public,
      _ => ProfileVisibility.friends,
    };
  }
}

class ProfilePlace {
  const ProfilePlace({
    required this.name,
    required this.category,
    required this.description,
  });

  final String name;
  final String category;
  final String description;
}

class MyProfile {
  const MyProfile({
    required this.realName,
    required this.visibility,
    required this.favoriteKeywords,
    required this.dislikedKeywords,
    required this.preferredTimes,
    required this.availableDays,
    required this.unavailableDates,
    required this.favoritePlaces,
    required this.wantToGoPlaces,
    required this.dislikedPlaces,
    this.introText = '',
    this.region = '',
    this.regionSelection,
    this.regionVisibility = RegionVisibility.private,
    this.favoriteFoodTags = const [],
    this.dislikedFoodTags = const [],
    this.favoritePlaceTags = const [],
    this.dislikedPlaceTags = const [],
    this.planStyles = const [],
    this.preferredWeekdays = const [],
    this.profileImageUrl = '',
    this.searchAllowed = true,
    this.useDefaultProfileImage = false,
    this.character,
  });

  final String realName;
  final String introText;
  final String region;
  final KoreaRegionSelection? regionSelection;
  final RegionVisibility regionVisibility;
  final ProfileVisibility visibility;
  final List<String> favoriteKeywords;
  final List<String> dislikedKeywords;
  final List<String> preferredTimes;
  final List<String> availableDays;
  final List<String> unavailableDates;
  final List<ProfilePlace> favoritePlaces;
  final List<ProfilePlace> wantToGoPlaces;
  final List<ProfilePlace> dislikedPlaces;
  final List<String> favoriteFoodTags;
  final List<String> dislikedFoodTags;
  final List<String> favoritePlaceTags;
  final List<String> dislikedPlaceTags;
  final List<String> planStyles;
  final List<String> preferredWeekdays;
  final String profileImageUrl;
  final bool searchAllowed;
  final bool useDefaultProfileImage;
  final CharacterDraft? character;

  List<String> get preferenceHighlights {
    return [...favoriteFoodTags, ...favoritePlaceTags, ...planStyles];
  }

  KoreaRegionSelection get effectiveRegionSelection {
    return regionSelection ?? KoreaRegionSelection.fromDisplayName(region);
  }

  MyProfile copyWith({
    String? realName,
    String? introText,
    String? region,
    KoreaRegionSelection? regionSelection,
    RegionVisibility? regionVisibility,
    ProfileVisibility? visibility,
    List<String>? favoriteKeywords,
    List<String>? dislikedKeywords,
    List<String>? preferredTimes,
    List<String>? availableDays,
    List<String>? unavailableDates,
    List<ProfilePlace>? favoritePlaces,
    List<ProfilePlace>? wantToGoPlaces,
    List<ProfilePlace>? dislikedPlaces,
    List<String>? favoriteFoodTags,
    List<String>? dislikedFoodTags,
    List<String>? favoritePlaceTags,
    List<String>? dislikedPlaceTags,
    List<String>? planStyles,
    List<String>? preferredWeekdays,
    String? profileImageUrl,
    bool? searchAllowed,
    bool? useDefaultProfileImage,
    CharacterDraft? character,
  }) {
    return MyProfile(
      realName: realName ?? this.realName,
      introText: introText ?? this.introText,
      region: region ?? this.region,
      regionSelection:
          regionSelection ??
          (region == null
              ? this.regionSelection
              : KoreaRegionSelection.fromDisplayName(region)),
      regionVisibility: regionVisibility ?? this.regionVisibility,
      visibility: visibility ?? this.visibility,
      favoriteKeywords: favoriteKeywords ?? this.favoriteKeywords,
      dislikedKeywords: dislikedKeywords ?? this.dislikedKeywords,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      availableDays: availableDays ?? this.availableDays,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      favoritePlaces: favoritePlaces ?? this.favoritePlaces,
      wantToGoPlaces: wantToGoPlaces ?? this.wantToGoPlaces,
      dislikedPlaces: dislikedPlaces ?? this.dislikedPlaces,
      favoriteFoodTags: favoriteFoodTags ?? this.favoriteFoodTags,
      dislikedFoodTags: dislikedFoodTags ?? this.dislikedFoodTags,
      favoritePlaceTags: favoritePlaceTags ?? this.favoritePlaceTags,
      dislikedPlaceTags: dislikedPlaceTags ?? this.dislikedPlaceTags,
      planStyles: planStyles ?? this.planStyles,
      preferredWeekdays: preferredWeekdays ?? this.preferredWeekdays,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      searchAllowed: searchAllowed ?? this.searchAllowed,
      useDefaultProfileImage:
          useDefaultProfileImage ?? this.useDefaultProfileImage,
      character: character ?? this.character,
    );
  }
}

class FriendProfile {
  const FriendProfile({
    this.userId = '',
    this.publicId = '',
    this.userCode = '',
    required this.name,
    required this.preferenceSummary,
    required this.isFriend,
    this.isFavorite = false,
    this.memo = '',
    this.profileImageUrl = '',
    this.introText = '',
    this.useDefaultProfileImage = false,
    this.friendshipCreatedAt,
    this.character,
  });

  final String userId;
  final String publicId;
  final String userCode;
  final String name;
  final String preferenceSummary;
  final bool isFriend;
  final bool isFavorite;
  final String memo;
  final String profileImageUrl;
  final String introText;
  final bool useDefaultProfileImage;
  final DateTime? friendshipCreatedAt;
  final CharacterDraft? character;

  String get memoOrCode {
    final cleanMemo = memo.trim();
    if (cleanMemo.isNotEmpty) {
      return cleanMemo;
    }
    final cleanCode = userCode.trim();
    if (cleanCode.isNotEmpty) {
      return cleanCode;
    }
    return publicId;
  }

  FriendProfile copyWith({
    bool? isFriend,
    bool? isFavorite,
    String? memo,
    String? introText,
    bool? useDefaultProfileImage,
    DateTime? friendshipCreatedAt,
    CharacterDraft? character,
  }) {
    return FriendProfile(
      userId: userId,
      publicId: publicId,
      userCode: userCode,
      name: name,
      preferenceSummary: preferenceSummary,
      isFriend: isFriend ?? this.isFriend,
      isFavorite: isFavorite ?? this.isFavorite,
      memo: memo ?? this.memo,
      profileImageUrl: profileImageUrl,
      introText: introText ?? this.introText,
      useDefaultProfileImage:
          useDefaultProfileImage ?? this.useDefaultProfileImage,
      friendshipCreatedAt: friendshipCreatedAt ?? this.friendshipCreatedAt,
      character: character ?? this.character,
    );
  }
}
