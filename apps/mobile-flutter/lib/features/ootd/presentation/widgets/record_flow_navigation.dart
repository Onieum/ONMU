import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/widgets/pixel_character.dart';

class RecordFlowExitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RecordFlowExitButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new,
        color: AppColors.textMain,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }
}

class RecordEntryIntro extends StatelessWidget {
  final CharacterDraft character;
  final String title;
  final String subtitle;
  final String bannerText;
  final IconData topLeftIcon;
  final Color topLeftColor;
  final IconData bottomRightIcon;
  final Color bottomRightColor;

  const RecordEntryIntro({
    super.key,
    required this.character,
    required this.title,
    required this.subtitle,
    required this.bannerText,
    required this.topLeftIcon,
    required this.topLeftColor,
    required this.bottomRightIcon,
    required this.bottomRightColor,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final characterSize = width < 360 ? 112.0 : 140.0;

    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSub,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        Stack(
          alignment: Alignment.center,
          children: [
            PixelCharacterWidget(character: character, size: characterSize),
            Positioned(
              top: 0,
              left: 10,
              child: Icon(topLeftIcon, color: topLeftColor, size: 20),
            ),
            Positioned(
              bottom: 20,
              right: 10,
              child: Icon(bottomRightIcon, color: bottomRightColor, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineSoft),
          ),
          alignment: Alignment.center,
          child: Text(
            bannerText,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class RecordFlowStepIndicator extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;

  const RecordFlowStepIndicator({
    super.key,
    required this.labels,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final safeActiveIndex = activeIndex.clamp(0, labels.length - 1).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = safeActiveIndex == index;
          final isDone = safeActiveIndex > index;

          return Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryPink
                        : isDone
                        ? AppColors.primaryPinkSoft
                        : AppColors.bgPaper,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isDone
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.sticker.copyWith(
                      color: isActive
                          ? AppColors.textInverse
                          : AppColors.textSub,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sticker.copyWith(
                    color: isActive ? AppColors.textMain : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class RecordFlowBottomBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const RecordFlowBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.onBackPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.bgWarm,
      child: Row(
        children: [
          if (showBackButton) ...[
            Expanded(
          child: ElevatedButton(
                onPressed: onBackPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgDefault,
                  foregroundColor: AppColors.textMain,
                  side: const BorderSide(color: AppColors.lineSoft),
                ),
                child: const Text('이전'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onPrimaryPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: AppColors.textInverse,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(primaryLabel, maxLines: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
