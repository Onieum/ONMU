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
  const PlaceDetailPage({
    required this.onmoimId,
    required this.meetupId,
    required this.placeId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;
  final String placeId;

  @override
  Widget build(BuildContext context) {
    final candidate = findPlaceCandidate(placeId);

    return OnmuScaffold(
      title: '장소 상세',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: Row(
        children: [
          Expanded(
            child: OnmuSecondaryButton(
              label: '후보에 추가하기',
              icon: Icons.favorite_border,
              onPressed: () => context.go(
                RoutePaths.planPlaceCandidates(onmoimId, meetupId),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuPrimaryButton(
              label: '일정에 바로 등록하기',
              icon: Icons.event_available_outlined,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: () =>
                  context.go(RoutePaths.planItinerary(onmoimId, meetupId)),
            ),
          ),
        ],
      ),
      children: [
        _DetailMap(candidate: candidate),
        const SizedBox(height: AppSpacing.md),
        _DetailSheet(candidate: candidate),
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
              OnmuChip(label: '인스타'),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          _InfoBlock(
            title: candidate.openingLabel,
            body: '방문 전 영업시간을 한 번 더 확인해 주세요.',
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
          Text('참여자 선호', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          MemberPreferenceList(candidate: candidate),
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
