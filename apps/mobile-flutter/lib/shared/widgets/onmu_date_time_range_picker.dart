import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_button.dart';
import 'onmu_card.dart';
import 'onmu_date_time_picker.dart';

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
  late DateTime _start;
  late DateTime _end;
  _DateFieldTarget? _expandedDateTarget;
  final _startCalendarKey = GlobalKey();
  final _endCalendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _start = _roundedToFiveMinutes(widget.initialStart);
    _end = _normalizedEnd(_start, widget.initialEnd);
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
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    _DateSummaryField(
                      label: '시작 날짜',
                      value: _formatDate(_start),
                      selected: _expandedDateTarget == _DateFieldTarget.start,
                      onTap: () => _toggleDateTarget(_DateFieldTarget.start),
                    ),
                    if (_expandedDateTarget == _DateFieldTarget.start) ...[
                      const SizedBox(height: AppSpacing.sm),
                      KeyedSubtree(
                        key: _startCalendarKey,
                        child: OnmuCalendarDatePicker(
                          selectedDate: _start,
                          minimumDate: _today(),
                          maximumDate: _today().add(const Duration(days: 365)),
                          highlightedDates: _recommendedDatesAround(_start),
                          onDateChanged: (date) => setState(() {
                            _updateStartDate(date);
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _DateSummaryField(
                      label: '종료 날짜',
                      value: _formatDate(_end),
                      selected: _expandedDateTarget == _DateFieldTarget.end,
                      onTap: () => _toggleDateTarget(_DateFieldTarget.end),
                    ),
                    if (_expandedDateTarget == _DateFieldTarget.end) ...[
                      const SizedBox(height: AppSpacing.sm),
                      KeyedSubtree(
                        key: _endCalendarKey,
                        child: OnmuCalendarDatePicker(
                          selectedDate: _end,
                          minimumDate: _start,
                          maximumDate: _start.add(const Duration(days: 365)),
                          highlightedDates: _recommendedDatesAround(_start),
                          onDateChanged: (date) => setState(() {
                            _updateEndDate(date);
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    OnmuTimeChipPicker(
                      title: '시작 시간',
                      selectedDateTime: _start,
                      minimumDateTime: _today(),
                      maximumDateTime: _today().add(const Duration(days: 365)),
                      onChanged: (value) => setState(() {
                        _updateStart(_roundedToFiveMinutes(value));
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OnmuTimeChipPicker(
                      title: '종료 시간',
                      selectedDateTime: _end,
                      minimumDateTime: _start.add(const Duration(minutes: 30)),
                      maximumDateTime: _start.add(const Duration(days: 1)),
                      onChanged: (value) => setState(() {
                        _end = _normalizedEnd(_start, value);
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '추천/비추천 시간대',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final recommendation in _timeRecommendations) ...[
                      _TimeRecommendationTile(
                        recommendation: recommendation,
                        selected: recommendation.matches(_start),
                        onTap: () => setState(() {
                          final date = DateTime(
                            _start.year,
                            _start.month,
                            _start.day,
                          );
                          _start = date.add(
                            Duration(
                              hours: recommendation.hour,
                              minutes: recommendation.minute,
                            ),
                          );
                          _end = _start.add(
                            Duration(hours: recommendation.durationHours),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
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

  void _updateStart(DateTime nextStart) {
    final previousDuration = _end.difference(_start);
    _start = _roundedToFiveMinutes(nextStart);
    _end = _start.add(
      previousDuration.isNegative || previousDuration.inMinutes < 30
          ? const Duration(hours: 1)
          : previousDuration,
    );
  }

  void _updateStartDate(DateTime date) {
    final nextStart = DateTime(
      date.year,
      date.month,
      date.day,
      _start.hour,
      _start.minute,
    );
    _start = _roundedToFiveMinutes(nextStart);
    if (!_end.isAfter(_start)) {
      _end = _start.add(const Duration(hours: 1));
    }
  }

  void _updateEndDate(DateTime date) {
    final nextEnd = DateTime(
      date.year,
      date.month,
      date.day,
      _end.hour,
      _end.minute,
    );
    _end = _normalizedEnd(_start, nextEnd);
  }

  void _toggleDateTarget(_DateFieldTarget target) {
    final willOpen = _expandedDateTarget != target;
    setState(() {
      _expandedDateTarget = willOpen ? target : null;
    });

    if (!willOpen) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarContext = switch (target) {
        _DateFieldTarget.start => _startCalendarKey.currentContext,
        _DateFieldTarget.end => _endCalendarKey.currentContext,
      };
      if (calendarContext == null || !mounted) {
        return;
      }
      Scrollable.ensureVisible(
        calendarContext,
        alignment: 0.12,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }
}

enum _DateFieldTarget { start, end }

class _DateSummaryField extends StatelessWidget {
  const _DateSummaryField({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: Icons.calendar_month_outlined, title: label),
            const SizedBox(height: AppSpacing.sm),
            OnmuCard(
              backgroundColor: selected
                  ? AppColors.bgPurpleSoft
                  : AppColors.bgDefault,
              borderColor: selected ? AppColors.linePink : AppColors.lineSoft,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    selected ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationStatusLabel extends StatelessWidget {
  const _RecommendationStatusLabel({
    required this.recommendation,
    super.key,
    this.compact = false,
  });

  final _TimeRecommendation recommendation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final recommended = recommendation.isRecommended;
    final color = recommended ? AppColors.accentGreen : AppColors.accentRed;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          recommended
              ? compact
                    ? '추천 시간대'
                    : '참여자 추천 시간대'
              : '비추천 시간대',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _TimeRecommendationTile extends StatelessWidget {
  const _TimeRecommendationTile({
    required this.recommendation,
    required this.selected,
    required this.onTap,
  });

  final _TimeRecommendation recommendation;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star_rounded, color: recommendation.statusColor),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 74,
            child: Text(
              '${_formatClock(recommendation.hour, recommendation.minute)}\n~ ${_formatClock(recommendation.hour + recommendation.durationHours, recommendation.minute)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RecommendationStatusLabel(
                      key: ValueKey(
                        'time-recommendation-tile-status-${recommendation.hour}-${recommendation.minute}',
                      ),
                      recommendation: recommendation,
                      compact: true,
                    ),
                    Text(
                      recommendation.availability,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: recommendation.statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _TimeRecommendation {
  const _TimeRecommendation({
    required this.hour,
    required this.minute,
    required this.durationHours,
    required this.label,
    required this.preferredCount,
    required this.unavailableCount,
  });

  final int hour;
  final int minute;
  final int durationHours;
  final String label;
  final int preferredCount;
  final int unavailableCount;

  bool get isRecommended => preferredCount > unavailableCount;

  String get availability => '$preferredCount명 추천';

  Color get statusColor =>
      isRecommended ? AppColors.accentGreen : AppColors.accentRed;

  bool matches(DateTime dateTime) {
    return dateTime.hour == hour && dateTime.minute == minute;
  }
}

const _timeRecommendations = [
  _TimeRecommendation(
    hour: 12,
    minute: 0,
    durationHours: 2,
    label: '점심부터 여유롭게 시작할 수 있어요.',
    preferredCount: 3,
    unavailableCount: 0,
  ),
  _TimeRecommendation(
    hour: 13,
    minute: 0,
    durationHours: 2,
    label: '가장 많이 선택되는 시간대예요.',
    preferredCount: 4,
    unavailableCount: 1,
  ),
  _TimeRecommendation(
    hour: 14,
    minute: 0,
    durationHours: 2,
    label: '일부 멤버가 피하고 싶은 시간대예요.',
    preferredCount: 1,
    unavailableCount: 3,
  ),
  _TimeRecommendation(
    hour: 19,
    minute: 0,
    durationHours: 2,
    label: '퇴근 후 저녁 약속에 맞아요.',
    preferredCount: 1,
    unavailableCount: 2,
  ),
];

DateTime _normalizedEnd(DateTime start, DateTime end) {
  final roundedEnd = _roundedToFiveMinutes(end);
  if (roundedEnd.isAfter(start)) {
    return roundedEnd;
  }
  return start.add(const Duration(hours: 1));
}

DateTime _roundedToFiveMinutes(DateTime dateTime) {
  final minute = (dateTime.minute / 5).round() * 5;
  if (minute == 60) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour + 1,
    );
  }
  return DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour,
    minute,
  );
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<DateTime> _recommendedDatesAround(DateTime anchor) {
  final date = DateTime(anchor.year, anchor.month, anchor.day);
  return [
    date,
    date.add(const Duration(days: 2)),
    date.add(const Duration(days: 7)),
  ];
}

String _formatDate(DateTime date) {
  return '${date.month}월 ${date.day}일 (${_weekday(date)})';
}

String _formatClock(int hour, int minute) {
  final normalizedHour = hour % 24;
  return '${normalizedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _weekday(DateTime date) {
  return const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
}
