import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_upcoming_plan_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/home_view_model.dart';

class UpcomingPlansPage extends ConsumerWidget {
  const UpcomingPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return state.when(
      data: (state) => _UpcomingPlansContent(
        groupId: state.groupId,
        upcomingPlans: state.upcomingPlans,
        calendarPlans: state.calendarPlans,
      ),
      loading: () => const OnmuScaffold(
        title: '다가오는 약속',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '다가오는 약속',
        children: [
          Text(
            '다가오는 약속을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class UpcomingPlansCalendarPage extends ConsumerWidget {
  const UpcomingPlansCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return state.when(
      data: (state) => _UpcomingCalendarContent(
        groupId: state.groupId,
        plans: state.calendarPlans,
      ),
      loading: () => const OnmuScaffold(
        title: '약속 캘린더',
        showBackButton: true,
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속 캘린더',
        showBackButton: true,
        children: [
          Text(
            '약속 캘린더를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _UpcomingCalendarContent extends StatefulWidget {
  const _UpcomingCalendarContent({required this.groupId, required this.plans});

  final int? groupId;
  final List<GroupPlanSummary> plans;

  @override
  State<_UpcomingCalendarContent> createState() =>
      _UpcomingCalendarContentState();
}

class _UpcomingCalendarContentState extends State<_UpcomingCalendarContent> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final month = _visibleMonth;
    final leadingEmptySlots = month.weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final calendarSlots = <DateTime?>[
      for (var index = 0; index < leadingEmptySlots; index += 1) null,
      for (var day = 1; day <= daysInMonth; day += 1)
        DateTime(month.year, month.month, day),
    ];
    final selectedDay = _selectedDay;
    final selectedPlans = selectedDay == null
        ? const <GroupPlanSummary>[]
        : _plansOn(selectedDay);

    return OnmuScaffold(
      title: '약속 캘린더',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.homeUpcomingPlans),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '이전 달',
              onPressed: () => setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month - 1,
                );
                _selectedDay = null;
              }),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${month.year}년 ${month.month}월',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: '다음 달',
              onPressed: () => setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month + 1,
                );
                _selectedDay = null;
              }),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _CalendarWeekdayHeader(),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: calendarSlots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DateTime.daysPerWeek,
            childAspectRatio: 0.94,
            crossAxisSpacing: AppSpacing.xxs,
            mainAxisSpacing: AppSpacing.xxs,
          ),
          itemBuilder: (context, index) {
            final day = calendarSlots[index];
            if (day == null) {
              return const SizedBox.shrink();
            }
            return _CalendarDayCell(
              key: ValueKey(
                'upcoming-calendar-day-${day.year}-${day.month}-${day.day}',
              ),
              day: day,
              plans: _plansOn(day),
              selected: _isSameDay(day, _selectedDay),
              onTap: () {
                setState(() {
                  final tappedDay = DateTime(day.year, day.month, day.day);
                  _selectedDay = _isSameDay(day, _selectedDay)
                      ? null
                      : tappedDay;
                });
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SelectedCalendarDayPlans(
          groupId: widget.groupId,
          selectedDay: selectedDay,
          plans: selectedPlans,
        ),
        const SizedBox(height: 72),
      ],
    );
  }

  List<GroupPlanSummary> _plansOn(DateTime day) {
    return widget.plans.where((plan) {
      final startsAt = plan.startsAt?.toLocal();
      return startsAt != null &&
          startsAt.year == day.year &&
          startsAt.month == day.month &&
          startsAt.day == day.day;
    }).toList()..sort(GroupPlanSummary.compareUpcoming);
  }

  bool _isSameDay(DateTime left, DateTime? right) {
    return right != null &&
        left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.plans,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DateTime day;
  final List<GroupPlanSummary> plans;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.linePink
        : plans.isEmpty
        ? AppColors.lineSoft
        : AppColors.linePink;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.day.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMain),
                ),
                const SizedBox(height: AppSpacing.xxs),
                for (final plan in plans.take(2))
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryPurple,
                      height: 1.05,
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

class _CalendarWeekdayHeader extends StatelessWidget {
  const _CalendarWeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final weekday in const ['월', '화', '수', '목', '금', '토', '일'])
          Expanded(
            child: Center(
              child: Text(
                weekday,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectedCalendarDayPlans extends StatelessWidget {
  const _SelectedCalendarDayPlans({
    required this.groupId,
    required this.selectedDay,
    required this.plans,
  });

  final int? groupId;
  final DateTime? selectedDay;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    final selectedDay = this.selectedDay;
    final title = selectedDay == null
        ? '선택한 날짜'
        : '${selectedDay.month}월 ${selectedDay.day}일 약속';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (selectedDay == null)
          const _CalendarSelectionGuideCard()
        else if (plans.isEmpty)
          const _EmptySelectedDayPlanCard()
        else
          for (final plan in plans) ...[
            OnmuUpcomingPlanCard(
              plan: plan,
              onTap: () {
                final currentGroupId = groupId;
                if (currentGroupId == null) {
                  context.go(RoutePaths.groups);
                  return;
                }
                context.push(RoutePaths.planDetail(currentGroupId, plan.id));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _CalendarSelectionGuideCard extends StatelessWidget {
  const _CalendarSelectionGuideCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.lineSoft,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '날짜를 선택하면 약속이 표시돼요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
      ),
    );
  }
}

class _EmptySelectedDayPlanCard extends StatelessWidget {
  const _EmptySelectedDayPlanCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.lineSoft,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '선택한 날짜에 표시할 약속이 없어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
      ),
    );
  }
}

class _UpcomingPlansContent extends StatefulWidget {
  const _UpcomingPlansContent({
    required this.groupId,
    required this.upcomingPlans,
    required this.calendarPlans,
  });

  final int? groupId;
  final List<GroupPlanSummary> upcomingPlans;
  final List<GroupPlanSummary> calendarPlans;

  @override
  State<_UpcomingPlansContent> createState() => _UpcomingPlansContentState();
}

class _UpcomingPlansContentState extends State<_UpcomingPlansContent> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDay;
    final weekPlans = widget.upcomingPlans.take(2).toList();
    final nextPlans = widget.upcomingPlans.skip(2).toList();
    final filteredPlans = selectedDay == null
        ? const <GroupPlanSummary>[]
        : _plansOn(selectedDay);

    return OnmuScaffold(
      title: '다가오는 약속',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      action: Row(
        children: [
          IconButton(
            tooltip: '캘린더 보기',
            onPressed: () => context.push(RoutePaths.homeUpcomingCalendar),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      children: [
        _MonthHeader(
          plans: widget.calendarPlans,
          selectedDay: selectedDay,
          onDayTap: _toggleSelectedDay,
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (selectedDay == null) ...[
          _PlanSection(
            title: '이번 주',
            groupId: widget.groupId,
            plans: weekPlans,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _PlanSection(
            title: '다음 주',
            groupId: widget.groupId,
            plans: nextPlans,
          ),
        ] else
          _PlanSection(
            title: '${selectedDay.month}월 ${selectedDay.day}일 약속',
            groupId: widget.groupId,
            plans: filteredPlans,
          ),
        const SizedBox(height: 72),
      ],
    );
  }

  List<GroupPlanSummary> _plansOn(DateTime day) {
    return widget.calendarPlans.where((plan) {
      final startsAt = plan.startsAt?.toLocal();
      return startsAt != null &&
          startsAt.year == day.year &&
          startsAt.month == day.month &&
          startsAt.day == day.day;
    }).toList()..sort(GroupPlanSummary.compareUpcoming);
  }

  void _toggleSelectedDay(DateTime day) {
    setState(() {
      final normalizedDay = DateTime(day.year, day.month, day.day);
      _selectedDay = _isSameDay(normalizedDay, _selectedDay)
          ? null
          : normalizedDay;
    });
  }

  bool _isSameDay(DateTime left, DateTime? right) {
    return right != null &&
        left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _MonthHeader extends StatefulWidget {
  const _MonthHeader({
    required this.plans,
    required this.selectedDay,
    required this.onDayTap,
  });

  final List<GroupPlanSummary> plans;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayTap;

  @override
  State<_MonthHeader> createState() => _MonthHeaderState();
}

class _MonthHeaderState extends State<_MonthHeader> {
  late DateTime _weekAnchor;

  List<DateTime> _createDays(DateTime today) {
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
      DateTime.daysPerWeek,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[date.weekday - 1];
  }

  bool _hasPlanOn(DateTime date) {
    return widget.plans.any((plan) {
      final startsAt = plan.startsAt?.toLocal();
      return startsAt != null &&
          startsAt.year == date.year &&
          startsAt.month == date.month &&
          startsAt.day == date.day;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekAnchor = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final days = _createDays(_weekAnchor);

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 주',
                onPressed: () {
                  setState(() {
                    _weekAnchor = _weekAnchor.subtract(
                      const Duration(days: DateTime.daysPerWeek),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_weekAnchor.year}년 ${_weekAnchor.month}월',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: '다음 주',
                onPressed: () {
                  setState(() {
                    _weekAnchor = _weekAnchor.add(
                      const Duration(days: DateTime.daysPerWeek),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: _DayPill(
                    key: ValueKey(
                      'upcoming-week-day-${day.year}-${day.month}-${day.day}',
                    ),
                    day: day.day.toString(),
                    weekday: _weekdayLabel(day),
                    selected: _isSameDay(day, widget.selectedDay),
                    hasPlan: _hasPlanOn(day),
                    onTap: () => widget.onDayTap(day),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime left, DateTime? right) {
    return right != null &&
        left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.weekday,
    required this.selected,
    required this.hasPlan,
    required this.onTap,
    super.key,
  });

  final String day;
  final String weekday;
  final bool selected;
  final bool hasPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryPinkSoft : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: selected ? Border.all(color: AppColors.linePink) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                SizedBox(
                  height: 6,
                  child: hasPlan
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const SizedBox.square(dimension: 5),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  day,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.primaryPurple
                        : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  weekday,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? AppColors.primaryPurple
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

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.groupId,
    required this.plans,
  });

  final String title;
  final int? groupId;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (plans.isEmpty)
          const _EmptyPlanSectionCard()
        else
          for (final plan in plans) ...[
            OnmuUpcomingPlanCard(
              plan: plan,
              onTap: () {
                final currentGroupId = groupId;
                if (currentGroupId == null) {
                  context.go(RoutePaths.groups);
                  return;
                }
                context.push(RoutePaths.planDetail(currentGroupId, plan.id));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _EmptyPlanSectionCard extends StatelessWidget {
  const _EmptyPlanSectionCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.lineSoft,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '표시할 약속이 없어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
      ),
    );
  }
}
