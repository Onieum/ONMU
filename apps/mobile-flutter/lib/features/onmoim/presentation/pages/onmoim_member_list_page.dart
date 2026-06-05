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

class OnMoimMemberListPage extends StatelessWidget {
  const OnMoimMemberListPage({required this.onmoimId, super.key});

  final String onmoimId;

  @override
  Widget build(BuildContext context) {
    final group = demoOnMoimGroups.firstWhere(
      (group) => group.id == onmoimId,
      orElse: () => demoOnMoimGroups.first,
    );

    return OnmuScaffold(
      title: '모임원',
      subtitle: '${group.name} · ${group.members.length}명',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.groupDetail(onmoimId)),
      useWarmBackground: false,
      children: [
        const _MemberSearchField(),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (
                var index = 0;
                index < demoOnMoimMemberProfiles.length;
                index += 1
              ) ...[
                _MemberRow(profile: demoOnMoimMemberProfiles[index]),
                if (index < demoOnMoimMemberProfiles.length - 1)
                  const Divider(height: 1, color: AppColors.lineSoft),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InviteCard(onTap: () => context.go(RoutePaths.groupInvite(onmoimId))),
        const SizedBox(height: 72),
      ],
    );
  }
}

class OnMoimInvitePage extends StatefulWidget {
  const OnMoimInvitePage({required this.onmoimId, super.key});

  final String onmoimId;

  @override
  State<OnMoimInvitePage> createState() => _OnMoimInvitePageState();
}

class _OnMoimInvitePageState extends State<OnMoimInvitePage> {
  final Set<String> _selectedNames = {'은지', '태호'};

  @override
  Widget build(BuildContext context) {
    final candidates = demoOnMoimMemberProfiles.where((profile) {
      return profile.invited || profile.name == '소연';
    }).toList();

    return OnmuScaffold(
      title: '친구 초대하기',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.groupMembers(widget.onmoimId)),
      useWarmBackground: false,
      bottom: FilledButton.icon(
        onPressed: () => context.go(RoutePaths.groupMembers(widget.onmoimId)),
        icon: const Icon(Icons.person_add_outlined),
        label: Text('선택한 친구 초대하기 ${_selectedNames.length}명'),
      ),
      children: [
        const _SelectedInviteStrip(),
        const SizedBox(height: AppSpacing.md),
        const _MemberSearchField(hint: '친구 이름 검색'),
        const SizedBox(height: AppSpacing.lg),
        Text('추천 친구', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < candidates.length; index += 1) ...[
                _InviteCandidateRow(
                  profile: candidates[index],
                  selected: _selectedNames.contains(candidates[index].name),
                  onTap: () {
                    setState(() {
                      final name = candidates[index].name;
                      if (!_selectedNames.add(name)) {
                        _selectedNames.remove(name);
                      }
                    });
                  },
                ),
                if (index < candidates.length - 1)
                  const Divider(height: 1, color: AppColors.lineSoft),
              ],
            ],
          ),
        ),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _MemberSearchField extends StatelessWidget {
  const _MemberSearchField({this.hint = '멤버 검색'});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
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
          Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.profile});

  final OnMoimMemberProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PixelAvatar(label: profile.name, size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  profile.note,
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
          OnmuChip(label: profile.statusLabel, selected: !profile.invited),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.linePink,
              style: BorderStyle.solid,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  child: Icon(Icons.add),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '친구 초대하기',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedInviteStrip extends StatelessWidget {
  const _SelectedInviteStrip();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final name in ['은지', '태호']) ...[
            OnmuCard(
              backgroundColor: AppColors.primaryPinkSoft,
              borderColor: AppColors.linePink,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  PixelAvatar(label: name, size: 28),
                  const SizedBox(width: AppSpacing.xs),
                  Text(name, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _InviteCandidateRow extends StatelessWidget {
  const _InviteCandidateRow({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final OnMoimMemberProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            PixelAvatar(label: profile.name, size: 48),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    profile.note,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryPink : AppColors.bgDefault,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.primaryPink : AppColors.lineBrown,
                ),
              ),
              child: SizedBox.square(
                dimension: 28,
                child: Icon(
                  selected ? Icons.check : Icons.add,
                  color: selected ? AppColors.textInverse : AppColors.textSub,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
