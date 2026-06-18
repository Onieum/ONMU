import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/notification_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/home_notifications_view_model.dart';

class HomeNotificationsPage extends ConsumerWidget {
  const HomeNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(homeNotificationsViewModelProvider);
    return OnmuScaffold(
      title: '알림',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      children: [
        if (notifications.hasError)
          _NotificationErrorState(
            onRetry: () => ref.invalidate(homeNotificationsViewModelProvider),
          )
        else
          notifications.when(
            data: (items) => items.isEmpty
                ? const _EmptyNotificationState()
                : _NotificationContent(
                    items: items,
                    onMarkAllRead: () => ref
                        .read(homeNotificationsViewModelProvider.notifier)
                        .markAllRead(),
                    onRespondFriendRequest: (item, accept) async {
                      try {
                        await ref
                            .read(homeNotificationsViewModelProvider.notifier)
                            .respondFriendRequest(item, accept: accept);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                accept ? '친구 요청을 수락했어요.' : '친구 요청을 거절했어요.',
                              ),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('친구 요청 처리에 실패했어요. 다시 시도해주세요.'),
                            ),
                          );
                        }
                      }
                    },
                    onTapItem: (item) async {
                      final route = _routeForNotification(item);
                      if (route == null) {
                        return;
                      }
                      await ref
                          .read(homeNotificationsViewModelProvider.notifier)
                          .markRead(item);
                      if (context.mounted) {
                        context.go(route);
                      }
                    },
                  ),
            loading: () => const _NotificationLoadingState(),
            error: (error, stackTrace) => _NotificationErrorState(
              onRetry: () => ref.invalidate(homeNotificationsViewModelProvider),
            ),
          ),
      ],
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.items,
    required this.onMarkAllRead,
    required this.onTapItem,
    required this.onRespondFriendRequest,
  });

  final List<NotificationItem> items;
  final VoidCallback onMarkAllRead;
  final ValueChanged<NotificationItem> onTapItem;
  final void Function(NotificationItem item, bool accept) onRespondFriendRequest;

  @override
  Widget build(BuildContext context) {
    final unreadCount = items.where((item) => !item.isRead).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unreadCount > 0) ...[
          _NotificationSummary(
            unreadCount: unreadCount,
            onMarkAllRead: onMarkAllRead,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _NotificationList(
          items: items,
          onTapItem: onTapItem,
          onRespondFriendRequest: onRespondFriendRequest,
        ),
      ],
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.linePink,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '읽지 않은 알림 $unreadCount개',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.textMain),
            ),
          ),
          OnmuSecondaryButton(
            label: '모두 읽음',
            icon: Icons.done_all_rounded,
            onPressed: onMarkAllRead,
          ),
        ],
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
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('알림이 없어요.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '서버에서 알림 데이터를 받으면 이곳에 표시돼요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationLoadingState extends StatelessWidget {
  const _NotificationLoadingState();

  @override
  Widget build(BuildContext context) {
    return const OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  const _NotificationErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '알림을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '잠시 후 다시 시도해 주세요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OnmuSecondaryButton(
            label: '다시 불러오기',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.onTapItem,
    required this.onRespondFriendRequest,
  });

  final List<NotificationItem> items;
  final ValueChanged<NotificationItem> onTapItem;
  final void Function(NotificationItem item, bool accept) onRespondFriendRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _NotificationCard(
            item: item,
            onTap: () => onTapItem(item),
            onAcceptFriendRequest: () => onRespondFriendRequest(item, true),
            onDeclineFriendRequest: () => onRespondFriendRequest(item, false),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onAcceptFriendRequest,
    required this.onDeclineFriendRequest,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onAcceptFriendRequest;
  final VoidCallback onDeclineFriendRequest;

  @override
  Widget build(BuildContext context) {
    final route = _routeForNotification(item);
    final friendRequestId = item.payloadString('friendRequestId');
    final canRespondFriendRequest =
        item.notificationType == 'friend_request' &&
        friendRequestId != null &&
        friendRequestId.isNotEmpty &&
        !item.isRead;
    final textTheme = Theme.of(context).textTheme;
    return OnmuCard(
      onTap: route == null || canRespondFriendRequest ? null : onTap,
      backgroundColor: item.isRead ? AppColors.bgDefault : AppColors.bgPaper,
      borderColor: item.isRead ? AppColors.lineSoft : AppColors.linePink,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(type: item.notificationType, isRead: item.isRead),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (item.timeLabel.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        item.timeLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
                if (canRespondFriendRequest) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OnmuSecondaryButton(
                          label: '거절',
                          icon: Icons.close_rounded,
                          onPressed: onDeclineFriendRequest,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OnmuPrimaryButton(
                          label: '수락',
                          icon: Icons.person_add_alt_1_rounded,
                          onPressed: onAcceptFriendRequest,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (route != null && !canRespondFriendRequest) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ],
      ),
    );
  }
}

String? _routeForNotification(NotificationItem item) {
  final groupId = item.groupId;
  final planId = item.planId;
  final settlementId = item.payloadString('settlementId');
  if (groupId != null &&
      planId != null &&
      settlementId != null &&
      settlementId.isNotEmpty) {
    return RoutePaths.planSettlementDetail(groupId, planId, settlementId);
  }

  final voteId = item.payloadString('voteId');
  if (groupId != null && voteId != null && voteId.isNotEmpty) {
    return RoutePaths.groupVote(groupId, voteId);
  }

  final recordId = item.payloadString('recordId');
  if (groupId != null && recordId != null && recordId.isNotEmpty) {
    return RoutePaths.groupMemoryDetail(groupId, recordId);
  }

  if (groupId != null) {
    return RoutePaths.groupChat(groupId);
  }
  return null;
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type, required this.isRead});

  final String type;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'settlement_created' ||
      'settlement_requested' => Icons.receipt_long_rounded,
      'vote_created' || 'vote_closed' => Icons.how_to_vote_rounded,
      'record_created' => Icons.auto_stories_rounded,
      'place_candidate_created' => Icons.place_rounded,
      _ => Icons.notifications_none_rounded,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isRead ? AppColors.bgWarm : AppColors.primaryPinkSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Icon(
        icon,
        color: isRead ? AppColors.textSub : AppColors.primaryPurpleDark,
        size: 22,
      ),
    );
  }
}
