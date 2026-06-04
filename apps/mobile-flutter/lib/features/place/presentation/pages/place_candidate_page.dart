import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class PlaceCandidatePage extends StatefulWidget {
  const PlaceCandidatePage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
    this.showVoteResult = false,
  });

  final String onmoimId;
  final String meetupId;
  final bool showVoteResult;

  @override
  State<PlaceCandidatePage> createState() => _PlaceCandidatePageState();
}

class _PlaceCandidatePageState extends State<PlaceCandidatePage> {
  var _selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 후보 리스트',
      showBackButton: true,
      onBack: () => context.pop(),
      action: TextButton(
        onPressed: () => _goConfirmed(context),
        child: const Text('완료'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '후보 추가',
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        shape: const CircleBorder(),
        onPressed: () => context.go(
          RoutePaths.onmoimMeetupPlaceMap(widget.onmoimId, widget.meetupId),
        ),
        child: const Icon(Icons.add),
      ),
      bottom: OnmuCard(
        backgroundColor: AppColors.bgPaper,
        borderColor: AppColors.lineWarm,
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.accentOrange),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '일정 만들 때 이 후보 리스트에서 먼저 선택해요',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      children: [
        _HeaderRow(showVoteResult: widget.showVoteResult),
        const SizedBox(height: AppSpacing.md),
        const _CategoryChips(),
        const SizedBox(height: AppSpacing.md),
        _DateTabs(
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() => _selectedDateIndex = index),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < demoPlaceCandidates.length; index += 1) ...[
          _CandidateListCard(
            order: index + 1,
            candidate: demoPlaceCandidates[index],
            selected: index == 0,
            onTap: () => _goConfirmed(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: 72),
      ],
    );
  }

  void _goConfirmed(BuildContext context) {
    context.go(
      '${RoutePaths.onmoimMeetupDetail(widget.onmoimId, widget.meetupId)}?place=confirmed',
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showVoteResult});

  final bool showVoteResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            OnmuChip(label: '제주도 여행'),
            OnmuChip(label: '6.7 - 6.9'),
            OnmuChip(label: '제주도 일대'),
          ],
        ),
        if (showVoteResult) ...[
          const SizedBox(height: AppSpacing.sm),
          OnmuCard(
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.linePink,
            child: Text(
              '온모임 투표 결과를 후보 리스트에 이어서 보여줘요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('참여자 4명', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            PixelAvatar(label: '지우', size: 36),
            SizedBox(width: AppSpacing.sm),
            PixelAvatar(label: '민수', size: 36),
            SizedBox(width: AppSpacing.sm),
            PixelAvatar(label: '하린', size: 36),
            SizedBox(width: AppSpacing.sm),
            PixelAvatar(label: '현우', size: 36),
          ],
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    const categories = ['전체', '카페', '식사', '관광', '숙소'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index += 1) ...[
            OnmuChip(label: categories[index], selected: index == 1),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _DateTabs extends StatelessWidget {
  const _DateTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['6/7 토', '6/8 일', '6/9 월'];

    return Row(
      children: [
        for (var index = 0; index < tabs.length; index += 1)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CandidateListCard extends StatelessWidget {
  const _CandidateListCard({
    required this.order,
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final int order;
  final PlaceCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: selected
          ? AppColors.primaryPinkSoft
          : AppColors.bgDefault,
      borderColor: selected ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: SizedBox.square(
              dimension: 28,
              child: Center(
                child: Text(
                  '$order',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgGrid,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const SizedBox.square(
              dimension: 58,
              child: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.textSub,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: '후보 더보기',
                      onPressed: onTap,
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                Text(
                  '${candidate.category} · ${candidate.tags.take(2).join(' · ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  candidate.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.favorite_border,
                      color: selected
                          ? AppColors.accentRed
                          : AppColors.primaryPink,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      selected ? '인서 지정' : '${order + 1}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Spacer(),
                    TextButton(onPressed: onTap, child: const Text('일정에 넣기')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
