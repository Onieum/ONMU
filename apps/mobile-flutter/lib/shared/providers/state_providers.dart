import 'package:flutter_riverpod/legacy.dart';

import '../models/character_model.dart';
import '../models/preference_profile.dart';

// 스플래시 완료 여부 상태
final showSplashProvider = StateProvider<bool>((ref) => true);

// 유저 생성 캐릭터 상태
final userCharacterProvider = StateProvider<CharacterDraft?>((ref) => null);

// 유저 취향 설정 상태
final preferenceProfileProvider = StateProvider<PreferenceProfile?>(
  (ref) => null,
);

// 온보딩에서 캐릭터 설정을 건너뛰었는지 여부
final skippedCharacterProvider = StateProvider<bool>((ref) => false);

// 온보딩에서 취향 설정을 건너뛰었는지 여부
final skippedPreferenceProvider = StateProvider<bool>((ref) => false);

// 생성된 다이어리 기록들 상태
