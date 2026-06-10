import '../domain/my_profile.dart';

List<FriendProfile> createInitialFriends() {
  return const [
    FriendProfile(
      name: '지연',
      preferenceSummary: '성수동 카페 투어 중',
      isFriend: true,
      memo: '@jiyoun',
    ),
    FriendProfile(
      name: '민수',
      preferenceSummary: '전시회, 음악 좋아해요',
      isFriend: true,
      memo: '@minsu',
    ),
    FriendProfile(
      name: '하린',
      preferenceSummary: '맛집 탐방러',
      isFriend: true,
      memo: '@harin',
    ),
    FriendProfile(
      name: '현우',
      preferenceSummary: '산책과 사진 찍기',
      isFriend: true,
      memo: '@hyunwoo',
    ),
    FriendProfile(
      name: '소연',
      preferenceSummary: '감성 장소 찾는 중',
      isFriend: true,
      memo: '@soyeon',
    ),
    FriendProfile(
      name: '태오',
      preferenceSummary: '여행을 좋아해요',
      isFriend: true,
      memo: '@taeo',
    ),
    FriendProfile(
      name: '유나',
      preferenceSummary: '주말 브런치 메이트',
      isFriend: false,
      memo: '@yuna',
    ),
  ];
}
