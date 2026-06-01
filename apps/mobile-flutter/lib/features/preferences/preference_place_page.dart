import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_meetup_style_page.dart';

class PreferencePlacePage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferencePlacePage({super.key, required this.profile});

  @override
  State<PreferencePlacePage> createState() => _PreferencePlacePageState();
}

class _PreferencePlacePageState extends State<PreferencePlacePage> {
  static const _favoriteOptions = [
    '조용하게 대화하기 좋은 곳 🤫',
    '인스타 감성 (사진 맛집) 📸',
    '가성비 좋은 곳 💸',
    '주차 공간 넉넉한 곳 🚗',
    '공간이 넓고 쾌적한 곳 🛋️',
    '상관 없어요',
  ];
  static const _dislikeOptions = [
    '웨이팅 1시간 넘어가는 곳 ⏳',
    '옆 테이블 말소리 들리는 시끄러운 곳 🗣️',
    '사람 너무 많은 북적이는 곳 👥',
    '상관 없어요',
  ];

  late final Set<String> _favorites = widget.profile.favoritePlaceTags.toSet();
  late final Set<String> _dislikes = widget.profile.dislikedPlaceTags.toSet();
  late final TextEditingController _favoriteOtherController =
      TextEditingController(text: widget.profile.otherFavoritePlace);
  late final TextEditingController _dislikeOtherController =
      TextEditingController(text: widget.profile.otherDislikedPlace);

  @override
  void dispose() {
    _favoriteOtherController.dispose();
    _dislikeOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 3,
      stepCount: 6,
      title: '장소/분위기 취향',
      buttonLabel: '다음',
      onNext: _favorites.isEmpty && _dislikes.isEmpty
          ? null
          : () => pushOnmuPage(
              context,
              PreferenceMeetupStylePage(
                profile: widget.profile.copyWith(
                  favoritePlaceTags: _favorites.toList(),
                  dislikedPlaceTags: _dislikes.toList(),
                  otherFavoritePlace: _favoriteOtherController.text,
                  otherDislikedPlace: _dislikeOtherController.text,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreferenceOptionSection(
            title: '선호 태그',
            caption: '어떤 분위기의 장소가 좋나요?',
            options: _favoriteOptions,
            selected: _favorites,
            onTap: (value) => _toggle(_favorites, value),
          ),
          const SizedBox(height: 22),
          PreferenceTextField(
            label: '기타 입력',
            controller: _favoriteOtherController,
          ),
          const SizedBox(height: 28),
          PreferenceOptionSection(
            title: '비선호 태그',
            caption: '이런 곳은 피하고 싶은 조건을 골라주세요.',
            options: _dislikeOptions,
            selected: _dislikes,
            isDislike: true,
            onTap: (value) => _toggle(_dislikes, value),
          ),
          const SizedBox(height: 22),
          PreferenceTextField(
            label: '기타 입력',
            controller: _dislikeOtherController,
          ),
        ],
      ),
    );
  }

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (!target.remove(value)) {
        target.add(value);
      }
    });
  }
}
