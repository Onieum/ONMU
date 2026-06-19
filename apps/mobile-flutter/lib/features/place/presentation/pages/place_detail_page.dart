import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/map/model/map_models.dart';
import '../../../../features/map/widgets/onmu_map_view.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/place_candidates_view_model.dart';
import '../widgets/place_candidate_card.dart';

class PlaceDetailPage extends ConsumerWidget {
  const PlaceDetailPage({
    required this.groupId,
    required this.planId,
    required this.placeId,
    super.key,
  });

  final String groupId;
  final String planId;
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      placeCandidateDetailViewModelProvider((
        groupId: groupId,
        planId: planId,
        candidateId: placeId,
      )),
    );

    return state.when(
      data: (candidate) => _PlaceDetailContent(
        groupId: groupId,
        planId: planId,
        candidate: candidate,
        onAddCandidate: () async {
          await ref
              .read(
                placeCandidatesViewModelProvider((
                  groupId: groupId,
                  planId: planId,
                )).notifier,
              )
              .addCandidate(candidate);
        },
        onRegisterCandidate: () async {
          await ref
              .read(
                placeCandidatesViewModelProvider((
                  groupId: groupId,
                  planId: planId,
                )).notifier,
              )
              .addCandidateToSchedule(candidate);
        },
      ),
      loading: () => const OnmuScaffold(
        title: '장소 상세',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '장소 상세',
        children: [
          Text(
            '장소 정보를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PlaceDetailContent extends StatelessWidget {
  const _PlaceDetailContent({
    required this.groupId,
    required this.planId,
    required this.candidate,
    required this.onAddCandidate,
    required this.onRegisterCandidate,
  });

  final String groupId;
  final String planId;
  final PlaceCandidate candidate;
  final Future<void> Function() onAddCandidate;
  final Future<void> Function() onRegisterCandidate;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 상세',
      showBackButton: true,
      onBack: () =>
          context.popOrGo(RoutePaths.planPlaceCandidates(groupId, planId)),
      bottom: Row(
        children: [
          Expanded(
            child: OnmuSecondaryButton(
              label: '후보에 추가하기',
              icon: Icons.favorite_border,
              onPressed: () async {
                await onAddCandidate();
                if (!context.mounted) {
                  return;
                }
                context.go(RoutePaths.planPlaceCandidates(groupId, planId));
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuPrimaryButton(
              label: '일정에 바로 등록하기',
              icon: Icons.event_available_outlined,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: () async {
                await onRegisterCandidate();
                if (!context.mounted) {
                  return;
                }
                context.go(RoutePaths.planItinerary(groupId, planId));
              },
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
        child: OnmuMapView(
          points: [
            OnmuMapPoint(
              id: candidate.id.toString(),
              label: candidate.name,
              coordinate: candidate.hasCoordinate
                  ? OnmuLatLng(
                      lat: candidate.latitude!,
                      lng: candidate.longitude!,
                    )
                  : const OnmuLatLng(lat: 37.5665, lng: 126.9780),
              order: 1,
            ),
          ],
          zoom: 13,
          fallbackLabel: '장소 지도 미리보기',
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
    final detailRows = _detailRows(candidate);

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            candidate.categoryDistanceLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (candidate.displayAddress.isNotEmpty)
            Text(
              candidate.displayAddress,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (detailRows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PlaceDetailFacts(rows: detailRows),
          ],
          if (candidate.openingLabel.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoBlock(
              title: candidate.openingLabel,
              body: '방문 전 영업시간을 한 번 더 확인해 주세요.',
              trailing: candidate.isOpen ? '영업중' : '확인 필요',
            ),
          ],
          if (candidate.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('분류 키워드', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final tag in candidate.tags.take(4))
                  OnmuChip(label: tag, selected: true),
              ],
            ),
          ],
          if (candidate.memberFits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('참여자 선호', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            MemberPreferenceList(candidate: candidate),
          ],
          if (candidate.sourceUrl.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ExternalPlaceLinkButton(sourceUrl: candidate.sourceUrl),
          ],
        ],
      ),
    );
  }

  List<_PlaceDetailFact> _detailRows(PlaceCandidate candidate) {
    return [
      if (candidate.roadAddress.trim().isNotEmpty &&
          candidate.roadAddress.trim() != candidate.displayAddress.trim())
        _PlaceDetailFact(label: '도로명', value: candidate.roadAddress.trim()),
      if (candidate.sourceLabel.trim().isNotEmpty)
        _PlaceDetailFact(label: '출처', value: candidate.sourceLabel.trim()),
      if (_providerLabel(candidate.provider).isNotEmpty)
        _PlaceDetailFact(
          label: '제공',
          value: _providerLabel(candidate.provider),
        ),
    ];
  }

  String _providerLabel(String provider) {
    return switch (provider.trim().toLowerCase()) {
      'naver' => 'Naver',
      'kakao' => 'Kakao',
      'onmu_catalog' => 'ONMU catalog',
      final value => value,
    };
  }
}

class _PlaceDetailFact {
  const _PlaceDetailFact({required this.label, required this.value});

  final String label;
  final String value;
}

class _PlaceDetailFacts extends StatelessWidget {
  const _PlaceDetailFacts({required this.rows});

  final List<_PlaceDetailFact> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  row.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
                ),
              ),
              Expanded(
                child: Text(
                  row.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    height: 1.16,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          if (row != rows.last) const SizedBox(height: AppSpacing.xxs),
        ],
      ],
    );
  }
}

class _ExternalPlaceLinkButton extends StatelessWidget {
  const _ExternalPlaceLinkButton({required this.sourceUrl});

  final String sourceUrl;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _launchSource(context),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('외부 상세 보기'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  Future<void> _launchSource(BuildContext context) async {
    final uri = Uri.tryParse(sourceUrl.trim());
    if (uri == null || !uri.hasScheme) {
      _showLaunchFailure(context);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showLaunchFailure(context);
    }
  }

  void _showLaunchFailure(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('외부 상세 페이지를 열 수 없어요.')));
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

class DetailMapPainter extends CustomPainter {
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
