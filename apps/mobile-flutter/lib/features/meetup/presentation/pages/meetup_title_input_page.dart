import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/onmu_step_progress.dart';

class MeetupTitleInputPage extends StatefulWidget {
  const MeetupTitleInputPage({super.key});

  @override
  State<MeetupTitleInputPage> createState() => _MeetupTitleInputPageState();
}

class _MeetupTitleInputPageState extends State<MeetupTitleInputPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '약속 이름 입력',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuPrimaryButton(
        label: '저장하기',
        icon: Icons.check,
        onPressed: () => context.pop(),
      ),
      children: [
        const OnmuStepProgress(currentIndex: 0),
        const SizedBox(height: AppSpacing.xl),
        OnmuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.edit_note, color: AppColors.primaryPurple),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '약속 이름을 정해주세요',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '참여자들이 한눈에 알아볼 수 있는 짧은 이름이면 충분해요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '예: 주말 나들이',
            prefixIcon: Icon(Icons.drive_file_rename_outline),
          ),
        ),
      ],
    );
  }
}
