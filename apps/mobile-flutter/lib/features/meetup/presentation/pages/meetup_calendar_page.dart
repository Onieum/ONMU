import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class MeetupCalendarPage extends StatefulWidget {
  const MeetupCalendarPage({super.key});

  @override
  State<MeetupCalendarPage> createState() => _MeetupCalendarPageState();
}

class _MeetupCalendarPageState extends State<MeetupCalendarPage> {
  static final _month = DateTime(2026, 5);
  static const _recommendedDays = {26};
  static const _availableDays = {23, 24, 25, 26, 27, 28};
  static const _partialDays = {29, 30, 31};

  var _selectedDay = 26;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month).weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return OnmuScaffold(
      title: '약속 캘린더',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuPrimaryButton(
        label: '선택 완료',
        icon: Icons.check,
        onPressed: () => context.pop(),
      ),
      children: [
        OnmuCard(
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '월간 후보를 한눈에 봐요',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '친구들이 가능한 날짜와 추천 날짜를 달력에서 확인해요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            OnmuChip(
              label: '모두 가능',
              icon: Icons.circle,
              color: AppColors.accentGreen,
            ),
            OnmuChip(
              label: '일부만 가능',
              icon: Icons.circle,
              color: AppColors.accentOrange,
            ),
            OnmuChip(
              label: '추천',
              icon: Icons.star,
              color: AppColors.primaryPurple,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '5월 2026',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  OnmuChip(label: '$_selectedDay일 선택', selected: true),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _CalendarWeekHeader(),
              const SizedBox(height: AppSpacing.xs),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: firstWeekday + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekday) {
                    return const SizedBox.shrink();
                  }

                  final day = index - firstWeekday + 1;
                  return _CalendarDayCell(
                    day: day,
                    selected: day == _selectedDay,
                    recommended: _recommendedDays.contains(day),
                    available: _availableDays.contains(day),
                    partial: _partialDays.contains(day),
                    onTap: () => setState(() => _selectedDay = day),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarWeekHeader extends StatelessWidget {
  const _CalendarWeekHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.selected,
    required this.recommended,
    required this.available,
    required this.partial,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool recommended;
  final bool available;
  final bool partial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = recommended
        ? AppColors.primaryPurple
        : available
        ? AppColors.accentGreen
        : partial
        ? AppColors.accentOrange
        : AppColors.lineSoft;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPurpleSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.linePurple : AppColors.lineSoft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.primaryPurple : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              recommended ? Icons.star : Icons.circle,
              size: recommended ? 13 : 8,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}
