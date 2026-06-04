import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class OnMoimMeetupListPage extends StatelessWidget {
  const OnMoimMeetupListPage({required this.onmoimId, super.key});

  final String onmoimId;

  @override
  Widget build(BuildContext context) {
    final upcoming = demoOnMoimMeetups
        .where((meetup) => !meetup.isPast)
        .toList();
    final past = demoOnMoimMeetups.where((meetup) => meetup.isPast).toList();

    return OnmuScaffold(
      title: '약속',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.onmoimDetail(onmoimId)),
      action: IconButton(
        tooltip: '약속 만들기',
        onPressed: () => context.go(RoutePaths.onmoimMeetupNew(onmoimId)),
        icon: const Icon(Icons.add, color: AppColors.primaryPink),
      ),
      useWarmBackground: false,
      children: [
        const _MeetupSearchSortRow(),
        const SizedBox(height: AppSpacing.lg),
        _MeetupSectionTitle(
          title: '다가오는 약속',
          count: upcoming.length,
          onCreateTap: () => context.go(RoutePaths.onmoimMeetupNew(onmoimId)),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final meetup in upcoming) ...[
          _MeetupSummaryCard(
            meetup: meetup,
            onTap: () =>
                context.go(RoutePaths.onmoimMeetupDetail(onmoimId, meetup.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _MeetupSectionTitle(title: '지난 약속', count: past.length),
          const SizedBox(height: AppSpacing.sm),
          for (final meetup in past) ...[
            _MeetupSummaryCard(
              meetup: meetup,
              onTap: () => context.go(
                RoutePaths.onmoimMeetupDetail(onmoimId, meetup.id),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: 72),
      ],
    );
  }
}

class _MeetupSectionTitle extends StatelessWidget {
  const _MeetupSectionTitle({
    required this.title,
    required this.count,
    this.onCreateTap,
  });

  final String title;
  final int count;
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        OnmuChip(label: '$count개'),
        const Spacer(),
        if (onCreateTap != null)
          TextButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('약속 만들기'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}

class _MeetupSearchSortRow extends StatelessWidget {
  const _MeetupSearchSortRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OnmuCard(
            onTap: () =>
                _showMeetupListSnack(context, '약속 검색 입력은 다음 단계에서 연결할게요.'),
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.lineSoft,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '모임 약속 검색',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () =>
              _showMeetupListSnack(context, '현재는 날짜 순으로 정렬되어 있어요.'),
          icon: const Icon(Icons.keyboard_arrow_down),
          label: const Text('날짜 순'),
        ),
        IconButton.outlined(
          tooltip: '약속 필터',
          onPressed: () =>
              _showMeetupListSnack(context, '진행 중, 예정, 완료 필터는 다음 단계에서 연결할게요.'),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}

class _MeetupSummaryCard extends StatelessWidget {
  const _MeetupSummaryCard({required this.meetup, required this.onTap});

  final OnMoimMeetupSummary meetup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MeetupThumb(kind: meetup.iconKind),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OnmuChip(
                      label: meetup.statusLabel,
                      selected: !meetup.isPast,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        meetup.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: '약속 더보기',
                      onPressed: () => _showMeetupListSnack(
                        context,
                        '${meetup.title} 더보기 메뉴는 다음 단계에서 연결할게요.',
                      ),
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                Text(
                  meetup.dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meetup.placeName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final member in demoOnMoimMemberProfiles.take(
                      meetup.memberCount > 4 ? 4 : meetup.memberCount,
                    )) ...[
                      PixelAvatar(label: member.name, size: 22),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    if (meetup.extraMemberCount > 0)
                      OnmuChip(label: '+${meetup.extraMemberCount}'),
                    const Spacer(),
                    OnmuChip(
                      label: meetup.statusType,
                      selected: !meetup.isPast,
                    ),
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

void _showMeetupListSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _MeetupThumb extends StatelessWidget {
  const _MeetupThumb({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      'coffee' => Icons.local_cafe_outlined,
      'park' => Icons.park_outlined,
      _ => Icons.water,
    };
    final color = switch (kind) {
      'coffee' => AppColors.accentBrown,
      'park' => AppColors.accentGreen,
      _ => AppColors.accentBlue,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox.square(
        dimension: 82,
        child: Icon(icon, color: color, size: 34),
      ),
    );
  }
}
