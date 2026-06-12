import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_button.dart';
import 'onmu_card.dart';
import 'onmu_chip.dart';

class OnmuDateTimeRange {
  const OnmuDateTimeRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class OnmuDateTimeRangePicker {
  const OnmuDateTimeRangePicker._();

  static Future<OnmuDateTimeRange?> show({
    required BuildContext context,
    required DateTime initialStart,
    required DateTime initialEnd,
    String title = '날짜와 시간 선택',
  }) {
    return showModalBottomSheet<OnmuDateTimeRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _DateTimeRangePickerSheet(
        title: title,
        initialStart: initialStart,
        initialEnd: initialEnd.isAfter(initialStart)
            ? initialEnd
            : initialStart.add(const Duration(hours: 2)),
      ),
    );
  }
}

class _DateTimeRangePickerSheet extends StatefulWidget {
  const _DateTimeRangePickerSheet({
    required this.title,
    required this.initialStart,
    required this.initialEnd,
  });

  final String title;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_DateTimeRangePickerSheet> createState() =>
      _DateTimeRangePickerSheetState();
}

class _DateTimeRangePickerSheetState extends State<_DateTimeRangePickerSheet> {
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;
  late int _durationHours;

  DateTime get _start => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _hour,
    _minute,
  );

  DateTime get _end => _start.add(Duration(hours: _durationHours));

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialStart.year,
      widget.initialStart.month,
      widget.initialStart.day,
    );
    _hour = widget.initialStart.hour;
    _minute = widget.initialStart.minute >= 30 ? 30 : 0;
    final duration = widget.initialEnd.difference(widget.initialStart).inHours;
    _durationHours = duration.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.52,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SelectedScheduleCard(start: _start, end: _end),
                  const SizedBox(height: AppSpacing.lg),
                  Text('추천 시간대', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (final preset in _timePresets) ...[
                    _TimePresetTile(
                      preset: preset,
                      selected: _hour == preset.hour,
                      onTap: () => setState(() {
                        _hour = preset.hour;
                        _minute = 0;
                        _durationHours = preset.durationHours;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(
                    icon: Icons.calendar_month_outlined,
                    title: '날짜 선택',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final date = _today().add(Duration(days: index));
                        return _DateChip(
                          date: date,
                          selected: _sameDate(date, _selectedDate),
                          onTap: () => setState(() => _selectedDate = date),
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemCount: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(icon: Icons.schedule, title: '직접 시간 지정'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final hour in _hours)
                        OnmuChip(
                          label: '${hour.toString().padLeft(2, '0')}:00',
                          selected: _hour == hour,
                          onTap: () => setState(() => _hour = hour),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final minute in const [0, 30])
                        OnmuChip(
                          label: minute == 0 ? '정각' : '30분',
                          selected: _minute == minute,
                          onTap: () => setState(() => _minute = minute),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final duration in const [1, 2, 3, 4])
                        OnmuChip(
                          label: '$duration시간',
                          selected: _durationHours == duration,
                          onTap: () =>
                              setState(() => _durationHours = duration),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                bottomPadding + AppSpacing.md,
              ),
              child: OnmuPrimaryButton(
                label: '선택 완료',
                icon: Icons.check,
                color: AppColors.primaryPink,
                foregroundColor: AppColors.textInverse,
                onPressed: () => Navigator.of(
                  context,
                ).pop(OnmuDateTimeRange(start: _start, end: _end)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedScheduleCard extends StatelessWidget {
  const _SelectedScheduleCard({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택한 일정', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_formatDate(start)} · ${_formatTime(start)} ~ ${_formatTime(end)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePresetTile extends StatelessWidget {
  const _TimePresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _TimePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: selected ? AppColors.bgPurpleSoft : AppColors.bgDefault,
      borderColor: selected ? AppColors.linePink : AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            preset.recommended ? Icons.star_rounded : Icons.circle,
            color: preset.color,
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 74,
            child: Text(
              '${preset.hour.toString().padLeft(2, '0')}:00\n~ ${(preset.hour + preset.durationHours).toString().padLeft(2, '0')}:00',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              preset.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            ),
          ),
          Text(
            preset.availability,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: preset.color),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = _sameDate(date, _today());

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primaryPink : AppColors.lineSoft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              today ? '오늘' : '${date.month}월',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text('${date.day}', style: Theme.of(context).textTheme.titleMedium),
            Text(
              _weekday(date),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPink),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _TimePreset {
  const _TimePreset({
    required this.hour,
    required this.durationHours,
    required this.label,
    required this.availability,
    required this.color,
    this.recommended = false,
  });

  final int hour;
  final int durationHours;
  final String label;
  final String availability;
  final Color color;
  final bool recommended;
}

const _timePresets = [
  _TimePreset(
    hour: 12,
    durationHours: 2,
    label: '점심부터 여유롭게 시작할 수 있어요.',
    availability: '추천',
    color: AppColors.accentGreen,
  ),
  _TimePreset(
    hour: 13,
    durationHours: 2,
    label: '가장 많이 선택되는 시간대예요.',
    availability: '추천',
    color: AppColors.accentGreen,
    recommended: true,
  ),
  _TimePreset(
    hour: 15,
    durationHours: 2,
    label: '오후 일정으로 가볍게 잡기 좋아요.',
    availability: '보통',
    color: AppColors.accentOrange,
  ),
  _TimePreset(
    hour: 19,
    durationHours: 2,
    label: '퇴근 후 저녁 약속에 맞아요.',
    availability: '저녁',
    color: AppColors.accentRed,
  ),
];

const _hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _formatDate(DateTime date) {
  return '${date.month}월 ${date.day}일 (${_weekday(date)})';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _weekday(DateTime date) {
  return const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
}
