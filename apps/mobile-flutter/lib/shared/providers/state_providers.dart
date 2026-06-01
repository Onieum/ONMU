import 'package:flutter_riverpod/legacy.dart';
import '../models/character_model.dart';
import '../models/ootd_model.dart';

// 스플래시 완료 여부 상태
final showSplashProvider = StateProvider<bool>((ref) => true);

// 유저 생성 캐릭터 상태
final userCharacterProvider = StateProvider<CharacterDraft?>((ref) => null);

// 생성된 다이어리 기록들 상태
final customRecordsProvider = StateProvider<List<OotdRecord>>((ref) => []);
