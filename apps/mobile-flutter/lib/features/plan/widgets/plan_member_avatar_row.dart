import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/widgets/pixel_avatar.dart';

class PlanMemberAvatarRow extends StatelessWidget {
  const PlanMemberAvatarRow({required this.members, super.key, this.trailing});

  final List<PlanMember> members;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final member in members) PlanMemberAvatar(member: member),
        ?trailing,
      ],
    );
  }
}

class PlanMemberAvatar extends StatelessWidget {
  const PlanMemberAvatar({required this.member, super.key});

  final PlanMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelAvatar(
            label: member.name,
            size: 42,
            profileImageUrl: member.profileImageUrl,
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
