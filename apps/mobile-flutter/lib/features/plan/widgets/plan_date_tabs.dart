import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../view_model/plan_detail_view_model.dart';

class PlanDateTabs extends StatelessWidget {
  const PlanDateTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<PlanDateTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final visibleTabs = tabs.isEmpty
        ? const [PlanDateTab(tabLabel: '일정', headingLabel: '일정 동선')]
        : tabs;

    return Row(
      children: [
        for (var index = 0; index < visibleTabs.length; index += 1)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    visibleTabs[index].tabLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
