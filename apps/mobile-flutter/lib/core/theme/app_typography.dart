import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppFontFamilies {
  const AppFontFamilies._();

  static const body = 'Mona12TextKR';
  static const pixel = 'Mona12';
  static const pixelCompact = 'Mona10x12';
  static const emoji = 'Mona12Emoji';
  static const colorEmoji = 'Mona12ColorEmoji';

  static const fallback = <String>[
    'Mona12TextKR',
    'Mona12TextJP',
    'Mona12TextSC',
    'Mona12TextTC',
    'Mona12TextHK',
    'Mona12Emoji',
    'Mona12ColorEmoji',
  ];
}

class AppTextStyles {
  const AppTextStyles._();

  static const displayLarge = TextStyle(
    fontFamily: AppFontFamilies.pixel,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.15,
  );

  static const displayMedium = TextStyle(
    fontFamily: AppFontFamilies.pixel,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.2,
  );

  static const displaySmall = TextStyle(
    fontFamily: AppFontFamilies.pixel,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.2,
  );

  static const headlineLarge = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    height: 1.25,
  );

  static const headlineMedium = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    height: 1.3,
  );

  static const headlineSmall = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    height: 1.3,
  );

  static const titleLarge = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.35,
  );

  static const titleMedium = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.35,
  );

  static const titleSmall = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.35,
  );

  static const bodyLarge = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
    height: 1.45,
  );

  static const bodyMedium = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSub,
    height: 1.45,
  );

  static const bodySmall = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSub,
    height: 1.4,
  );

  static const labelLarge = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.3,
  );

  static const labelMedium = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const labelSmall = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.25,
  );

  static const sticker = TextStyle(
    fontFamily: AppFontFamilies.pixelCompact,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.2,
  );

  static const tiny = TextStyle(
    fontFamily: AppFontFamilies.pixelCompact,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.2,
  );

  static const micro = TextStyle(
    fontFamily: AppFontFamilies.pixelCompact,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 8,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.2,
  );

  static const emojiLarge = TextStyle(
    fontFamily: AppFontFamilies.emoji,
    fontFamilyFallback: AppFontFamilies.fallback,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1,
  );
}

class OnmuTypography extends ThemeExtension<OnmuTypography> {
  const OnmuTypography({
    required this.sticker,
    required this.tiny,
    required this.micro,
    required this.pixelTitle,
    required this.emojiLarge,
  });

  final TextStyle sticker;
  final TextStyle tiny;
  final TextStyle micro;
  final TextStyle pixelTitle;
  final TextStyle emojiLarge;

  static const light = OnmuTypography(
    sticker: AppTextStyles.sticker,
    tiny: AppTextStyles.tiny,
    micro: AppTextStyles.micro,
    pixelTitle: AppTextStyles.displayMedium,
    emojiLarge: AppTextStyles.emojiLarge,
  );

  @override
  OnmuTypography copyWith({
    TextStyle? sticker,
    TextStyle? tiny,
    TextStyle? micro,
    TextStyle? pixelTitle,
    TextStyle? emojiLarge,
  }) {
    return OnmuTypography(
      sticker: sticker ?? this.sticker,
      tiny: tiny ?? this.tiny,
      micro: micro ?? this.micro,
      pixelTitle: pixelTitle ?? this.pixelTitle,
      emojiLarge: emojiLarge ?? this.emojiLarge,
    );
  }

  @override
  OnmuTypography lerp(ThemeExtension<OnmuTypography>? other, double t) {
    if (other is! OnmuTypography) {
      return this;
    }
    return OnmuTypography(
      sticker: TextStyle.lerp(sticker, other.sticker, t)!,
      tiny: TextStyle.lerp(tiny, other.tiny, t)!,
      micro: TextStyle.lerp(micro, other.micro, t)!,
      pixelTitle: TextStyle.lerp(pixelTitle, other.pixelTitle, t)!,
      emojiLarge: TextStyle.lerp(emojiLarge, other.emojiLarge, t)!,
    );
  }
}

extension OnmuTypographyX on BuildContext {
  OnmuTypography get onmuTypography =>
      Theme.of(this).extension<OnmuTypography>() ?? OnmuTypography.light;
}
