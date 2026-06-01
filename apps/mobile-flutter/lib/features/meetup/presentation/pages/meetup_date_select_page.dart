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
import '../../../../shared/widgets/onmu_step_progress.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class MeetupDateSelectPage extends StatefulWidget {
  const MeetupDateSelectPage({super.key});

  @override
  State<MeetupDateSelectPage> createState() => _MeetupDateSelectPageState();
}

class _MeetupDateSelectPageState extends State<MeetupDateSelectPage> {
  static const _dateChoices = [
    _DateChoice(day: '23', weekday: '목', fullWeekday: '목요일', caption: '오늘'),
    _DateChoice(day: '24', weekday: '금', fullWeekday: '금요일'),
    _DateChoice(day: '25', weekday: '토', fullWeekday: '토요일'),
    _DateChoice(day: '26', weekday: '일', fullWeekday: '일요일'),
    _DateChoice(day: '27', weekday: '월', fullWeekday: '월요일'),
    _DateChoice(day: '28', weekday: '화', fullWeekday: '화요일'),
  ];

  var _selectedDateIndex = 3;
  TimeCandidate _selectedTime = mockTimeCandidates[1];
  _TimeFilter? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final selectedDate = _dateChoices[_selectedDateIndex];
    final filteredCandidates = mockTimeCandidates.where((candidate) {
      return switch (_selectedFilter) {
        _TimeFilter.available => candidate.status == '모두 가능',
        _TimeFilter.partial => candidate.status == '일부만 가능',
        _TimeFilter.difficult => candidate.status == '보통 어려워요',
        _TimeFilter.recommended => candidate.recommended,
        null => true,
      };
    }).toList();

    return OnmuScaffold(
      title: '날짜/시간 선택',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '선택한 일정',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        _selectedScheduleLabel,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OnmuPrimaryButton(
              label: '장소 선택',
              icon: Icons.arrow_forward,
              onPressed: () =>
                  context.push(RoutePaths.meetupPlaces(mockMeetup.id)),
            ),
          ],
        ),
      ),
      children: [
        const OnmuStepProgress(currentIndex: 1),
        const SizedBox(height: AppSpacing.xl),
        OnmuCard(
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '약속 시간 추천',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '참여자들의 가능한 시간을 분석했어요. 모두에게 가장 잘 맞는 시간이에요!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              for (final member in mockMembers.where(
                (member) => member.selected,
              ))
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: PixelAvatar(label: member.name, size: 34),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _FilterChipButton(
              key: const ValueKey('time-filter-available'),
              label: '가능한 시간',
              icon: Icons.circle,
              color: AppColors.accentGreen,
              selected: _selectedFilter == _TimeFilter.available,
              onTap: () => _selectFilter(_TimeFilter.available),
            ),
            _FilterChipButton(
              key: const ValueKey('time-filter-partial'),
              label: '일부만 가능',
              icon: Icons.circle,
              color: AppColors.accentOrange,
              selected: _selectedFilter == _TimeFilter.partial,
              onTap: () => _selectFilter(_TimeFilter.partial),
            ),
            _FilterChipButton(
              key: const ValueKey('time-filter-difficult'),
              label: '보통 어려워요',
              icon: Icons.circle,
              color: AppColors.accentRed,
              selected: _selectedFilter == _TimeFilter.difficult,
              onTap: () => _selectFilter(_TimeFilter.difficult),
            ),
            _FilterChipButton(
              key: const ValueKey('time-filter-recommended'),
              label: '추천 시간',
              selected: _selectedFilter == _TimeFilter.recommended,
              icon: Icons.star,
              onTap: () => _selectFilter(_TimeFilter.recommended),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('날짜 선택', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  const OnmuChip(label: '캘린더 보기', icon: Icons.calendar_month),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < _dateChoices.length; index++)
                    _DatePill(
                      choice: _dateChoices[index],
                      selected: index == _selectedDateIndex,
                      onTap: () => setState(() => _selectedDateIndex = index),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      '시간 선택 (${selectedDate.day}일 ${selectedDate.fullWeekday})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              for (final candidate in filteredCandidates)
                _TimeCandidateRow(
                  candidate: candidate,
                  selected: candidate.time == _selectedTime.time,
                  onTap: () => setState(() => _selectedTime = candidate),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String get _selectedScheduleLabel {
    final date = _dateChoices[_selectedDateIndex];
    return '5월 ${date.day}일 (${date.weekday}) · '
        '${_formatTime(_selectedTime.time)} ${_formatRangeEnd(_selectedTime.range)}';
  }

  void _selectFilter(_TimeFilter filter) {
    setState(() {
      _selectedFilter = _selectedFilter == filter ? null : filter;
    });
  }

  String _formatTime(String time) {
    final hour = int.parse(time.split(':').first);
    final minute = time.split(':').last;
    if (hour == 12) {
      return '오후 12:$minute';
    }
    if (hour > 12) {
      return '오후 ${hour - 12}:$minute';
    }
    return '오전 $hour:$minute';
  }

  String _formatRangeEnd(String range) {
    final time = range.replaceAll('~', '').trim();
    final hour = int.parse(time.split(':').first);
    final minute = time.split(':').last;
    if (hour == 12) {
      return '~ 12:$minute';
    }
    if (hour > 12) {
      return '~ ${hour - 12}:$minute';
    }
    return '~ $hour:$minute';
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _DateChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('date-pill-${choice.day}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPurpleSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.linePurple : AppColors.lineSoft,
          ),
        ),
        child: SizedBox(
          width: 48,
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (choice.caption != null)
                Text(
                  choice.caption!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              Text(choice.day, style: Theme.of(context).textTheme.titleMedium),
              Text(
                choice.weekday,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (selected)
                const Icon(
                  Icons.star,
                  size: 16,
                  color: AppColors.primaryPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeCandidateRow extends StatelessWidget {
  const _TimeCandidateRow({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final TimeCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (candidate.status) {
      '모두 가능' => AppColors.accentGreen,
      '일부만 가능' => AppColors.accentOrange,
      '보통 어려워요' => AppColors.accentRed,
      _ => AppColors.textMuted,
    };

    return GestureDetector(
      key: ValueKey('time-candidate-${candidate.time}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.bgPurpleSoft
                : statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.linePurple
                  : statusColor.withValues(alpha: 0.46),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Column(
                    children: [
                      Icon(
                        key: ValueKey('time-status-icon-${candidate.time}'),
                        candidate.recommended ? Icons.stars : Icons.circle,
                        color: statusColor,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        candidate.time,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        candidate.range,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.status,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: statusColor),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        candidate.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 44,
                  child: Text(
                    key: ValueKey('time-count-${candidate.time}'),
                    candidate.countLabel,
                    textAlign: TextAlign.right,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: OnmuChip(
        label: label,
        selected: selected,
        icon: icon,
        color: color,
      ),
    );
  }
}

enum _TimeFilter { available, partial, difficult, recommended }

class _DateChoice {
  const _DateChoice({
    required this.day,
    required this.weekday,
    required this.fullWeekday,
    this.caption,
  });

  final String day;
  final String weekday;
  final String fullWeekday;
  final String? caption;
}
