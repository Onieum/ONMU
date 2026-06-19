class PreferenceProfile {
  final List<String> favoriteFoodTags;
  final List<String> dislikedFoodTags;
  final String otherFavoriteFood;
  final String otherDislikedFood;
  final List<String> favoritePlaceTags;
  final List<String> dislikedPlaceTags;
  final String otherFavoritePlace;
  final String otherDislikedPlace;
  final List<String> planStyles;
  final List<String> preferredWeekdays;
  final List<String> preferredTimes;
  final List<String> unavailableDates;

  const PreferenceProfile({
    required this.favoriteFoodTags,
    required this.dislikedFoodTags,
    required this.otherFavoriteFood,
    required this.otherDislikedFood,
    required this.favoritePlaceTags,
    required this.dislikedPlaceTags,
    required this.otherFavoritePlace,
    required this.otherDislikedPlace,
    required this.planStyles,
    required this.preferredWeekdays,
    required this.preferredTimes,
    this.unavailableDates = const [],
  });

  factory PreferenceProfile.empty() {
    return PreferenceProfile(
      favoriteFoodTags: [],
      dislikedFoodTags: [],
      otherFavoriteFood: '',
      otherDislikedFood: '',
      favoritePlaceTags: [],
      dislikedPlaceTags: [],
      otherFavoritePlace: '',
      otherDislikedPlace: '',
      planStyles: [],
      preferredWeekdays: [],
      preferredTimes: [],
      unavailableDates: [],
    );
  }

  factory PreferenceProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return PreferenceProfile.empty();
    }

    return PreferenceProfile(
      favoriteFoodTags: _readStringList(json['favoriteFoodTags']),
      dislikedFoodTags: _readStringList(json['dislikedFoodTags']),
      otherFavoriteFood: _readString(json['otherFavoriteFood']),
      otherDislikedFood: _readString(json['otherDislikedFood']),
      favoritePlaceTags: _readStringList(json['favoritePlaceTags']),
      dislikedPlaceTags: _readStringList(json['dislikedPlaceTags']),
      otherFavoritePlace: _readString(json['otherFavoritePlace']),
      otherDislikedPlace: _readString(json['otherDislikedPlace']),
      planStyles: _readStringList(json['planStyles']),
      preferredWeekdays: _readFirstStringList([
        json['preferredWeekdays'],
        json['preferredDays'],
      ]),
      preferredTimes: _readStringList(json['preferredTimes']),
      unavailableDates: _readStringList(json['unavailableDates']),
    );
  }

  PreferenceProfile copyWith({
    List<String>? favoriteFoodTags,
    List<String>? dislikedFoodTags,
    String? otherFavoriteFood,
    String? otherDislikedFood,
    List<String>? favoritePlaceTags,
    List<String>? dislikedPlaceTags,
    String? otherFavoritePlace,
    String? otherDislikedPlace,
    List<String>? planStyles,
    List<String>? preferredWeekdays,
    List<String>? preferredTimes,
    List<String>? unavailableDates,
  }) {
    return PreferenceProfile(
      favoriteFoodTags: favoriteFoodTags ?? this.favoriteFoodTags,
      dislikedFoodTags: dislikedFoodTags ?? this.dislikedFoodTags,
      otherFavoriteFood: otherFavoriteFood ?? this.otherFavoriteFood,
      otherDislikedFood: otherDislikedFood ?? this.otherDislikedFood,
      favoritePlaceTags: favoritePlaceTags ?? this.favoritePlaceTags,
      dislikedPlaceTags: dislikedPlaceTags ?? this.dislikedPlaceTags,
      otherFavoritePlace: otherFavoritePlace ?? this.otherFavoritePlace,
      otherDislikedPlace: otherDislikedPlace ?? this.otherDislikedPlace,
      planStyles: planStyles ?? this.planStyles,
      preferredWeekdays: preferredWeekdays ?? this.preferredWeekdays,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      unavailableDates: unavailableDates ?? this.unavailableDates,
    );
  }
}

List<String> _readStringList(Object? value) {
  if (value is Iterable) {
    return value
        .whereType<Object>()
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

List<String> _readFirstStringList(List<Object?> values) {
  for (final value in values) {
    final parsed = _readStringList(value);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return const [];
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}
