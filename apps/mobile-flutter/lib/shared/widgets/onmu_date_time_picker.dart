import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_button.dart';
import 'onmu_chip.dart';

class OnmuDateTimePicker {
  const OnmuDateTimePicker._();

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDateTime,
    String title = '날짜와 시간 선택',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) =>
          _DateTimePickerSheet(initialDateTime: initialDateTime, title: title),
    );
  }
}

class _DateTimePickerSheet extends StatefulWidget {
  const _DateTimePickerSheet({
    required this.initialDateTime,
    required this.title,
  });

  final DateTime initialDateTime;
  final String title;

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _selectedDateTime = widget.initialDateTime;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.74,
      minChildSize: 0.54,
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
                  OnmuCalendarDateTimeSelector(
                    selectedDateTime: _selectedDateTime,
                    minimumDate: DateTime.now().subtract(
                      const Duration(days: 1),
                    ),
                    maximumDate: DateTime.now().add(const Duration(days: 365)),
                    onChanged: (value) {
                      setState(() => _selectedDateTime = value);
                    },
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
                onPressed: () => Navigator.of(context).pop(_selectedDateTime),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnmuCalendarDateTimeSelector extends StatelessWidget {
  const OnmuCalendarDateTimeSelector({
    required this.selectedDateTime,
    required this.onChanged,
    super.key,
    this.minimumDate,
    this.maximumDate,
    this.calendarTitle = '날짜 선택',
    this.timeTitle = '시간 선택',
  });

  final DateTime selectedDateTime;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final String calendarTitle;
  final String timeTitle;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnmuCalendarDatePicker(
          selectedDate: selectedDateTime,
          minimumDate: minimumDate,
          maximumDate: maximumDate,
          title: calendarTitle,
          onDateChanged: (date) {
            onChanged(
              _clampDateTime(
                DateTime(
                  date.year,
                  date.month,
                  date.day,
                  selectedDateTime.hour,
                  selectedDateTime.minute,
                ),
                minimumDate,
                maximumDate,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        OnmuTimeChipPicker(
          title: timeTitle,
          selectedDateTime: selectedDateTime,
          minimumDateTime: minimumDate,
          maximumDateTime: maximumDate,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class OnmuCalendarDatePicker extends StatefulWidget {
  const OnmuCalendarDatePicker({
    required this.selectedDate,
    required this.onDateChanged,
    super.key,
    this.minimumDate,
    this.maximumDate,
    this.highlightedDates = const [],
    this.title = '날짜 선택',
  });

  final DateTime selectedDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final List<DateTime> highlightedDates;
  final String title;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<OnmuCalendarDatePicker> createState() => _OnmuCalendarDatePickerState();
}

class _OnmuCalendarDatePickerState extends State<OnmuCalendarDatePicker> {
  late DateTime _visibleMonth = _monthOf(widget.selectedDate);

  @override
  void didUpdateWidget(covariant OnmuCalendarDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedMonth = _monthOf(widget.selectedDate);
    if (!_sameMonth(selectedMonth, _visibleMonth)) {
      _visibleMonth = selectedMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final firstWeekday = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
    ).weekday;
    final cells = <Widget>[
      for (var index = 1; index < firstWeekday; index += 1)
        const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day += 1)
        _CalendarDayCell(
          date: DateTime(_visibleMonth.year, _visibleMonth.month, day),
          selected: _sameDate(
            DateTime(_visibleMonth.year, _visibleMonth.month, day),
            widget.selectedDate,
          ),
          today: _sameDate(
            DateTime(_visibleMonth.year, _visibleMonth.month, day),
            DateTime.now(),
          ),
          highlighted: widget.highlightedDates.any(
            (date) => _sameDate(
              date,
              DateTime(_visibleMonth.year, _visibleMonth.month, day),
            ),
          ),
          enabled: _isSelectable(
            DateTime(_visibleMonth.year, _visibleMonth.month, day),
          ),
          onTap: () => widget.onDateChanged(
            DateTime(_visibleMonth.year, _visibleMonth.month, day),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: AppColors.primaryPink),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.lineWarm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '이전 달',
                      onPressed: _canMoveToPreviousMonth()
                          ? () => setState(
                              () => _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_visibleMonth.year}년 ${_visibleMonth.month}월',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '다음 달',
                      onPressed: _canMoveToNextMonth()
                          ? () => setState(
                              () => _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (final weekday in const [
                      '월',
                      '화',
                      '수',
                      '목',
                      '금',
                      '토',
                      '일',
                    ])
                      Expanded(
                        child: Center(
                          child: Text(
                            weekday,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.textSub),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final childAspectRatio = constraints.maxWidth > 520
                        ? 1.8
                        : 1.0;

                    return GridView.count(
                      crossAxisCount: 7,
                      childAspectRatio: childAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.xxs,
                      crossAxisSpacing: AppSpacing.xxs,
                      children: cells,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isSelectable(DateTime date) {
    final day = DateUtils.dateOnly(date);
    final minimum = widget.minimumDate == null
        ? null
        : DateUtils.dateOnly(widget.minimumDate!);
    final maximum = widget.maximumDate == null
        ? null
        : DateUtils.dateOnly(widget.maximumDate!);

    if (minimum != null && day.isBefore(minimum)) {
      return false;
    }
    if (maximum != null && day.isAfter(maximum)) {
      return false;
    }
    return true;
  }

  bool _canMoveToPreviousMonth() {
    final minimum = widget.minimumDate;
    if (minimum == null) {
      return true;
    }
    return _monthOf(_visibleMonth).isAfter(_monthOf(minimum));
  }

  bool _canMoveToNextMonth() {
    final maximum = widget.maximumDate;
    if (maximum == null) {
      return true;
    }
    return _monthOf(_visibleMonth).isBefore(_monthOf(maximum));
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = !enabled
        ? AppColors.textMuted.withValues(alpha: 0.48)
        : selected
        ? AppColors.primaryPurpleDark
        : AppColors.textMain;

    return Semantics(
      button: enabled,
      selected: selected,
      label: '${date.month}월 ${date.day}일 ${_weekday(date)}요일',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: selected
                    ? AppColors.linePink
                    : today
                    ? AppColors.lineBrown
                    : AppColors.lineSoft,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${date.day}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: textColor),
                  ),
                ),
                if (highlighted)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: enabled
                          ? AppColors.accentOrange
                          : AppColors.textMuted,
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

class OnmuTimeChipPicker extends StatelessWidget {
  const OnmuTimeChipPicker({
    required this.title,
    required this.selectedDateTime,
    required this.onChanged,
    super.key,
    this.minimumDateTime,
    this.maximumDateTime,
    this.hourOptions = const [
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
    ],
    this.minuteOptions = const [0, 30],
  });

  final String title;
  final DateTime selectedDateTime;
  final DateTime? minimumDateTime;
  final DateTime? maximumDateTime;
  final List<int> hourOptions;
  final List<int> minuteOptions;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final hours = _optionsIncluding(hourOptions, selectedDateTime.hour);
    final minutes = _optionsIncluding(minuteOptions, selectedDateTime.minute);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.primaryPink),
            const SizedBox(width: AppSpacing.xs),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              '시',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
            ),
            for (final hour in hours)
              OnmuChip(
                label: '${hour.toString().padLeft(2, '0')}:00',
                selected: selectedDateTime.hour == hour,
                onTap: () => onChanged(
                  _clampDateTime(
                    DateTime(
                      selectedDateTime.year,
                      selectedDateTime.month,
                      selectedDateTime.day,
                      hour,
                      selectedDateTime.minute,
                    ),
                    minimumDateTime,
                    maximumDateTime,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              '분',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
            ),
            for (final minute in minutes)
              OnmuChip(
                label: '${minute.toString().padLeft(2, '0')}분',
                selected: selectedDateTime.minute == minute,
                onTap: () => onChanged(
                  _clampDateTime(
                    DateTime(
                      selectedDateTime.year,
                      selectedDateTime.month,
                      selectedDateTime.day,
                      selectedDateTime.hour,
                      minute,
                    ),
                    minimumDateTime,
                    maximumDateTime,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

List<int> _optionsIncluding(List<int> options, int selectedValue) {
  final values = {...options, selectedValue}.toList()..sort();
  return values;
}

DateTime _clampDateTime(
  DateTime value,
  DateTime? minimumDateTime,
  DateTime? maximumDateTime,
) {
  if (minimumDateTime != null && value.isBefore(minimumDateTime)) {
    return minimumDateTime;
  }
  if (maximumDateTime != null && value.isAfter(maximumDateTime)) {
    return maximumDateTime;
  }
  return value;
}

DateTime _monthOf(DateTime date) {
  return DateTime(date.year, date.month);
}

bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _sameMonth(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month;
}

String _weekday(DateTime date) {
  return const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
}
