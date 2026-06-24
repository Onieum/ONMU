import 'package:flutter/material.dart';

import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/pixel_character.dart';

String generatedOotdImageUrl(OotdRecord record) {
  return record.brands['generatedImageUrl']?.trim() ?? '';
}

String generatedOotdAvatarImageUrl(OotdRecord record) {
  return record.brands['avatarImageUrl']?.trim() ?? '';
}

String generatedOotdDisplayImageUrl(
  OotdRecord record, {
  bool preferAvatarImage = false,
  bool avatarOnly = false,
}) {
  final avatarUrl = generatedOotdAvatarImageUrl(record);
  final compositeUrl = generatedOotdImageUrl(record);
  if (avatarOnly) {
    return avatarUrl;
  }
  if (preferAvatarImage && avatarUrl.isNotEmpty) {
    return avatarUrl;
  }
  if (compositeUrl.isNotEmpty) {
    return compositeUrl;
  }
  return avatarUrl;
}

String ootdGenerationStatus(OotdRecord record) {
  return (record.brands['aiStatus'] ?? '').trim().toUpperCase();
}

bool hasOotdGenerationStarted(OotdRecord record) {
  final status = ootdGenerationStatus(record);
  return status.isNotEmpty && status != 'SKIPPED';
}

bool isOotdGenerationPending(OotdRecord record) {
  final status = ootdGenerationStatus(record);
  return status == 'PENDING' || status == 'PROCESSING' || status == 'QUEUED';
}

bool isOotdGenerationFailed(OotdRecord record) {
  final status = ootdGenerationStatus(record);
  return status == 'FAILED' || status == 'ERROR';
}

class OotdCalendarPreview extends StatelessWidget {
  final OotdRecord record;
  final double size;

  const OotdCalendarPreview({super.key, required this.record, this.size = 58});

  @override
  Widget build(BuildContext context) {
    return OotdGeneratedImageView(
      record: record,
      width: size,
      height: size,
      characterSize: size,
      fit: BoxFit.contain,
      preferAvatarImage: true,
      avatarOnly: true,
      showFallbackCharacter: false,
      compactStatus: true,
    );
  }
}

class OotdGeneratedImageView extends StatelessWidget {
  final OotdRecord record;
  final double? width;
  final double? height;
  final double characterSize;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool preferAvatarImage;
  final bool avatarOnly;
  final bool showFallbackCharacter;
  final bool compactStatus;

  const OotdGeneratedImageView({
    super.key,
    required this.record,
    this.width,
    this.height,
    this.characterSize = 120,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.preferAvatarImage = false,
    this.avatarOnly = false,
    this.showFallbackCharacter = true,
    this.compactStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final imageUrl = generatedOotdDisplayImageUrl(
      record,
      preferAvatarImage: preferAvatarImage,
      avatarOnly: avatarOnly,
    );
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return OotdGenerationLoadingView(compact: compactStatus);
        },
        errorBuilder: (context, error, stackTrace) => _fallbackContent(context),
      );
    }

    if (isOotdGenerationPending(record) || hasOotdGenerationStarted(record)) {
      return isOotdGenerationFailed(record)
          ? _GenerationMessage(
              title: '이미지 생성 실패',
              body: '다시 생성하거나 잠시 후 확인해 주세요.',
              compact: compactStatus,
            )
          : OotdGenerationLoadingView(compact: compactStatus);
    }

    return _fallbackContent(context);
  }

  Widget _fallbackContent(BuildContext context) {
    if (!showFallbackCharacter) {
      return _GenerationMessage(
        title: '이미지 준비 중',
        body: '생성 이미지가 곧 표시됩니다.',
        compact: compactStatus,
      );
    }
    return PixelCharacterWidget(
      character: record.character,
      size: characterSize,
    );
  }
}

class OotdGenerationLoadingView extends StatelessWidget {
  final bool compact;

  const OotdGenerationLoadingView({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: compact
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'AI OOTD 생성 중',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3E2B25),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '완성되면 이미지가 자동으로 표시돼요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8D746C), fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GenerationMessage extends StatelessWidget {
  final String title;
  final String body;
  final bool compact;

  const _GenerationMessage({
    required this.title,
    required this.body,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 4 : 12),
          child: compact
              ? const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 18,
                  color: Color(0xFF8D746C),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF3E2B25),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8D746C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
