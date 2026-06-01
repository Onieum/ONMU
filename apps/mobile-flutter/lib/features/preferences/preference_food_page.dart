import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_place_page.dart';

class PreferenceFoodPage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferenceFoodPage({super.key, required this.profile});

  @override
  State<PreferenceFoodPage> createState() => _PreferenceFoodPageState();
}

class _PreferenceFoodPageState extends State<PreferenceFoodPage> {
  static const _favoriteOptions = [
    '한식 🍚',
    '일식 🍣',
    '양식 🍝',
    '중식 🥟',
    '매운 음식 🌶️',
    '디저트/카페 🍰',
    '고기/구이류 🥩',
    '비건/건강식 🥗',
    '상관 없어요',
  ];
  static const _dislikeOptions = [
    '맵찔이 (매운 거 절대 불가) 🥵',
    '해산물 싫어요 🙅‍♂️',
    '고수/향신료 빼주세요 🌿',
    '오이 싫어요 🥒',
    '주차 공간 없는 곳 🚗',
    '상관 없어요',
  ];

  late final Set<String> _favorites = widget.profile.favoriteFoodTags.toSet();
  late final Set<String> _dislikes = widget.profile.dislikedFoodTags.toSet();
  late final TextEditingController _favoriteOtherController =
      TextEditingController(text: widget.profile.otherFavoriteFood);
  late final TextEditingController _dislikeOtherController =
      TextEditingController(text: widget.profile.otherDislikedFood);

  @override
  void dispose() {
    _favoriteOtherController.dispose();
    _dislikeOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 2,
      stepCount: 6,
      title: '음식/메뉴 취향',
      buttonLabel: '다음',
      onNext: _favorites.isEmpty && _dislikes.isEmpty
          ? null
          : () => pushOnmuPage(
              context,
              PreferencePlacePage(
                profile: widget.profile.copyWith(
                  favoriteFoodTags: _favorites.toList(),
                  dislikedFoodTags: _dislikes.toList(),
                  otherFavoriteFood: _favoriteOtherController.text,
                  otherDislikedFood: _dislikeOtherController.text,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreferenceOptionSection(
            title: '선호 태그',
            caption: '좋아하는 메뉴를 골라주세요.',
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
            caption: '이건 꼭 빼줬으면 하는 메뉴를 골라주세요.',
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
