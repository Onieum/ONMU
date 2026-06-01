import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import 'onmu_button.dart';
import 'onmu_card.dart';
import 'onmu_scaffold.dart';

class PrototypePlaceholderPage extends StatelessWidget {
  const PrototypePlaceholderPage({
    required this.title,
    required this.description,
    super.key,
    this.primaryLabel,
    this.primaryRoute,
  });

  final String title;
  final String description;
  final String? primaryLabel;
  final String? primaryRoute;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: title,
      subtitle: description,
      children: [
        OnmuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI 프로토타입 준비 중',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '지금은 mock data와 화면 이동만 확인하는 단계예요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (primaryLabel != null && primaryRoute != null) ...[
          const SizedBox(height: AppSpacing.md),
          OnmuPrimaryButton(
            label: primaryLabel!,
            icon: Icons.arrow_forward,
            onPressed: () => context.go(primaryRoute!),
          ),
        ],
      ],
    );
  }
}
