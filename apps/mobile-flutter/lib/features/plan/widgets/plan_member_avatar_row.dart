import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/widgets/onmu_remove_badge_button.dart';
import '../../../shared/widgets/pixel_avatar.dart';

class PlanMemberAvatarRow extends StatelessWidget {
  const PlanMemberAvatarRow({
    required this.members,
    super.key,
    this.trailing,
    this.onRemoveMember,
    this.canRemoveMember,
  });

  final List<PlanMember> members;
  final Widget? trailing;
  final ValueChanged<PlanMember>? onRemoveMember;
  final bool Function(PlanMember member)? canRemoveMember;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final member in members)
          PlanMemberAvatar(
            member: member,
            onRemovePressed:
                onRemoveMember != null &&
                    (canRemoveMember?.call(member) ?? true)
                ? () => onRemoveMember!(member)
                : null,
          ),
        ?trailing,
      ],
    );
  }
}

class PlanMemberAvatar extends StatelessWidget {
  const PlanMemberAvatar({
    required this.member,
    super.key,
    this.onRemovePressed,
  });

  final PlanMember member;
  final VoidCallback? onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Center(
                    child: PixelAvatar(
                      label: member.name,
                      size: 42,
                      profileImageUrl: member.profileImageUrl,
                      fallbackToViewerCharacter:
                          member.fallbackToViewerCharacter,
                    ),
                  ),
                ),
                if (onRemovePressed != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: OnmuRemoveBadgeButton(
                      tooltip: '${member.name} 제거',
                      onPressed: onRemovePressed!,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
