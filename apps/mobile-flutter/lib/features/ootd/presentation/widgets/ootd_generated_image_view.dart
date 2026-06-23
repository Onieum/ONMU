import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/pixel_character.dart';

String generatedOotdImageUrl(OotdRecord record) {
  return record.brands['generatedImageUrl']?.trim() ?? '';
}

bool isOotdGenerationPending(OotdRecord record) {
  final status = (record.brands['aiStatus'] ?? '').trim().toUpperCase();
  return status == 'PENDING' || status == 'PROCESSING' || status == 'QUEUED';
}

class OotdGeneratedImageView extends StatelessWidget {
  final OotdRecord record;
  final double characterSize;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OotdGeneratedImageView({
    super.key,
    required this.record,
    required this.characterSize,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = generatedOotdImageUrl(record);
    final content = _buildContent(imageUrl);
    final radius = borderRadius;
    if (radius == null) return content;
    return ClipRRect(borderRadius: radius, child: content);
  }

  Widget _buildContent(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _ImageUnavailable(width: width, height: height),
      );
    }

    if (isOotdGenerationPending(record)) {
      return OotdGenerationLoadingView(width: width, height: height);
    }

    return PixelCharacterWidget(
      character: record.character,
      size: characterSize,
    );
  }
}

class OotdGenerationLoadingView extends StatelessWidget {
  final double? width;
  final double? height;

  const OotdGenerationLoadingView({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgPaper.withOpacity(0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI OOTD 생성 중이에요',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '완성되면 자동으로 이미지가 표시돼요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSub,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  final double? width;
  final double? height;

  const _ImageUnavailable({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgPurpleSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSub,
        ),
      ),
    );
  }
}
