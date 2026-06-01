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
  final List<String> preferredTimes;
  final List<String> unavailableWeekdays;

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
    required this.preferredTimes,
    required this.unavailableWeekdays,
  });

  factory PreferenceProfile.mock() {
    return const PreferenceProfile(
      favoriteFoodTags: ['한식 🍚', '디저트/카페 🍰'],
      dislikedFoodTags: ['맵찔이 (매운 거 절대 불가) 🥵'],
      otherFavoriteFood: '',
      otherDislikedFood: '',
      favoritePlaceTags: ['조용하게 대화하기 좋은 곳 🤫'],
      dislikedPlaceTags: ['웨이팅 1시간 넘어가는 곳 ⏳'],
      otherFavoritePlace: '',
      otherDislikedPlace: '',
      meetupStyles: ['미리 일정이 확정되면 좋겠어요.'],
      preferredTimes: ['저녁'],
      unavailableWeekdays: ['일요일'],
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
    List<String>? preferredTimes,
    List<String>? unavailableWeekdays,
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
      preferredTimes: preferredTimes ?? this.preferredTimes,
      unavailableWeekdays: unavailableWeekdays ?? this.unavailableWeekdays,
    );
  }
}
