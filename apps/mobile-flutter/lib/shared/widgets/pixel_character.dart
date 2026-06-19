import 'package:flutter/material.dart';
import '../models/character_model.dart';

class PixelCharacterWidget extends StatelessWidget {
  final CharacterDraft character;
  final double size;
  final bool showShadow;
  final bool showBody;
  final bool showClothes;
  final bool showEyes;
  final bool showHair;

  const PixelCharacterWidget({
    super.key,
    required this.character,
    this.size = 150.0,
    this.showShadow = true,
    this.showBody = true,
    this.showClothes = true,
    this.showEyes = true,
    this.showHair = true,
  });

  static List<String> assetPathsFor(CharacterDraft character) {
    final assets = _PixelCharacterAssets(character);
    return [
      assets.bodyPath,
      assets.clothesPath,
      assets.eyePath,
      assets.hairSilhouettePath,
      assets.hairOutlinePath,
      assets.mouthPath,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final assets = _PixelCharacterAssets(character);
    final hairColor = Color(
      int.parse(
        CharacterDraft.hairColors[character.hairColorIndex].replaceAll(
          '#',
          '0xFF',
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showShadow)
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
          if (showBody) _asset(assets.bodyPath),
          if (showClothes) _asset(assets.clothesPath),
          if (showEyes) _asset(assets.eyePath),
          if (showHair)
            _asset(
              assets.hairSilhouettePath,
              color: hairColor,
              colorBlendMode: BlendMode.srcIn,
            ),
          if (showHair) _asset(assets.hairOutlinePath),
          if (showEyes)
            character.gender == 'female'
                ? Transform.translate(
                    offset: Offset(-size * (16 / 1920), -size * (16 / 1920)),
                    child: _asset(assets.mouthPath),
                  )
                : _asset(assets.mouthPath),
        ],
      ),
    );
  }

  Widget _asset(String path, {Color? color, BlendMode? colorBlendMode}) {
    return Image.asset(
      path,
      width: size,
      height: size * 1.3,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (context, error, stackTrace) => const SizedBox(),
    );
  }
}

class _PixelCharacterAssets {
  _PixelCharacterAssets(this.character);

  final CharacterDraft character;

  String get genderPath => character.gender == 'female' ? 'female' : 'male';

  String get bodyPath {
    final bodyPrefix = character.gender == 'female'
        ? 'girl_skin_base_0'
        : 'boy_skin_base_0';
    final skinAssetIndex = character.skinToneIndex.clamp(0, 4).toInt() + 1;
    return 'assets/images/character/$genderPath/body/$bodyPrefix$skinAssetIndex.PNG';
  }

  String get eyePath {
    final eyePrefix = character.gender == 'female' ? 'girl_eye_0' : 'boy_eye_0';
    if (character.gender == 'female' && character.eyeShapeIndex == 2) {
      return 'assets/images/character/female/eyes/girl_eye_03.PNG';
    }

    final colorName =
        CharacterDraft.eyeColorEnglishNames[character.eyeColorIndex];
    return 'assets/images/character/$genderPath/eyes/$eyePrefix${character.eyeShapeIndex + 1}_$colorName.PNG';
  }

  String get mouthPath => 'assets/images/character/mouth.png';

  String get hairSilhouettePath {
    final hairPrefix = character.gender == 'female'
        ? 'hair_girl_0'
        : 'hair_boy_0';
    return 'assets/images/character/$genderPath/hair/$hairPrefix${character.hairStyleIndex + 1}_silhouette.PNG';
  }

  String get hairOutlinePath {
    final hairPrefix = character.gender == 'female'
        ? 'hair_girl_0'
        : 'hair_boy_0';
    return 'assets/images/character/$genderPath/hair/$hairPrefix${character.hairStyleIndex + 1}.PNG';
  }

  String get clothesPath {
    final clothesPrefix = character.gender == 'female' ? 'girl' : 'boy';
    return character.topStyleIndex == -1
        ? 'assets/images/character/$genderPath/clothes/${clothesPrefix}_base_clothes.PNG'
        : 'assets/images/character/$genderPath/clothes/${clothesPrefix}_clothes_0${character.topStyleIndex + 1}.PNG';
  }
}
