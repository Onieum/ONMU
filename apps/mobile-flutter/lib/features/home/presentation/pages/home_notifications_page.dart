import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/demo_route_seeds.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class HomeNotificationsPage extends StatefulWidget {
  const HomeNotificationsPage({super.key});

  @override
  State<HomeNotificationsPage> createState() => _HomeNotificationsPageState();
}

class _HomeNotificationsPageState extends State<HomeNotificationsPage> {
  String _selectedFilter = '전체';

  List<_NotificationItem> get _filteredItems {
    if (_selectedFilter == '전체') {
      return _items;
    }
    return _items.where((item) => item.kind == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final todayItems = items.where((item) => item.group == '오늘').toList();
    final yesterdayItems = items.where((item) => item.group == '어제').toList();

    return OnmuScaffold(
      title: '알림',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(RoutePaths.home);
      },
      action: IconButton(
        tooltip: '알림 설정',
        onPressed: () => _showSnack(context, '알림 설정은 다음 단계에서 연결할게요.'),
        icon: const Icon(Icons.settings_outlined),
      ),
      children: [
        Text(
          '약속, 투표, 정산, 기록 업데이트가 최신순으로 쌓여요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: AppSpacing.lg),
        _NotificationFilters(
          selected: _selectedFilter,
          onChanged: (value) => setState(() => _selectedFilter = value),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (todayItems.isNotEmpty)
          _NotificationGroup(title: '오늘', items: todayItems),
        if (todayItems.isNotEmpty && yesterdayItems.isNotEmpty)
          const SizedBox(height: AppSpacing.xxl),
        if (yesterdayItems.isNotEmpty)
          _NotificationGroup(title: '어제', items: yesterdayItems),
        if (items.isEmpty) const _EmptyNotificationState(),
      ],
    );
  }
}

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({required this.selected, required this.onChanged});

  static const _filters = ['전체', '약속', '투표', '정산', '기록'];

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _filters) ...[
            _FilterChipButton(
              label: filter,
              selected: selected == filter,
              onTap: () => onChanged(filter),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: onTap,
        child: OnmuChip(label: label, selected: selected),
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({required this.title, required this.items});

  final String title;
  final List<_NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final item in items) ...[
          _NotificationCard(item: item),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () => _handleNotificationTap(context, item),
      backgroundColor: item.unread ? AppColors.bgPaper : AppColors.bgDefault,
      borderColor: item.unread ? AppColors.linePink : AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(item: item),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OnmuChip(label: item.kind, selected: item.unread),
                    const Spacer(),
                    Text(
                      item.time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
                if (item.actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _handleNotificationTap(context, item),
                      icon: const Icon(Icons.arrow_forward_ios, size: 12),
                      label: Text(item.actionLabel!),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    if (item.kind == '기록') {
      return const PixelAvatar(label: '민', size: 42);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: item.color.withValues(alpha: 0.46)),
      ),
      child: SizedBox.square(
        dimension: 42,
        child: Icon(item.icon, color: item.color, size: 23),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('해당 알림이 없어요', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.group,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.unread = false,
  });

  final String group;
  final String kind;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final bool unread;
}

const _items = [
  _NotificationItem(
    group: '오늘',
    kind: '약속',
    title: '성수 저녁 약속이 30분 뒤 시작돼요',
    body: '다운타우너 성수 · 18:30 · 도착까지 20분',
    time: '방금 전',
    icon: Icons.event_available_outlined,
    color: AppColors.primaryPurple,
    actionLabel: '약속 상세 보기',
    unread: true,
  ),
  _NotificationItem(
    group: '오늘',
    kind: '투표',
    title: '제주도 여행 장소 투표가 열렸어요',
    body: '카페 오션뷰, 흑돼지 맛집 돈사돈, 협재 해수욕장 후보를 비교 중이에요.',
    time: '12분 전',
    icon: Icons.how_to_vote_outlined,
    color: AppColors.accentBlue,
    actionLabel: '투표 확인하기',
    unread: true,
  ),
  _NotificationItem(
    group: '오늘',
    kind: '정산',
    title: '주말 나들이 정산이 만들어졌어요',
    body: '나는 103,333원을 받아요 · 총 186,000원',
    time: '25분 전',
    icon: Icons.receipt_long_outlined,
    color: AppColors.primaryPink,
    actionLabel: '정산 확인하기',
    unread: true,
  ),
  _NotificationItem(
    group: '오늘',
    kind: '기록',
    title: '민수님이 최근 기록에 댓글을 남겼어요',
    body: '“분위기 좋다! 어디야?”',
    time: '오전 10:24',
    icon: Icons.chat_bubble_outline,
    color: AppColors.accentBrown,
    actionLabel: '기록 보기',
  ),
  _NotificationItem(
    group: '어제',
    kind: '약속',
    title: '한남 카페 투어 일정이 확정됐어요',
    body: '5월 28일 토요일 오후 2시 · 한남동 일대',
    time: '오후 6:12',
    icon: Icons.check_circle_outline,
    color: AppColors.accentGreen,
    actionLabel: '약속 확인하기',
  ),
  _NotificationItem(
    group: '어제',
    kind: '기록',
    title: '하린님이 제주 바다 기록에 좋아요를 눌렀어요',
    body: '대학 동기 여행단 · 최근 기록',
    time: '오후 2:03',
    icon: Icons.favorite_border,
    color: AppColors.primaryPink,
  ),
];

void _handleNotificationTap(BuildContext context, _NotificationItem item) {
  switch (item.kind) {
    case '투표':
      context.push(
        RoutePaths.planVoteNew(DemoRouteSeeds.groupId, DemoRouteSeeds.planId),
      );
      return;
    case '정산':
      context.push(
        RoutePaths.planSettlementDetail(
          DemoRouteSeeds.groupId,
          DemoRouteSeeds.planId,
          DemoRouteSeeds.settlementId,
        ),
      );
      return;
    case '기록':
      context.push(RoutePaths.homeRecentRecords);
      return;
    default:
      context.push(
        RoutePaths.planDetail(DemoRouteSeeds.groupId, DemoRouteSeeds.planId),
      );
      return;
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
