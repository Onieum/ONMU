import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/place_candidate_card.dart';

class PlaceCandidatePage extends StatelessWidget {
  const PlaceCandidatePage({super.key, this.showVoteResult = false});

  final bool showVoteResult;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 후보',
      subtitle: '친구 취향과 이동 시간을 종이 메모처럼 모아봤어요.',
      children: [
        if (showVoteResult) ...[
          const _VoteResultCarryoverCard(),
          const SizedBox(height: AppSpacing.md),
        ],
        const _MeetupContextCard(),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '검색 필터',
                icon: Icons.tune,
                onPressed: () => context.go(RoutePaths.placeSearch),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuSecondaryButton(
                label: '지도 보기',
                icon: Icons.map_outlined,
                onPressed: () => context.go(RoutePaths.placeMap),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('추천 후보', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in demoPlaceCandidates) ...[
          PlaceCandidateCard(
            candidate: candidate,
            onDetailPressed: () {
              context.go('/meetups/demo/places/${candidate.id}');
            },
            onSelectPressed: () => context.go(RoutePaths.placeCompare),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuPrimaryButton(
          label: '리스크 먼저 확인',
          icon: Icons.warning_amber,
          color: AppColors.primaryPink,
          onPressed: () => context.go(RoutePaths.placeRisks),
        ),
      ],
    );
  }
}

class _MeetupContextCard extends StatelessWidget {
  const _MeetupContextCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnmuStickerLabel(label: '오늘의 약속 메모', icon: Icons.favorite),
          const SizedBox(height: AppSpacing.sm),
          Text('토요일 오후 성수 모임', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '4명 · 6월 6일 15:00 후보 · 조용한 대화와 디저트 선호',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(
            value: 0.76,
            minHeight: 8,
            backgroundColor: AppColors.primaryPinkSoft,
            color: AppColors.primaryPink,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('참여자 취향 반영률 76%', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _VoteResultCarryoverCard extends StatelessWidget {
  const _VoteResultCarryoverCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnmuTape(width: 76),
          const SizedBox(height: AppSpacing.xs),
          Text(
            demoPlaceVoteResult.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${demoPlaceVoteResult.selectedPlaceName}에 ${demoPlaceVoteResult.voters.length}명이 투표했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            demoPlaceVoteResult.note,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
