import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/group_models.dart';
import 'onmu_chip.dart';

class OnmuPlanStatusChip extends StatelessWidget {
  const OnmuPlanStatusChip({
    required this.status,
    required this.label,
    super.key,
  });

  final PlanProgressStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!status.isDisplayable || label.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 72),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: OnmuChip(
          label: label,
          selected: false,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(PlanProgressStatus status) {
    return switch (status) {
      PlanProgressStatus.scheduled => AppColors.accentBlue,
      PlanProgressStatus.active => AppColors.accentGreen,
      PlanProgressStatus.completed => AppColors.textMuted,
      PlanProgressStatus.cancelled => AppColors.accentRed,
      PlanProgressStatus.unknown => AppColors.accentOrange,
    };
  }
}
