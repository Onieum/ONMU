import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/onmu_media_url.dart';
import '../../core/theme/app_colors.dart';
import '../../features/character/repository/character_repository.dart';
import '../models/character_model.dart';
import '../providers/state_providers.dart';
import 'pixel_character.dart';

class PixelAvatar extends ConsumerWidget {
  const PixelAvatar({
    required this.label,
    this.size = 48,
    this.profileImageUrl,
    this.character,
    this.fallbackToViewerCharacter = false,
    this.bodyColor = AppColors.primaryPurple,
    this.hairColor = AppColors.textMain,
    super.key,
  });

  final String label;
  final double size;
  final String? profileImageUrl;
  final CharacterDraft? character;
  final bool fallbackToViewerCharacter;
  final Color bodyColor;
  final Color hairColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmedLabel = label.trim();
    final imageUrl = resolveOnmuMediaUrl(profileImageUrl);
    final fallbackCharacter =
        character ??
        (fallbackToViewerCharacter
            ? ref.watch(userCharacterProvider) ??
                  ref.watch(characterProfileProvider).value
            : null);

    return Semantics(
      label: trimmedLabel.isEmpty ? '프로필 이미지' : '$trimmedLabel 프로필 이미지',
      image: true,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.primaryPinkSoft.withOpacity(0.32),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.linePink.withOpacity(0.55)),
        ),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _PixelAvatarFallback(
                      size: size,
                      iconColor: bodyColor,
                      character: fallbackCharacter,
                    ),
              )
            : _PixelAvatarFallback(
                size: size,
                iconColor: bodyColor,
                character: fallbackCharacter,
              ),
      ),
    );
  }
}

class _PixelAvatarFallback extends StatelessWidget {
  const _PixelAvatarFallback({
    required this.size,
    required this.iconColor,
    this.character,
  });

  final double size;
  final Color iconColor;
  final CharacterDraft? character;

  @override
  Widget build(BuildContext context) {
    final fallbackCharacter = character;
    if (fallbackCharacter != null) {
      return OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: size * 1.45,
        maxHeight: size * 1.65,
        child: Transform.translate(
          offset: Offset(0, size * 0.08),
          child: PixelCharacterWidget(
            character: fallbackCharacter,
            size: size * 1.1,
            showShadow: false,
          ),
        ),
      );
    }

    return Icon(
      Icons.person_rounded,
      size: size * 0.56,
      color: iconColor.withOpacity(0.72),
    );
  }
}
