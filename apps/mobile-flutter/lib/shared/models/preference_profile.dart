class PreferenceProfile {
  final List<String> favoriteFoodTags;
  final List<String> dislikedFoodTags;
  final String otherFavoriteFood;
  final String otherDislikedFood;
  final List<String> favoritePlaceTags;
  final List<String> dislikedPlaceTags;
  final String otherFavoritePlace;
  final String otherDislikedPlace;
  final List<String> meetupStyles;
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
    required this.meetupStyles,
    required this.preferredWeekdays,
    required this.preferredTimes,
  });

  factory PreferenceProfile.mock() {
    return const PreferenceProfile(
      favoriteFoodTags: ['한식', '디저트 카페'],
      dislikedFoodTags: ['너무 매운 음식'],
      otherFavoriteFood: '',
      otherDislikedFood: '',
      favoritePlaceTags: ['조용한 대화 공간'],
      dislikedPlaceTags: ['이동 시간이 긴 곳'],
      otherFavoritePlace: '',
      otherDislikedPlace: '',
      meetupStyles: ['미리 일정을 정하는 편'],
      preferredWeekdays: ['토요일'],
      preferredTimes: ['저녁'],
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
    List<String>? meetupStyles,
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
      meetupStyles: meetupStyles ?? this.meetupStyles,
      preferredWeekdays: preferredWeekdays ?? this.preferredWeekdays,
      preferredTimes: preferredTimes ?? this.preferredTimes,
    );
  }
}
