import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/onmu_card.dart';
import '../../../shared/widgets/pixel_avatar.dart';
import '../domain/my_profile.dart';

class FriendPickerSheet extends StatefulWidget {
  const FriendPickerSheet({
    required this.friends,
    this.excludedNames = const {},
    this.title = '멤버 추가',
    this.description = '친구 목록에서 초대할 멤버를 선택해 주세요.',
    this.emptyLabel = '초대할 친구가 없어요.',
    super.key,
  });

  final List<FriendProfile> friends;
  final Set<String> excludedNames;
  final String title;
  final String description;
  final String emptyLabel;

  @override
  State<FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<FriendPickerSheet> {
  var _query = '';

  List<FriendProfile> get _filteredFriends {
    final query = _query.trim().toLowerCase();
    return widget.friends
        .where((friend) {
          if (!friend.isFriend || widget.excludedNames.contains(friend.name)) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return friend.name.toLowerCase().contains(query) ||
              friend.memo.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '친구 이름 검색',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final friend in _filteredFriends) ...[
                      _FriendPickerTile(friend: friend),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_filteredFriends.isEmpty)
                      OnmuCard(
                        backgroundColor: AppColors.bgDefault,
                        borderColor: AppColors.lineSoft,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: Text(widget.emptyLabel)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendPickerTile extends StatelessWidget {
  const _FriendPickerTile({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PixelAvatar(
            label: friend.name,
            size: 44,
            profileImageUrl: friend.profileImageUrl,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  friend.preferenceSummary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(friend),
            child: const Text('선택'),
          ),
        ],
      ),
    );
  }
}
