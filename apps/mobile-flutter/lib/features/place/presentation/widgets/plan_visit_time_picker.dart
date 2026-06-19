import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_date_time_picker.dart';
import '../../../../shared/widgets/onmu_date_time_range_picker.dart';

class PlanVisitTimePicker {
  const PlanVisitTimePicker._();

  static Future<OnmuDateTimeRange?> show({
    required BuildContext context,
    required DateTime? planStartsAt,
    required DateTime? planEndsAt,
    required DateTime initialStart,
    required DateTime initialEnd,
    String title = '방문 시간 설정',
  }) {
    final bounds = _PlanVisitBounds.resolve(
      planStartsAt: planStartsAt,
      planEndsAt: planEndsAt,
      initialStart: initialStart,
      initialEnd: initialEnd,
    );

    return showModalBottomSheet<OnmuDateTimeRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _PlanVisitTimePickerSheet(
        title: title,
        bounds: bounds,
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );
  }
}

class _PlanVisitTimePickerSheet extends StatefulWidget {
  const _PlanVisitTimePickerSheet({
    required this.title,
    required this.bounds,
    required this.initialStart,
    required this.initialEnd,
  });

  final String title;
  final _PlanVisitBounds bounds;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_PlanVisitTimePickerSheet> createState() =>
      _PlanVisitTimePickerSheetState();
}

class _PlanVisitTimePickerSheetState extends State<_PlanVisitTimePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final normalized = widget.bounds.normalizedRange(
      start: widget.initialStart,
      end: widget.initialEnd,
    );
    _selectedDate = _dateOnly(normalized.start);
    _start = normalized.start;
    _end = normalized.end;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final startMaximum = widget.bounds.latestStartFor(_selectedDate);
    final endMinimum = widget.bounds.minimumEndFor(_start);
    final endMaximum = widget.bounds.dayEndFor(_selectedDate);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
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
                  _PlanDateButtonSection(
                    dates: widget.bounds.dates,
                    selectedDate: _selectedDate,
                    onDateSelected: _selectDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PlanVisitRangeSummary(start: _start, end: _end),
                  const SizedBox(height: AppSpacing.md),
                  OnmuSlidingTimePicker(
                    title: '방문 시작 시간',
                    selectedDateTime: _start,
                    minimumDateTime: widget.bounds.dayStartFor(_selectedDate),
                    maximumDateTime: startMaximum,
                    sliderKey: const ValueKey('plan-visit-start-time-slider'),
                    onChanged: _updateStart,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OnmuSlidingTimePicker(
                    title: '방문 종료 시간',
                    selectedDateTime: _end,
                    minimumDateTime: endMinimum,
                    maximumDateTime: endMaximum,
                    sliderKey: const ValueKey('plan-visit-end-time-slider'),
                    onChanged: _updateEnd,
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
                icon: Icons.check_rounded,
                color: AppColors.primaryPink,
                foregroundColor: AppColors.textInverse,
                onPressed: () => Navigator.of(context).pop(
                  OnmuDateTimeRange(start: _start.toUtc(), end: _end.toUtc()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectDate(DateTime date) {
    final previousDuration = _end.difference(_start);
    final nextStart = DateTime(
      date.year,
      date.month,
      date.day,
      _start.hour,
      _start.minute,
    );
    final normalized = widget.bounds.normalizedRange(
      start: nextStart,
      end: nextStart.add(previousDuration),
    );
    setState(() {
      _selectedDate = _dateOnly(date);
      _start = normalized.start;
      _end = normalized.end;
    });
  }

  void _updateStart(DateTime value) {
    final previousDuration = _end.difference(_start);
    final normalized = widget.bounds.normalizedRange(
      start: value,
      end: value.add(previousDuration),
    );
    setState(() {
      _selectedDate = _dateOnly(normalized.start);
      _start = normalized.start;
      _end = normalized.end;
    });
  }

  void _updateEnd(DateTime value) {
    setState(() {
      _end = widget.bounds.normalizedEnd(start: _start, end: value);
    });
  }
}

class _PlanDateButtonSection extends StatelessWidget {
  const _PlanDateButtonSection({
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '방문 날짜',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final date in dates)
                OnmuChip(
                  key: ValueKey(
                    'plan-visit-date-${date.year}-${date.month}-${date.day}',
                  ),
                  label: _dateButtonLabel(date),
                  selected: _isSameDate(date, selectedDate),
                  onTap: () => onDateSelected(date),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanVisitRangeSummary extends StatelessWidget {
  const _PlanVisitRangeSummary({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${_dateButtonLabel(start)} ${_clockLabel(start)} - ${_clockLabel(end)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanVisitBounds {
  const _PlanVisitBounds({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static const _minimumDuration = Duration(minutes: 30);

  static _PlanVisitBounds resolve({
    required DateTime? planStartsAt,
    required DateTime? planEndsAt,
    required DateTime initialStart,
    required DateTime initialEnd,
  }) {
    final fallbackStart = initialStart.toLocal();
    final fallbackEnd = initialEnd.isAfter(initialStart)
        ? initialEnd.toLocal()
        : fallbackStart.add(const Duration(hours: 1));
    final resolvedStart = (planStartsAt ?? fallbackStart).toLocal();
    final resolvedEnd = (planEndsAt ?? fallbackEnd).toLocal();
    if (resolvedEnd.isAfter(resolvedStart)) {
      return _PlanVisitBounds(start: resolvedStart, end: resolvedEnd);
    }
    return _PlanVisitBounds(
      start: resolvedStart,
      end: resolvedStart.add(const Duration(hours: 1)),
    );
  }

  List<DateTime> get dates {
    final result = <DateTime>[];
    var cursor = _dateOnly(start);
    final endDate = _dateOnly(end);
    while (!cursor.isAfter(endDate)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return List.unmodifiable(result);
  }

  ({DateTime start, DateTime end}) normalizedRange({
    required DateTime start,
    required DateTime end,
  }) {
    final selectedDate = _nearestDateInBounds(start);
    final normalizedStart = normalizedStartFor(selectedDate, start);
    final normalizedEnd = this.normalizedEnd(start: normalizedStart, end: end);
    return (start: normalizedStart, end: normalizedEnd);
  }

  DateTime normalizedStartFor(DateTime selectedDate, DateTime value) {
    final date = _nearestDateInBounds(selectedDate);
    final candidate = DateTime(
      date.year,
      date.month,
      date.day,
      value.hour,
      _roundedMinute(value.minute),
    );
    return _clampDateTime(candidate, dayStartFor(date), latestStartFor(date));
  }

  DateTime normalizedEnd({required DateTime start, required DateTime end}) {
    final dayEnd = dayEndFor(start);
    final minimumEnd = minimumEndFor(start);
    if (minimumEnd.isAfter(dayEnd)) {
      return dayEnd;
    }
    final candidate = DateTime(
      start.year,
      start.month,
      start.day,
      end.hour,
      _roundedMinute(end.minute),
    );
    return _clampDateTime(candidate, minimumEnd, dayEnd);
  }

  DateTime dayStartFor(DateTime date) {
    final selectedDate = _dateOnly(date);
    if (_isSameDate(selectedDate, start)) {
      return start;
    }
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  }

  DateTime dayEndFor(DateTime date) {
    final selectedDate = _dateOnly(date);
    if (_isSameDate(selectedDate, end)) {
      return end;
    }
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      55,
    );
  }

  DateTime latestStartFor(DateTime date) {
    final dayStart = dayStartFor(date);
    final dayEnd = dayEndFor(date);
    final latestStart = dayEnd.subtract(_minimumDuration);
    return latestStart.isBefore(dayStart) ? dayStart : latestStart;
  }

  DateTime minimumEndFor(DateTime start) {
    final dayEnd = dayEndFor(start);
    final minimumEnd = start.add(_minimumDuration);
    return minimumEnd.isAfter(dayEnd) ? start : minimumEnd;
  }

  DateTime _nearestDateInBounds(DateTime value) {
    final selectedDate = _dateOnly(value.toLocal());
    final firstDate = _dateOnly(start);
    final lastDate = _dateOnly(end);
    if (selectedDate.isBefore(firstDate)) {
      return firstDate;
    }
    if (selectedDate.isAfter(lastDate)) {
      return lastDate;
    }
    return selectedDate;
  }
}

DateTime _clampDateTime(DateTime value, DateTime minimum, DateTime maximum) {
  if (value.isBefore(minimum)) {
    return minimum;
  }
  if (value.isAfter(maximum)) {
    return maximum;
  }
  return value;
}

DateTime _dateOnly(DateTime dateTime) {
  final local = dateTime.toLocal();
  return DateTime(local.year, local.month, local.day);
}

int _roundedMinute(int minute) {
  return ((minute / 5).round() * 5).clamp(0, 55);
}

String _dateButtonLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.month}/${local.day} ${_weekdayLabel(local)}';
}

String _clockLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _weekdayLabel(DateTime dateTime) {
  return switch (dateTime.weekday) {
    DateTime.monday => '월',
    DateTime.tuesday => '화',
    DateTime.wednesday => '수',
    DateTime.thursday => '목',
    DateTime.friday => '금',
    DateTime.saturday => '토',
    DateTime.sunday => '일',
    _ => '',
  };
}

bool _isSameDate(DateTime left, DateTime right) {
  final leftLocal = left.toLocal();
  final rightLocal = right.toLocal();
  return leftLocal.year == rightLocal.year &&
      leftLocal.month == rightLocal.month &&
      leftLocal.day == rightLocal.day;
}
