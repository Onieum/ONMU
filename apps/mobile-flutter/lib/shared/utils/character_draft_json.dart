import '../../core/api/onmu_api_client.dart';
import '../models/character_model.dart';

CharacterDraft? characterDraftFromJson(
  Object? value, {
  required String nickname,
}) {
  final json = OnmuJson.asMap(value);
  if (json.isEmpty) {
    return null;
  }
  return CharacterDraft.fromApiJson(json, nickname: nickname);
}
