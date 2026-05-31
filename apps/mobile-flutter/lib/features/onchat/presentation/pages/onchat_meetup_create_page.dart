import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class OnChatMeetupCreatePage extends StatelessWidget {
  const OnChatMeetupCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗 약속 만들기',
      subtitle: '온챗 멤버를 그대로 가져와 약속 초안을 만드는 화면입니다.',
      children: [
        const _CreateSection(title: '참여자', chips: ['민서', '지훈', '하린', '나']),
        const SizedBox(height: AppSpacing.md),
        const _CreateSection(
          title: '날짜 후보',
          chips: ['6/6 토 15:00', '6/6 토 17:00', '6/7 일 14:00'],
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          child: TextField(
            decoration: const InputDecoration(
              labelText: '약속 메모',
              hintText: '조용한 카페에서 디저트 먹고 사진 남기기',
            ),
            maxLines: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuPrimaryButton(
          label: '약속 보드 만들기',
          icon: Icons.add_task,
          onPressed: () => context.go(RoutePaths.onchatMeetupBoard),
        ),
      ],
    );
  }
}

class _CreateSection extends StatelessWidget {
  const _CreateSection({required this.title, required this.chips});

  final String title;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final chip in chips) OnmuChip(label: chip, selected: true),
            ],
          ),
        ],
      ),
    );
  }
}
