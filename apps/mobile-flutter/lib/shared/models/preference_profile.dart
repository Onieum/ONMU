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
    );
  }
}
