import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/place_candidate_card.dart';

class PlaceDetailPage extends StatelessWidget {
  const PlaceDetailPage({required this.placeId, super.key});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final candidate = findPlaceCandidate(placeId);

    return OnmuScaffold(
      title: '장소 상세',
      subtitle: '지도 위 바텀시트처럼 후보 정보를 한 번에 확인합니다.',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '후보에 추가하기',
            icon: Icons.add,
            color: AppColors.primaryPurple,
            foregroundColor: AppColors.textInverse,
            onPressed: () => context.go(RoutePaths.placeCompare),
          ),
        ),
      ),
      children: [
        _DetailMap(candidate: candidate),
        const SizedBox(height: AppSpacing.md),
        _DetailSheet(candidate: candidate),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '목록',
                icon: Icons.arrow_back,
                onPressed: () => context.go(RoutePaths.placeCandidates),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuSecondaryButton(
                label: '리스크',
                icon: Icons.warning_amber,
                onPressed: () => context.go(RoutePaths.placeRisks),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailMap extends StatelessWidget {
  const _DetailMap({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.bgGrid,
      borderColor: AppColors.lineSoft,
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DetailMapPainter())),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_pin,
                    size: 42,
                    color: AppColors.primaryPurple,
                  ),
                  Text(
                    '핀: ${candidate.name}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('장소 상세', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              _ScorePill(score: candidate.score),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            candidate.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${candidate.category} · ${candidate.distanceLabel}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(candidate.address, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: const [
              OnmuChip(label: '전화'),
              OnmuChip(label: '지도앱'),
              OnmuChip(label: '인스타'),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          _InfoBlock(
            title: candidate.openingLabel,
            body: candidate.sourceLabel,
            trailing: candidate.isOpen ? '영업중' : '확인 필요',
          ),
          const Divider(height: AppSpacing.xl),
          Text('리뷰 키워드', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in candidate.tags)
                OnmuChip(label: tag, selected: true),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Text('참여자 적합도', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final fit in candidate.memberFits) PlaceMemberFitBar(fit: fit),
          const Divider(height: AppSpacing.xl),
          _RiskSummary(candidate: candidate),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
    required this.trailing,
  });

  final String title;
  final String body;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        OnmuChip(label: trailing, selected: true),
      ],
    );
  }
}

class _RiskSummary extends StatelessWidget {
  const _RiskSummary({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final isStable = candidate.riskTone == 'none';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStable ? '운영 리스크 없음' : '운영 리스크 확인 필요',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                candidate.risks.join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        OnmuChip(label: candidate.riskLabel, selected: true),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '${score.toInt()}점',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
        ),
      ),
    );
  }
}

class _DetailMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 1.5;

    for (var x = 0.0; x <= size.width; x += 58) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
