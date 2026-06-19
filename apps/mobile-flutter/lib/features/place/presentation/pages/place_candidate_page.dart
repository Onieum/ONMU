import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_date_time_range_picker.dart';
import '../../../../shared/widgets/onmu_location_subtitle.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/place_candidates_view_model.dart';

class PlaceCandidatePage extends ConsumerWidget {
  const PlaceCandidatePage({
    required this.groupId,
    required this.planId,
    super.key,
    this.showVoteResult = false,
  });

  final String groupId;
  final String planId;
  final bool showVoteResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = placeCandidatesViewModelProvider((
      groupId: groupId,
      planId: planId,
    ));
    final state = ref.watch(provider);

    return state.when(
      data: (state) => _PlaceCandidateContent(
        groupId: groupId,
        planId: planId,
        showVoteResult: showVoteResult,
        state: state,
        onFavoritePressed: (candidateId) {
          ref.read(provider.notifier).toggleFavorite(candidateId);
        },
        onRegisterCandidate: (candidate, range) async {
          await ref
              .read(provider.notifier)
              .addCandidateToSchedule(
                candidate,
                startsAt: range.start,
                endsAt: range.end,
              );
        },
      ),
      loading: () => const OnmuScaffold(
        title: '장소 후보 리스트',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '장소 후보 리스트',
        children: [
          Text(
            '장소 후보를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PlaceCandidateContent extends StatefulWidget {
  const _PlaceCandidateContent({
    required this.groupId,
    required this.planId,
    required this.showVoteResult,
    required this.state,
    required this.onFavoritePressed,
    required this.onRegisterCandidate,
  });

  final String groupId;
  final String planId;
  final bool showVoteResult;
  final PlaceCandidatesState state;
  final ValueChanged<int> onFavoritePressed;
  final Future<void> Function(PlaceCandidate candidate, OnmuDateTimeRange range)
  onRegisterCandidate;

  @override
  State<_PlaceCandidateContent> createState() => _PlaceCandidateContentState();
}

class _PlaceCandidateContentState extends State<_PlaceCandidateContent> {
  var _selectedCategory = _allCategory;
  final _savingCandidateIds = <int>{};

  static const _allCategory = '전체';

  List<PlaceCandidate> get _visibleCandidates {
    if (_selectedCategory == _allCategory) {
      return widget.state.candidates;
    }
    return widget.state.candidates
        .where((candidate) => _matchesCategory(candidate, _selectedCategory))
        .toList(growable: false);
  }

  bool _matchesCategory(PlaceCandidate candidate, String selectedCategory) {
    final category = candidate.category.trim();
    final tags = candidate.tags.map((tag) => tag.trim()).toList();
    final values = [category, ...tags];

    return switch (selectedCategory) {
      '카페' => values.any((value) => value.contains('카페')),
      '식사' => values.any(
        (value) =>
            value.contains('식사') ||
            value.contains('식당') ||
            value.contains('한식') ||
            value.contains('양식') ||
            value.contains('일식') ||
            value.contains('중식') ||
            value.contains('분식'),
      ),
      '관광' => values.any(
        (value) =>
            value.contains('관광') ||
            value.contains('명소') ||
            value.contains('전시') ||
            value.contains('체험'),
      ),
      '숙소' => values.any(
        (value) =>
            value.contains('숙소') ||
            value.contains('호텔') ||
            value.contains('펜션') ||
            value.contains('게스트하우스'),
      ),
      _ => category == selectedCategory,
    };
  }

  @override
  Widget build(BuildContext context) {
    final visibleCandidates = _visibleCandidates;

    return OnmuScaffold(
      title: '장소 후보 리스트',
      titleSubtitle: OnmuLocationSubtitle(location: widget.state.planLocation),
      showBackButton: true,
      onBack: () =>
          context.popOrGo(RoutePaths.planDetail(widget.groupId, widget.planId)),
      action: TextButton(
        onPressed: widget.state.candidates.isEmpty
            ? null
            : () => context.push(
                RoutePaths.planVoteNew(widget.groupId, widget.planId),
              ),
        child: const Text('투표 만들기'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '후보 추가',
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        shape: const CircleBorder(),
        onPressed: () => context.push(
          RoutePaths.planPlaceSearch(widget.groupId, widget.planId),
        ),
        child: const Icon(Icons.add),
      ),
      bottom: OnmuCard(
        backgroundColor: AppColors.bgPaper,
        borderColor: AppColors.lineWarm,
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.accentOrange),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '약속 멤버가 함께 모은 장소 후보예요',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      children: [
        if (widget.showVoteResult) ...[
          const _VoteResultNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        _CategoryChips(
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() => _selectedCategory = category);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visibleCandidates.isEmpty)
          const _EmptyCandidateCard()
        else
          for (var index = 0; index < visibleCandidates.length; index += 1) ...[
            _CandidateListCard(
              order: index + 1,
              candidate: visibleCandidates[index],
              liked: widget.state.isLiked(visibleCandidates[index].id),
              favoriteCount: widget.state.favoriteCountFor(
                visibleCandidates[index].id,
              ),
              onFavoritePressed: () =>
                  widget.onFavoritePressed(visibleCandidates[index].id),
              onDetailPressed: () => context.push(
                RoutePaths.planPlaceCandidateDetail(
                  widget.groupId,
                  widget.planId,
                  visibleCandidates[index].id,
                ),
              ),
              saving: _savingCandidateIds.contains(visibleCandidates[index].id),
              onRegisterPressed: () =>
                  _registerCandidate(context, visibleCandidates[index]),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        const SizedBox(height: 72),
      ],
    );
  }

  Future<void> _registerCandidate(
    BuildContext context,
    PlaceCandidate candidate,
  ) async {
    if (_savingCandidateIds.contains(candidate.id)) {
      return;
    }
    final picked = await OnmuDateTimeRangePicker.show(
      context: context,
      title: '방문 시간 설정',
      initialStart: _initialVisitStart(widget.state),
      initialEnd: _initialVisitEnd(widget.state),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _savingCandidateIds.add(candidate.id);
    });
    try {
      await widget.onRegisterCandidate(candidate, picked);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일정 장소를 등록하지 못했어요.')));
      return;
    } finally {
      if (mounted) {
        setState(() {
          _savingCandidateIds.remove(candidate.id);
        });
      }
    }
    if (!context.mounted) {
      return;
    }
    context.go(RoutePaths.planItinerary(widget.groupId, widget.planId));
  }

  DateTime _initialVisitStart(PlaceCandidatesState state) {
    final planStart = state.planStartsAt?.toLocal();
    if (planStart != null && planStart.isAfter(DateTime.now())) {
      return planStart;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  DateTime _initialVisitEnd(PlaceCandidatesState state) {
    final start = _initialVisitStart(state);
    final defaultEnd = start.add(const Duration(hours: 1));
    final planEnd = state.planEndsAt?.toLocal();
    if (planEnd != null &&
        planEnd.isAfter(start) &&
        planEnd.isBefore(defaultEnd)) {
      return planEnd;
    }
    return defaultEnd;
  }
}

class _EmptyCandidateCard extends StatelessWidget {
  const _EmptyCandidateCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lineWarm),
            ),
            child: const SizedBox(
              height: 96,
              child: Center(
                child: Icon(
                  Icons.add_location_alt_outlined,
                  size: 36,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '아직 장소 후보 리스트가 비어있어요!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '후보를 추가하면 이 공간에 카드로 정리돼요.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _VoteResultNotice extends StatelessWidget {
  const _VoteResultNotice();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePink,
      child: Text(
        '온모임 투표 결과를 후보 리스트에 이어서 보여줘요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final categories = ['전체', '카페', '식사', '관광', '숙소'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index += 1) ...[
            OnmuChip(
              label: categories[index],
              selected: categories[index] == selectedCategory,
              onTap: () => onCategorySelected(categories[index]),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _CandidateListCard extends StatelessWidget {
  const _CandidateListCard({
    required this.order,
    required this.candidate,
    required this.liked,
    required this.favoriteCount,
    required this.saving,
    required this.onFavoritePressed,
    required this.onDetailPressed,
    required this.onRegisterPressed,
  });

  final int order;
  final PlaceCandidate candidate;
  final bool liked;
  final int favoriteCount;
  final bool saving;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDetailPressed;
  final VoidCallback onRegisterPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onDetailPressed,
      backgroundColor: liked ? AppColors.primaryPinkSoft : AppColors.bgDefault,
      borderColor: liked ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: SizedBox.square(
              dimension: 28,
              child: Center(
                child: Text(
                  '$order',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgGrid,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const SizedBox.square(
              dimension: 58,
              child: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.textSub,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          tooltip: liked ? '하트 취소' : '하트',
                          onPressed: onFavoritePressed,
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.accentRed,
                          ),
                        ),
                        if (favoriteCount > 0)
                          Text(
                            '$favoriteCount',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                      ],
                    ),
                  ],
                ),
                Text(
                  _candidateMetaLabel(candidate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  candidate.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: saving ? null : onRegisterPressed,
                    child: Text(saving ? '등록 중' : '일정에 등록'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _candidateMetaLabel(PlaceCandidate candidate) {
  final tags = candidate.tags.take(2).toList(growable: false);
  if (tags.isEmpty) {
    return candidate.category;
  }
  return '${candidate.category} · ${tags.join(' · ')}';
}
