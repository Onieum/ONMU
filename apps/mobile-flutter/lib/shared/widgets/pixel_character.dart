import 'package:flutter/material.dart';
import '../models/character_model.dart';

class PixelCharacterWidget extends StatelessWidget {
  final CharacterDraft character;
  final double size;

  const PixelCharacterWidget({
    super.key,
    required this.character,
    this.size = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    final String genderPath = character.gender == 'female' ? 'female' : 'male';

    // 1. 피부/몸 경로 가공
    final String bodyPrefix = character.gender == 'female'
        ? 'girl_skin_base_0'
        : 'boy_skin_base_0';
    final String bodyPath =
        'assets/images/character/$genderPath/body/$bodyPrefix${character.skinToneIndex + 1}.PNG';

    // 2. 눈 경로 가공
    final String eyePrefix = character.gender == 'female'
        ? 'girl_eye_0'
        : 'boy_eye_0';
    String eyePath;
    if (character.gender == 'female' && character.eyeShapeIndex == 2) {
      // 여자 눈 3번(인덱스 2)은 색상이 없고 단일 파일(girl_eye_03.PNG)만 존재함
      eyePath = 'assets/images/character/female/eyes/girl_eye_03.PNG';
    } else {
      final String colorEng =
          CharacterDraft.eyeColorEnglishNames[character.eyeColorIndex];
      eyePath =
          'assets/images/character/$genderPath/eyes/$eyePrefix${character.eyeShapeIndex + 1}_$colorEng.PNG';
    }

    // 3. 머리 경로 가공
    final String hairPrefix = character.gender == 'female'
        ? 'hair_girl_0'
        : 'hair_boy_0';
    final String hairSilPath =
        'assets/images/character/$genderPath/hair/$hairPrefix${character.hairStyleIndex + 1}_silhouette.PNG';
    final String hairOutPath =
        'assets/images/character/$genderPath/hair/$hairPrefix${character.hairStyleIndex + 1}.PNG';

    // 헤어 염색용 색상 추출
    final Color hairColor = Color(
      int.parse(
        CharacterDraft.hairColors[character.hairColorIndex].replaceAll(
          '#',
          '0xFF',
        ),
      ),
    );

    // 4. 의상 경로 가공
    final String clothesPrefix = character.gender == 'female' ? 'girl' : 'boy';
    final String clothesPath = character.topStyleIndex == -1
        ? 'assets/images/character/$genderPath/clothes/${clothesPrefix}_base_clothes.PNG'
        : 'assets/images/character/$genderPath/clothes/${clothesPrefix}_clothes_0${character.topStyleIndex + 1}.PNG';

    const BoxFit fitMode = BoxFit.contain;

    return Container(
      width: size,
      height: size * 1.3,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 발 밑 그림자
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: size * 0.65,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size * 0.65, size * 0.12),
                ),
              ),
            ),
          ),

          // 몸/피부 레이어
          Image.asset(
            bodyPath,
            width: size,
            height: size * 1.3,
            fit: fitMode,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),

          // 의상 레이어
          Image.asset(
            clothesPath,
            width: size,
            height: size * 1.3,
            fit: fitMode,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),

          // 눈 레이어
          Image.asset(
            eyePath,
            width: size,
            height: size * 1.3,
            fit: fitMode,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),

          // 헤어 실루엣 (염색 레이어)
          Image.asset(
            hairSilPath,
            width: size,
            height: size * 1.3,
            fit: fitMode,
            color: hairColor,
            colorBlendMode: BlendMode.modulate, // 흰색 실루엣 위에 헤어 색상을 자연스럽게 곱하기 연산
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),

          // 헤어 아웃라인 (디테일 레이어)
          Image.asset(
            hairOutPath,
            width: size,
            height: size * 1.3,
            fit: fitMode,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
