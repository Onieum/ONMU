import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/meetup_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/onmu_step_progress.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class MeetupPlaceHandoffPage extends StatelessWidget {
  const MeetupPlaceHandoffPage({required this.meetupId, super.key});

  final String meetupId;

  @override
  Widget build(BuildContext context) {
    final selectedMembers = mockMeetup.members
        .where((member) => member.selected)
        .toList();

    return OnmuScaffold(
      title: '장소 선택',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuPrimaryButton(
        label: '선택 완료',
        icon: Icons.check,
        onPressed: () =>
            context.push(RoutePaths.onmoimMeetupDetail('friends', meetupId)),
      ),
      children: [
        const OnmuStepProgress(currentIndex: 2),
        const SizedBox(height: AppSpacing.xl),
        OnmuCard(
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시간까지 정해졌어요',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '성수동에서 함께 갈 곳을 고를 차례예요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              for (final member in selectedMembers)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: PixelAvatar(label: member.name, size: 34),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택한 일정',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '5월 26일 (일) · 오후 1:00 ~ 3:00',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
