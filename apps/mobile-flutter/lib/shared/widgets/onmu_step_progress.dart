import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class OnmuStepProgress extends StatelessWidget {
  const OnmuStepProgress({required this.currentIndex, super.key});

  final int currentIndex;

  static const _steps = [
    (Icons.groups_rounded, '참여자'),
    (Icons.calendar_month_rounded, '날짜/시간'),
    (Icons.location_on_rounded, '장소'),
    (Icons.check_rounded, '완료'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < _steps.length; index++) ...[
          Expanded(
            child: _StepDot(
              icon: _steps[index].$1,
              label: _steps[index].$2,
              selected: index == currentIndex,
              done: index < currentIndex,
            ),
          ),
          if (index != _steps.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.icon,
    required this.label,
    required this.selected,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final active = selected || done;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: active ? AppColors.primaryPurple : AppColors.lineSoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: SizedBox.square(
            dimension: 34,
            child: Icon(
              icon,
              size: 18,
              color: active ? AppColors.textInverse : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: active ? AppColors.primaryPurple : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
