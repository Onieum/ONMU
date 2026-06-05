import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_plan_style_page.dart';

class PreferencePlacePage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferencePlacePage({super.key, required this.profile});

  @override
  State<PreferencePlacePage> createState() => _PreferencePlacePageState();
}

class _PreferencePlacePageState extends State<PreferencePlacePage> {
  static const _favoriteOptions = [
    '조용한 대화 공간',
    '감성 있는 사진 맛집',
    '가성비 좋은 곳',
    '주차가 편한 곳',
    '넓고 쾌적한 공간',
    '상관 없어요',
  ];
  static const _dislikeOptions = [
    '이동 시간이 긴 곳',
    '소음이 큰 곳',
    '사람이 너무 많은 곳',
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
      stepCount: 5,
      title: '장소/분위기 취향',
      buttonLabel: '다음',
      onNext: _favorites.isEmpty && _dislikes.isEmpty
          ? null
          : () => pushOnmuPage(
              context,
              PreferencePlanStylePage(
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
          const SizedBox(height: 24),
          PreferenceTextField(
            label: '기타 입력',
            controller: _favoriteOtherController,
          ),
          const SizedBox(height: 32),
          PreferenceOptionSection(
            title: '피하고 싶은 태그',
            caption: '약속 장소로 피하고 싶은 조건을 골라주세요.',
            options: _dislikeOptions,
            selected: _dislikes,
            isDislike: true,
            onTap: (value) => _toggle(_dislikes, value),
          ),
          const SizedBox(height: 24),
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
