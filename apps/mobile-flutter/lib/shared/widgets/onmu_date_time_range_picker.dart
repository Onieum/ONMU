import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../models/preference_profile.dart';
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
    List<PreferenceProfile> participantPreferences = const [],
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
        initialStart: initialStart.toLocal(),
        initialEnd: initialEnd.isAfter(initialStart)
            ? initialEnd.toLocal()
            : initialStart.toLocal().add(const Duration(hours: 2)),
        participantPreferences: participantPreferences,
      ),
    );
  }
}

class _DateTimeRangePickerSheet extends StatefulWidget {
  const _DateTimeRangePickerSheet({
    required this.title,
    required this.initialStart,
    required this.initialEnd,
    required this.participantPreferences,
  });

  final String title;
  final DateTime initialStart;
  final DateTime initialEnd;
  final List<PreferenceProfile> participantPreferences;

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
  late final DateTime _recommendationAnchor;

  @override
  void initState() {
    super.initState();
    _start = _roundedToFiveMinutes(widget.initialStart);
    _end = _normalizedEnd(_start, widget.initialEnd);
    final today = _today();
    _recommendationAnchor = _dateOnly(_start).isBefore(today)
        ? today
        : _dateOnly(_start);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final recommendedDates = onmuRecommendedDatesForRangePicker(
      anchor: _recommendationAnchor,
      participantPreferences: widget.participantPreferences,
    );
    final multiDayRange = !_sameDate(_start, _end);
    final visibleRecommendedDates = multiDayRange
        ? _recommendedDatesInRange(recommendedDates, start: _start, end: _end)
        : recommendedDates;
    final recommendationResult = _timeRecommendationResult(
      selectedDate: _start,
      participantPreferences: widget.participantPreferences,
    );

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
                    if (visibleRecommendedDates.isNotEmpty) ...[
                      _RecommendedDateSection(
                        title: multiDayRange ? '선택 범위의 추천 방문일' : '추천 날짜',
                        recommendedDates: visibleRecommendedDates,
                        selectedDate: _start,
                        onDateSelected: multiDayRange
                            ? null
                            : (date) => setState(() {
                                _updateStartDate(date);
                              }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _DateSummaryField(
                      label: '시작 날짜',
                      value: _formatDate(_start),
                      timeValue: _formatClock(_start.hour, _start.minute),
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
                          highlightedDates: recommendedDates,
                          onDateChanged: (date) => setState(() {
                            _updateStartDate(date);
                          }),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OnmuSlidingTimePicker(
                        title: '시작 시간',
                        selectedDateTime: _start,
                        minimumDateTime: _today(),
                        maximumDateTime: _today().add(
                          const Duration(days: 365),
                        ),
                        sliderKey: const ValueKey('start-time-slider'),
                        onChanged: (value) => setState(() {
                          _updateStart(_roundedToFiveMinutes(value));
                        }),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _DateSummaryField(
                      label: '종료 날짜',
                      value: _formatDate(_end),
                      timeValue: _formatClock(_end.hour, _end.minute),
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
                          highlightedDates: const [],
                          onDateChanged: (date) => setState(() {
                            _updateEndDate(date);
                          }),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OnmuSlidingTimePicker(
                        title: '종료 시간',
                        selectedDateTime: _end,
                        minimumDateTime: _start.add(
                          const Duration(minutes: 30),
                        ),
                        maximumDateTime: _start.add(const Duration(days: 1)),
                        sliderKey: const ValueKey('end-time-slider'),
                        onChanged: (value) => setState(() {
                          _end = _normalizedEnd(_start, value);
                        }),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      multiDayRange ? '시작 날짜의 추천 시간대' : '선택한 날짜의 추천 시간대',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (recommendationResult.notice != null) ...[
                      _RecommendationNotice(text: recommendationResult.notice!),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    for (final recommendation
                        in recommendationResult.recommendations) ...[
                      _TimeRecommendationTile(
                        recommendation: recommendation,
                        selected: recommendation.matches(_start, _end),
                        onTap: () => setState(() {
                          _start = recommendation.start;
                          _end = recommendation.end;
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

class _RecommendedDateSection extends StatelessWidget {
  const _RecommendedDateSection({
    required this.title,
    required this.recommendedDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final String title;
  final List<DateTime> recommendedDates;
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.star_border_rounded, title: title),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final date in recommendedDates)
              _RecommendedDateChip(
                date: date,
                selected:
                    onDateSelected != null && _sameDate(selectedDate, date),
                onTap: onDateSelected == null
                    ? null
                    : () => onDateSelected!(date),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecommendedDateChip extends StatelessWidget {
  const _RecommendedDateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryPink : AppColors.accentGreen;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              _formatDate(date),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _DateSummaryField extends StatelessWidget {
  const _DateSummaryField({
    required this.label,
    required this.value,
    required this.timeValue,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final String timeValue;
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
                  const SizedBox(width: AppSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryPinkSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.linePink),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        timeValue,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primaryPurpleDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
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

class _RecommendationNotice extends StatelessWidget {
  const _RecommendationNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentBrown),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
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
          recommendation.statusLabel(compact: compact),
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
          Icon(recommendation.statusIcon, color: recommendation.statusColor),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 108,
            child: Text(
              '${_formatClock(recommendation.hour, recommendation.minute)} ~ ${_formatClock(recommendation.end.hour, recommendation.end.minute)}',
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
                    if (recommendation.availability.isNotEmpty)
                      Text(
                        recommendation.availability,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: recommendation.statusColor),
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
    required this.start,
    required this.duration,
    required this.label,
    required this.preferredCount,
    required this.unavailableCount,
    required this.isRecommended,
    this.generic = false,
  });

  final DateTime start;
  final Duration duration;
  final String label;
  final int preferredCount;
  final int unavailableCount;
  final bool isRecommended;
  final bool generic;

  int get hour => start.hour;

  int get minute => start.minute;

  DateTime get end => start.add(duration);

  int get durationHours => duration.inHours;

  String get availability =>
      generic ? '' : '$preferredCount명 선호, $unavailableCount명 비선호';

  IconData get statusIcon =>
      isRecommended ? Icons.star_rounded : Icons.close_rounded;

  Color get statusColor =>
      isRecommended ? AppColors.accentGreen : AppColors.accentRed;

  String statusLabel({required bool compact}) {
    if (isRecommended) {
      if (generic) {
        return '일반 추천';
      }
      return compact ? '추천 시간대' : '참여자 추천 시간대';
    }
    return '불가능 시간대';
  }

  bool matches(DateTime selectedStart, DateTime selectedEnd) {
    return _sameDate(selectedStart, start) &&
        selectedStart.hour == hour &&
        selectedStart.minute == minute &&
        _sameDate(selectedEnd, end) &&
        selectedEnd.hour == end.hour &&
        selectedEnd.minute == end.minute;
  }
}

class _TimeRecommendationResult {
  const _TimeRecommendationResult({required this.recommendations, this.notice});

  final List<_TimeRecommendation> recommendations;
  final String? notice;
}

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

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<DateTime> _recommendedDatesInRange(
  List<DateTime> dates, {
  required DateTime start,
  required DateTime end,
}) {
  final startDate = _dateOnly(start);
  final endDate = _dateOnly(end);
  return dates
      .where((date) {
        final current = _dateOnly(date);
        return !current.isBefore(startDate) && !current.isAfter(endDate);
      })
      .toList(growable: false);
}

@visibleForTesting
List<DateTime> onmuRecommendedDatesForRangePicker({
  required DateTime anchor,
  required List<PreferenceProfile> participantPreferences,
  int dayCount = 30,
}) {
  final profiles = participantPreferences
      .where(
        (profile) =>
            profile.preferredWeekdays.isNotEmpty ||
            profile.unavailableDates.isNotEmpty,
      )
      .toList(growable: false);
  if (profiles.isEmpty || dayCount <= 0) {
    return const [];
  }

  final anchorDate = _dateOnly(anchor);
  final candidates = <_DateRecommendation>[];
  for (var dayOffset = 0; dayOffset < dayCount; dayOffset += 1) {
    final date = anchorDate.add(Duration(days: dayOffset));
    final unavailableCount = participantPreferences
        .where((profile) => _profileUnavailableOn(profile, date))
        .length;
    if (unavailableCount >= participantPreferences.length) {
      continue;
    }
    final preferredCount = participantPreferences
        .where((profile) => _profileExplicitlyPrefersWeekday(profile, date))
        .length;
    if (preferredCount == 0) {
      continue;
    }
    candidates.add(
      _DateRecommendation(
        date: date,
        preferredCount: preferredCount,
        unavailableCount: unavailableCount,
      ),
    );
  }

  candidates.sort((a, b) {
    final unavailableCompare = a.unavailableCount.compareTo(b.unavailableCount);
    if (unavailableCompare != 0) {
      return unavailableCompare;
    }
    final preferredCompare = b.preferredCount.compareTo(a.preferredCount);
    if (preferredCompare != 0) {
      return preferredCompare;
    }
    return a.date.compareTo(b.date);
  });

  return _uniqueDates(candidates.take(4).map((candidate) => candidate.date));
}

_TimeRecommendationResult _timeRecommendationResult({
  required DateTime selectedDate,
  required List<PreferenceProfile> participantPreferences,
}) {
  final preferenceProfiles = participantPreferences
      .where((profile) => _hasPreferredTimeData(profile))
      .toList(growable: false);
  if (preferenceProfiles.isEmpty) {
    return _fallbackTimeRecommendationResult(selectedDate);
  }

  final slotStarts = _preferredSlotStarts(preferenceProfiles);
  if (slotStarts.isEmpty) {
    return _fallbackTimeRecommendationResult(selectedDate);
  }

  final date = _dateOnly(selectedDate);
  final recommendations = <_TimeRecommendation>[];
  for (final slotStart in slotStarts) {
    final preferredCount = preferenceProfiles
        .where((profile) => _profilePrefersSlot(profile, date, slotStart))
        .length;
    if (preferredCount == 0) {
      continue;
    }
    final unavailableCount = participantPreferences
        .where((profile) => _profileUnavailableOn(profile, date))
        .length;
    if (unavailableCount == participantPreferences.length) {
      continue;
    }
    final everyonePreferred =
        preferredCount == preferenceProfiles.length && unavailableCount == 0;
    recommendations.add(
      _TimeRecommendation(
        start: DateTime(
          date.year,
          date.month,
          date.day,
          slotStart.hour,
          slotStart.minute,
        ),
        duration: const Duration(hours: 2),
        label: everyonePreferred ? '모두가 선호한 시간대예요.' : '선호가 가장 많이 겹치는 시간대예요.',
        preferredCount: preferredCount,
        unavailableCount: unavailableCount,
        isRecommended: everyonePreferred,
      ),
    );
  }

  if (recommendations.isEmpty) {
    return _fallbackTimeRecommendationResult(selectedDate);
  }

  recommendations.sort((a, b) {
    final recommendedCompare = (b.isRecommended ? 1 : 0).compareTo(
      a.isRecommended ? 1 : 0,
    );
    if (recommendedCompare != 0) {
      return recommendedCompare;
    }
    final preferredCompare = b.preferredCount.compareTo(a.preferredCount);
    if (preferredCompare != 0) {
      return preferredCompare;
    }
    final unavailableCompare = a.unavailableCount.compareTo(b.unavailableCount);
    if (unavailableCompare != 0) {
      return unavailableCompare;
    }
    return a.start.compareTo(b.start);
  });

  final selectedRecommendations = recommendations.take(4).toList();
  final hasEveryonePreferred = recommendations.any(
    (recommendation) => recommendation.isRecommended,
  );
  return _TimeRecommendationResult(
    recommendations: selectedRecommendations,
    notice: hasEveryonePreferred ? null : '모두가 가능한 시간대가 없었음',
  );
}

_TimeRecommendationResult _fallbackTimeRecommendationResult(DateTime anchor) {
  final date = DateTime(anchor.year, anchor.month, anchor.day);
  final recommendations = [
    _fallbackTimeRecommendation(
      date: date,
      hour: 12,
      label: '점심부터 여유롭게 시작할 수 있어요.',
    ),
    _fallbackTimeRecommendation(
      date: date,
      hour: 13,
      label: '가장 많이 선택되는 시간대예요.',
    ),
    _fallbackTimeRecommendation(date: date, hour: 14, label: '오후 일정으로 잡기 좋아요.'),
    _fallbackTimeRecommendation(
      date: date,
      hour: 19,
      label: '퇴근 후 저녁 약속에 맞아요.',
    ),
  ];
  return _TimeRecommendationResult(recommendations: recommendations);
}

_TimeRecommendation _fallbackTimeRecommendation({
  required DateTime date,
  required int hour,
  required String label,
}) {
  return _TimeRecommendation(
    start: DateTime(date.year, date.month, date.day, hour),
    duration: const Duration(hours: 2),
    label: label,
    preferredCount: 0,
    unavailableCount: 0,
    isRecommended: true,
    generic: true,
  );
}

bool _hasPreferredTimeData(PreferenceProfile profile) {
  return profile.preferredTimes.any(
    (value) => _slotStartsForPreference(value).isNotEmpty,
  );
}

List<_SlotStart> _preferredSlotStarts(List<PreferenceProfile> profiles) {
  final seen = <int>{};
  final slots = <_SlotStart>[];
  for (final profile in profiles) {
    for (final value in profile.preferredTimes) {
      for (final slot in _slotStartsForPreference(value)) {
        final key = slot.hour * 60 + slot.minute;
        if (seen.add(key)) {
          slots.add(slot);
        }
      }
    }
  }
  slots.sort(
    (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
  );
  return slots;
}

bool _profilePrefersSlot(
  PreferenceProfile profile,
  DateTime date,
  _SlotStart slot,
) {
  if (!_profilePrefersWeekday(profile, date.weekday)) {
    return false;
  }
  return profile.preferredTimes.any(
    (value) => _slotStartsForPreference(value).contains(slot),
  );
}

bool _profilePrefersWeekday(PreferenceProfile profile, int weekday) {
  final weekdays = profile.preferredWeekdays
      .map(_weekdayNumberFromPreference)
      .whereType<int>()
      .toSet();
  if (weekdays.isEmpty) {
    return true;
  }
  return weekdays.contains(weekday);
}

bool _profileExplicitlyPrefersWeekday(
  PreferenceProfile profile,
  DateTime date,
) {
  return profile.preferredWeekdays
      .map(_weekdayNumberFromPreference)
      .whereType<int>()
      .contains(date.weekday);
}

bool _profileUnavailableOn(PreferenceProfile profile, DateTime date) {
  return profile.unavailableDates.any(
    (value) => _sameUnavailableDate(value, date),
  );
}

List<_SlotStart> _slotStartsForPreference(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized.contains('결정')) {
    return const [];
  }

  final parsedTime = _parseClockPreference(normalized);
  if (parsedTime != null) {
    return [parsedTime];
  }

  if (normalized == 'morning' || normalized.contains('오전')) {
    return const [_SlotStart(9, 0), _SlotStart(10, 0)];
  }
  if (normalized == 'lunch' || normalized.contains('점심')) {
    return const [_SlotStart(12, 0), _SlotStart(13, 0)];
  }
  if (normalized == 'afternoon' || normalized.contains('오후')) {
    return const [_SlotStart(14, 0), _SlotStart(16, 0)];
  }
  if (normalized == 'evening' ||
      normalized.contains('저녁') ||
      normalized.contains('night')) {
    return const [_SlotStart(19, 0), _SlotStart(20, 0)];
  }
  return const [];
}

_SlotStart? _parseClockPreference(String value) {
  final match = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(value);
  if (match == null) {
    return null;
  }
  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
  if (hour == null || hour > 23 || minute > 59) {
    return null;
  }
  if ((value.contains('오후') || value.contains('pm')) && hour < 12) {
    hour += 12;
  }
  if ((value.contains('오전') || value.contains('am')) && hour == 12) {
    hour = 0;
  }
  return _SlotStart(hour, minute);
}

int? _weekdayNumberFromPreference(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    '월' || '월요일' || 'mon' || 'monday' => 1,
    '화' || '화요일' || 'tue' || 'tuesday' => 2,
    '수' || '수요일' || 'wed' || 'wednesday' => 3,
    '목' || '목요일' || 'thu' || 'thursday' => 4,
    '금' || '금요일' || 'fri' || 'friday' => 5,
    '토' || '토요일' || 'sat' || 'saturday' => 6,
    '일' || '일요일' || 'sun' || 'sunday' => 7,
    _ => null,
  };
}

bool _sameUnavailableDate(String value, DateTime date) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed != null) {
    return _sameDate(parsed.toLocal(), date);
  }

  final match = RegExp(r'(\d{1,2})[/-](\d{1,2})').firstMatch(value);
  if (match == null) {
    return false;
  }
  final month = int.tryParse(match.group(1) ?? '');
  final day = int.tryParse(match.group(2) ?? '');
  return month == date.month && day == date.day;
}

List<DateTime> _uniqueDates(Iterable<DateTime> values) {
  final seen = <String>{};
  final dates = <DateTime>[];
  for (final value in values) {
    final date = DateTime(value.year, value.month, value.day);
    final key = '${date.year}-${date.month}-${date.day}';
    if (seen.add(key)) {
      dates.add(date);
    }
  }
  return dates;
}

class _DateRecommendation {
  const _DateRecommendation({
    required this.date,
    required this.preferredCount,
    required this.unavailableCount,
  });

  final DateTime date;
  final int preferredCount;
  final int unavailableCount;
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SlotStart {
  const _SlotStart(this.hour, this.minute);

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) {
    return other is _SlotStart && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
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
