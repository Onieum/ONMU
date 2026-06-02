import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onmoim_cards.dart';

class OnMoimGroupHomePage extends StatelessWidget {
  const OnMoimGroupHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final group = demoOnMoimGroups.first;

    return OnmuScaffold(
      title: group.name,
      actions: [
        IconButton(
          tooltip: '모임 설정',
          onPressed: () => context.go(RoutePaths.onmoimSettings(group.id)),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      children: [
        _GroupSummary(group: group),
        const SizedBox(height: AppSpacing.md),
        _PinnedMeetupRail(onTap: () => context.go(RoutePaths.onmoimDemoMeetup)),
        const SizedBox(height: AppSpacing.lg),
        Text('최근 흐름', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        _RecentValueRow(
          icon: Icons.chat_bubble_outline,
          label: '채팅',
          title: '현우: 항공권 모바일 체크인 했어!',
          meta: '방금 전 · 안 읽은 메시지 3개',
          onTap: () => context.go(RoutePaths.onmoimDemoChat),
        ),
        _RecentValueRow(
          icon: Icons.calendar_month_outlined,
          label: '약속',
          title: '제주도 여행 장소 투표 진행 중',
          meta: '온무식당 5표 · 무드카페 3표',
          onTap: () => context.go(RoutePaths.onmoimDemoMeetupBoard),
        ),
        _RecentValueRow(
          icon: Icons.photo_library_outlined,
          label: '추억',
          title: '민지님이 새 사진 8장을 올렸어요',
          meta: '제주 카페에서 · 지난 모임',
          onTap: () => context.go(RoutePaths.onmoimDemoMemories),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

const _homePinnedMeetups = [
  demoPinnedMeetup,
  OnMoimPinnedMeetup(
    id: 'dinner',
    title: '주말 나들이',
    dateLabel: '5.26(일) 오후 1:00',
    placeName: '성수동 일대',
    statusLabel: '장소 후보 3개',
    voteSummary: '온무식당 5표 · 무드카페 3표',
  ),
  OnMoimPinnedMeetup(
    id: 'checklist',
    title: '여행 준비 체크리스트',
    dateLabel: 'D-7까지 준비',
    placeName: '항공권 · 숙소 · 준비물',
    statusLabel: '6/12 완료',
    voteSummary: '혜진, 준호 응답 대기',
  ),
];

class _GroupSummary extends StatelessWidget {
  const _GroupSummary({required this.group});

  final OnMoimGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '우리 다음 약속이 거의 정해졌어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textMain),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            OnmuChip(label: '멤버 ${group.members.length}명'),
            const OnmuChip(label: '약속 2개 진행중'),
            const OnmuChip(label: '오늘 새 이야기 3개'),
          ],
        ),
      ],
    );
  }
}

class _PinnedMeetupRail extends StatelessWidget {
  const _PinnedMeetupRail({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('고정 약속', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            const OnmuChip(label: '옆으로 보기', selected: true),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 184,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: _homePinnedMeetups.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final meetup = _homePinnedMeetups[index];

              return SizedBox(
                width: 286,
                child: PinnedMeetupCard(meetup: meetup, onBoardPressed: onTap),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentValueRow extends StatelessWidget {
  const _RecentValueRow({
    required this.icon,
    required this.label,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryPinkSoft,
              foregroundColor: AppColors.primaryPink,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meta,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
