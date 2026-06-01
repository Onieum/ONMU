import 'package:flutter/material.dart';

/// 장소 후보 / route: /meetups/:meetupId/places  (약속 탭 nested route)
/// TODO(장소팀): 이 파일을 장소 후보 화면으로 교체한다.
/// 관련 route: /meetups/:meetupId/places, /meetups/:meetupId/places/search,
///             /meetups/:meetupId/places/map, /meetups/:meetupId/places/:placeId,
///             /meetups/:meetupId/place-compare, /meetups/:meetupId/places/risks
class PlaceCandidatePage extends StatelessWidget {
  const PlaceCandidatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
