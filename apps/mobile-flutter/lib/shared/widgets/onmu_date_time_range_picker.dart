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

class ParticipantSchedulePreference {
  const ParticipantSchedulePreference({
    required this.userId,
    required this.name,
    required this.preferenceProfile,
  });

  final String userId;
  final String name;
  final PreferenceProfile preferenceProfile;
}

class OnmuDateTimeRangePicker {
  const OnmuDateTimeRangePicker._();

  static Future<OnmuDateTimeRange?> show({
    required BuildContext context,
    required DateTime initialStart,
    required DateTime initialEnd,
    String title = '날짜와 시간 선택',
    List<ParticipantSchedulePreference> participantPreferences = const [],
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
  final List<ParticipantSchedulePreference> participantPreferences;

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
    final dateRecommendations = _dateRecommendationsForRangePicker(
      anchor: _recommendationAnchor,
      participantPreferences: widget.participantPreferences,
    );
    final recommendedDates = dateRecommendations
        .map((recommendation) => recommendation.date)
        .toList(growable: false);
    final multiDayRange = !_sameDate(_start, _end);
    final visibleDateRecommendations = multiDayRange
        ? _dateRecommendationsInRange(
            dateRecommendations,
            start: _start,
            end: _end,
          )
        : dateRecommendations;
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
                    if (visibleDateRecommendations.isNotEmpty) ...[
                      _RecommendedDateSection(
                        title: multiDayRange ? '선택 범위의 추천 방문일' : '추천 날짜',
                        recommendations: visibleDateRecommendations,
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
    required this.recommendations,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final String title;
  final List<_DateRecommendation> recommendations;
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.star_border_rounded, title: title),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final recommendation in recommendations)
                  SizedBox(
                    width: itemWidth.clamp(140.0, constraints.maxWidth),
                    child: _RecommendedDateChip(
                      key: ValueKey(
                        'recommended-date-${_dateKey(recommendation.date)}',
                      ),
                      recommendation: recommendation,
                      selected:
                          onDateSelected != null &&
                          _sameDate(selectedDate, recommendation.date),
                      onTap: onDateSelected == null
                          ? null
                          : () => onDateSelected!(recommendation.date),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecommendedDateChip extends StatelessWidget {
  const _RecommendedDateChip({
    super.key,
    required this.recommendation,
    required this.selected,
    required this.onTap,
  });

  final _DateRecommendation recommendation;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primaryPink
        : recommendation.hasConflict
        ? AppColors.accentOrange
        : AppColors.accentGreen;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color),
      ),
      child: SizedBox(
        height: 78,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: color),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      _formatDate(recommendation.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.preferredLabel.isEmpty
                    ? '선호 정보 확인 중'
                    : recommendation.preferredLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: color),
              ),
              const Spacer(),
              if (recommendation.unavailableLabel.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        recommendation.unavailableLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 13),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                if (recommendation.generic ||
                    recommendation.availability.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (recommendation.generic)
                        Text(
                          '제안',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: recommendation.statusColor),
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
    required this.preferredNames,
    required this.unavailableNames,
    required this.isRecommended,
    this.generic = false,
  });

  final DateTime start;
  final Duration duration;
  final String label;
  final List<String> preferredNames;
  final List<String> unavailableNames;
  final bool isRecommended;
  final bool generic;

  int get hour => start.hour;

  int get minute => start.minute;

  DateTime get end => start.add(duration);

  int get durationHours => duration.inHours;

  int get preferredCount => preferredNames.length;

  int get unavailableCount => unavailableNames.length;

  bool get hasConflict => unavailableNames.isNotEmpty;

  String get availability => _unavailableNamesSummary(unavailableNames);

  IconData get statusIcon {
    if (generic) {
      return Icons.auto_awesome;
    }
    if (hasConflict) {
      return Icons.warning_amber_rounded;
    }
    return Icons.star_rounded;
  }

  Color get statusColor {
    if (hasConflict) {
      return AppColors.accentOrange;
    }
    return isRecommended ? AppColors.accentGreen : AppColors.accentRed;
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
  const _TimeRecommendationResult({required this.recommendations});

  final List<_TimeRecommendation> recommendations;
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

List<_DateRecommendation> _dateRecommendationsInRange(
  List<_DateRecommendation> recommendations, {
  required DateTime start,
  required DateTime end,
}) {
  final startDate = _dateOnly(start);
  final endDate = _dateOnly(end);
  return recommendations
      .where((recommendation) {
        final current = _dateOnly(recommendation.date);
        return !current.isBefore(startDate) && !current.isAfter(endDate);
      })
      .toList(growable: false);
}

@visibleForTesting
List<DateTime> onmuRecommendedDatesForRangePicker({
  required DateTime anchor,
  required List<ParticipantSchedulePreference> participantPreferences,
  int dayCount = 30,
}) {
  return _dateRecommendationsForRangePicker(
    anchor: anchor,
    participantPreferences: participantPreferences,
    dayCount: dayCount,
  ).map((recommendation) => recommendation.date).toList(growable: false);
}

List<_DateRecommendation> _dateRecommendationsForRangePicker({
  required DateTime anchor,
  required List<ParticipantSchedulePreference> participantPreferences,
  int dayCount = 30,
}) {
  final profiles = participantPreferences
      .where(
        (participant) =>
            participant.preferenceProfile.preferredWeekdays.isNotEmpty ||
            participant.preferenceProfile.unavailableDates.isNotEmpty,
      )
      .toList(growable: false);
  if (profiles.isEmpty || dayCount <= 0) {
    return const [];
  }

  final anchorDate = _dateOnly(anchor);
  final candidates = <_DateRecommendation>[];
  for (var dayOffset = 0; dayOffset < dayCount; dayOffset += 1) {
    final date = anchorDate.add(Duration(days: dayOffset));
    final unavailableNames = participantPreferences
        .where(
          (participant) =>
              _profileUnavailableOn(participant.preferenceProfile, date),
        )
        .map((participant) => participant.name)
        .toList(growable: false);
    final preferredNames = participantPreferences
        .where(
          (participant) => _profileExplicitlyPrefersWeekday(
            participant.preferenceProfile,
            date,
          ),
        )
        .map((participant) => participant.name)
        .toList(growable: false);
    if (preferredNames.isEmpty) {
      continue;
    }
    candidates.add(
      _DateRecommendation(
        date: date,
        preferredNames: preferredNames,
        unavailableNames: unavailableNames,
      ),
    );
  }

  candidates.sort((a, b) {
    final preferredCompare = b.preferredCount.compareTo(a.preferredCount);
    if (preferredCompare != 0) {
      return preferredCompare;
    }
    final unavailableCompare = a.unavailableCount.compareTo(b.unavailableCount);
    if (unavailableCompare != 0) {
      return unavailableCompare;
    }
    return a.date.compareTo(b.date);
  });

  return _uniqueDateRecommendations(candidates.take(4));
}

_TimeRecommendationResult _timeRecommendationResult({
  required DateTime selectedDate,
  required List<ParticipantSchedulePreference> participantPreferences,
}) {
  final preferenceProfiles = participantPreferences
      .where(
        (participant) => _hasPreferredTimeData(participant.preferenceProfile),
      )
      .toList(growable: false);
  if (preferenceProfiles.isEmpty) {
    return _fallbackTimeRecommendationResult(
      selectedDate,
      unavailableNames: _unavailableParticipantNames(
        participantPreferences,
        selectedDate,
      ),
    );
  }

  final slotStarts = _preferredSlotStarts(preferenceProfiles);
  if (slotStarts.isEmpty) {
    return _fallbackTimeRecommendationResult(
      selectedDate,
      unavailableNames: _unavailableParticipantNames(
        participantPreferences,
        selectedDate,
      ),
    );
  }

  final date = _dateOnly(selectedDate);
  final recommendations = <_TimeRecommendation>[];
  final unavailableNames = _unavailableParticipantNames(
    participantPreferences,
    date,
  );
  for (final slotStart in slotStarts) {
    final preferredNames = preferenceProfiles
        .where(
          (participant) => _profilePrefersSlot(
            participant.preferenceProfile,
            date,
            slotStart,
          ),
        )
        .map((participant) => participant.name)
        .toList(growable: false);
    if (preferredNames.isEmpty) {
      continue;
    }
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
        label: _preferredNamesSummary(preferredNames),
        preferredNames: preferredNames,
        unavailableNames: unavailableNames,
        isRecommended: unavailableNames.isEmpty,
      ),
    );
  }

  if (recommendations.isEmpty) {
    return _fallbackTimeRecommendationResult(
      selectedDate,
      unavailableNames: unavailableNames,
    );
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
  return _TimeRecommendationResult(recommendations: selectedRecommendations);
}

_TimeRecommendationResult _fallbackTimeRecommendationResult(
  DateTime anchor, {
  List<String> unavailableNames = const [],
}) {
  final date = DateTime(anchor.year, anchor.month, anchor.day);
  final recommendations = [
    _fallbackTimeRecommendation(
      date: date,
      hour: 12,
      label: '점심부터 여유롭게 시작할 수 있어요.',
      unavailableNames: unavailableNames,
    ),
    _fallbackTimeRecommendation(
      date: date,
      hour: 13,
      label: '가장 많이 선택되는 시간대예요.',
      unavailableNames: unavailableNames,
    ),
    _fallbackTimeRecommendation(
      date: date,
      hour: 14,
      label: '오후 일정으로 잡기 좋아요.',
      unavailableNames: unavailableNames,
    ),
    _fallbackTimeRecommendation(
      date: date,
      hour: 19,
      label: '퇴근 후 저녁 약속에 맞아요.',
      unavailableNames: unavailableNames,
    ),
  ];
  return _TimeRecommendationResult(recommendations: recommendations);
}

_TimeRecommendation _fallbackTimeRecommendation({
  required DateTime date,
  required int hour,
  required String label,
  required List<String> unavailableNames,
}) {
  return _TimeRecommendation(
    start: DateTime(date.year, date.month, date.day, hour),
    duration: const Duration(hours: 2),
    label: label,
    preferredNames: const [],
    unavailableNames: unavailableNames,
    isRecommended: true,
    generic: true,
  );
}

bool _hasPreferredTimeData(PreferenceProfile profile) {
  return profile.preferredTimes.any(
    (value) => _slotStartsForPreference(value).isNotEmpty,
  );
}

List<_SlotStart> _preferredSlotStarts(
  List<ParticipantSchedulePreference> participants,
) {
  final seen = <int>{};
  final slots = <_SlotStart>[];
  for (final participant in participants) {
    for (final value in participant.preferenceProfile.preferredTimes) {
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

List<_DateRecommendation> _uniqueDateRecommendations(
  Iterable<_DateRecommendation> values,
) {
  final seen = <String>{};
  final recommendations = <_DateRecommendation>[];
  for (final value in values) {
    final date = DateTime(value.date.year, value.date.month, value.date.day);
    final key = '${date.year}-${date.month}-${date.day}';
    if (seen.add(key)) {
      recommendations.add(value);
    }
  }
  return recommendations;
}

List<String> _unavailableParticipantNames(
  List<ParticipantSchedulePreference> participants,
  DateTime date,
) {
  return participants
      .where(
        (participant) =>
            _profileUnavailableOn(participant.preferenceProfile, date),
      )
      .map((participant) => participant.name)
      .toList(growable: false);
}

String _preferredNamesSummary(List<String> names) {
  if (names.isEmpty) {
    return '';
  }
  if (names.length == 1) {
    return '${_honorificName(names.first)} 선호';
  }
  return '${names.length}명 선호';
}

String _unavailableNamesSummary(List<String> names) {
  if (names.isEmpty) {
    return '';
  }
  if (names.length == 1) {
    return '${_honorificName(names.first)}이 불가능해요';
  }
  return '${_honorificName(names.first)} 외 ${names.length - 1}명이 불가능해요';
}

String _honorificName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '참여자님';
  }
  if (trimmed.endsWith('님')) {
    return trimmed;
  }
  return '$trimmed님';
}

class _DateRecommendation {
  const _DateRecommendation({
    required this.date,
    required this.preferredNames,
    required this.unavailableNames,
  });

  final DateTime date;
  final List<String> preferredNames;
  final List<String> unavailableNames;

  int get preferredCount => preferredNames.length;

  int get unavailableCount => unavailableNames.length;

  bool get hasConflict => unavailableNames.isNotEmpty;

  String get preferredLabel => _preferredNamesSummary(preferredNames);

  String get unavailableLabel => _unavailableNamesSummary(unavailableNames);

  String get detailLabel {
    final parts = [
      preferredLabel,
      unavailableLabel,
    ].where((part) => part.isNotEmpty);
    return parts.join(' · ');
  }
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

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatClock(int hour, int minute) {
  final normalizedHour = hour % 24;
  return '${normalizedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String _weekday(DateTime date) {
  return const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
}
