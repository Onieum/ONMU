enum ProfileVisibility {
  private('비공개'),
  friends('친구 공개'),
  public('모두 공개');

  const ProfileVisibility(this.label);

  final String label;
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
  });

  final String realName;
  final ProfileVisibility visibility;
  final List<String> favoriteKeywords;
  final List<String> dislikedKeywords;
  final List<String> preferredTimes;
  final List<String> availableDays;
  final List<String> unavailableDates;
  final List<ProfilePlace> favoritePlaces;
  final List<ProfilePlace> wantToGoPlaces;
  final List<ProfilePlace> dislikedPlaces;

  MyProfile copyWith({
    String? realName,
    ProfileVisibility? visibility,
    List<String>? favoriteKeywords,
    List<String>? dislikedKeywords,
    List<String>? preferredTimes,
    List<String>? availableDays,
    List<String>? unavailableDates,
  }) {
    return MyProfile(
      realName: realName ?? this.realName,
      visibility: visibility ?? this.visibility,
      favoriteKeywords: favoriteKeywords ?? this.favoriteKeywords,
      dislikedKeywords: dislikedKeywords ?? this.dislikedKeywords,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      availableDays: availableDays ?? this.availableDays,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      favoritePlaces: favoritePlaces,
      wantToGoPlaces: wantToGoPlaces,
      dislikedPlaces: dislikedPlaces,
    );
  }
}

class FriendProfile {
  const FriendProfile({
    required this.name,
    required this.preferenceSummary,
    required this.isFriend,
    this.memo = '',
  });

  final String name;
  final String preferenceSummary;
  final bool isFriend;
  final String memo;

  FriendProfile copyWith({bool? isFriend, String? memo}) {
    return FriendProfile(
      name: name,
      preferenceSummary: preferenceSummary,
      isFriend: isFriend ?? this.isFriend,
      memo: memo ?? this.memo,
    );
  }
}
