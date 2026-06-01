import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/meetup_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class MeetupRouteReviewPage extends StatelessWidget {
  const MeetupRouteReviewPage({required this.meetupId, super.key});

  final String meetupId;

  @override
  Widget build(BuildContext context) {
    final meetup = mockMeetup;

    return OnmuScaffold(
      title: '동선 확인',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuPrimaryButton(
        label: '약속 완료',
        icon: Icons.check,
        onPressed: () => context.push(RoutePaths.meetupComplete(meetup.id)),
      ),
      children: [
        OnmuCard(
          child: Row(
            children: [
              const Icon(Icons.route_outlined, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '방문 동선을 확인해요',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '일정과 이동 시간을 한 번 더 맞춰봤어요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _RouteSketch(),
        const SizedBox(height: AppSpacing.md),
        const _RouteSummaryCard(),
        const SizedBox(height: AppSpacing.md),
        _RouteTimelineCard(visitPlan: meetup.visitPlan),
        const SizedBox(height: AppSpacing.md),
        const _ReminderCard(),
      ],
    );
  }
}

class _RouteSketch extends StatelessWidget {
  const _RouteSketch();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RouteSketchPainter())),
            const Positioned(
              left: 34,
              top: 32,
              child: _RoutePoint(order: 1, label: '13:00'),
            ),
            const Positioned(
              right: 52,
              top: 42,
              child: _RoutePoint(order: 2, label: '14:45'),
            ),
            const Positioned(
              left: 86,
              bottom: 38,
              child: _RoutePoint(order: 3, label: '16:30'),
            ),
            const Positioned(
              right: 36,
              bottom: 24,
              child: _RoutePoint(order: 4, label: '17:40'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSketchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.bgGrid
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(58, 58)
      ..quadraticBezierTo(size.width * 0.46, 24, size.width - 78, 68)
      ..quadraticBezierTo(size.width * 0.52, 116, 114, size.height - 52)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height - 16,
        size.width - 58,
        size.height - 44,
      );

    final linePaint = Paint()
      ..color = AppColors.linePurple
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.order, required this.label});

  final int order;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.bgDefault, width: 3),
          ),
          child: SizedBox.square(
            dimension: 38,
            child: Center(
              child: Text(
                '$order',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        OnmuChip(label: label),
      ],
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Row(
        children: const [
          Expanded(
            child: _SummaryItem(
              icon: Icons.schedule,
              label: '총 예상 시간',
              value: '4시간 10분',
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              icon: Icons.near_me_outlined,
              label: '이동 시간',
              value: '40분',
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              icon: Icons.groups_rounded,
              label: '참여자',
              value: '4명',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryPurple),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _RouteTimelineCard extends StatelessWidget {
  const _RouteTimelineCard({required this.visitPlan});

  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_list_bulleted,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('최종 일정표', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final plan in visitPlan) _RoutePlanTile(plan: plan),
        ],
      ),
    );
  }
}

class _RoutePlanTile extends StatelessWidget {
  const _RoutePlanTile({required this.plan});

  final VisitPlan plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgPaper,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Text(
                  plan.time,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.place,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${plan.kind} · ${plan.duration}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('알림 설정', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ReminderRow(
            icon: Icons.calendar_month,
            label: '약속 하루 전 알림',
            value: '5월 25일 오후 7:00',
          ),
          const _ReminderRow(
            icon: Icons.access_time,
            label: '출발 시간 알림',
            value: '5월 26일 오전 10:30',
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryPurple),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryPurple),
          ),
        ],
      ),
    );
  }
}
