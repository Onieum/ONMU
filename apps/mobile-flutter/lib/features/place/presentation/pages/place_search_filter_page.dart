import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/place_candidates_view_model.dart';
import '../widgets/place_candidate_card.dart';

class PlaceSearchFilterPage extends ConsumerStatefulWidget {
  const PlaceSearchFilterPage({
    required this.groupId,
    required this.planId,
    super.key,
  });

  final String groupId;
  final String planId;

  @override
  ConsumerState<PlaceSearchFilterPage> createState() =>
      _PlaceSearchFilterPageState();
}

class _PlaceSearchFilterPageState extends ConsumerState<PlaceSearchFilterPage> {
  static const _allCategory = '전체';
  static const _categories = [_allCategory, '음식점', '카페', '가볼만한곳'];

  final _searchController = TextEditingController();
  final _savingCandidateIds = <int>{};
  var _query = '';
  var _selectedCategory = _allCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final category = _selectedCategory == _allCategory
        ? null
        : _selectedCategory;
    final results = query.isEmpty
        ? const AsyncValue<List<PlaceCandidate>>.data([])
        : ref.watch(
            placeSearchResultsProvider((
              groupId: widget.groupId,
              planId: widget.planId,
              query: query,
              category: category,
              lat: null,
              lng: null,
              radius: null,
            )),
          );

    return OnmuScaffold(
      title: '장소 후보 찾기',
      subtitle: '검색해서 후보에 담고 만날 장소를 정해요',
      showBackButton: true,
      onBack: () => context.popOrGo(
        RoutePaths.planPlaceCandidates(widget.groupId, widget.planId),
      ),
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: '예: 강남 맛집, 을지로 카페, 서울 가볼만한 곳',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: '검색어 지우기',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CategoryFilter(
          selectedCategory: _selectedCategory,
          onChanged: (category) => setState(() => _selectedCategory = category),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (query.isEmpty)
          const _SearchGuideCard()
        else
          results.when(
            data: (candidates) => _SearchResults(
              candidates: candidates,
              query: query,
              savingCandidateIds: _savingCandidateIds,
              onAddCandidate: _addCandidate,
              onRegisterCandidate: _registerCandidate,
              onDetailCandidate: _openCandidateDetail,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _SearchErrorCard(),
          ),
      ],
    );
  }

  Future<void> _addCandidate(PlaceCandidate candidate) async {
    if (_savingCandidateIds.contains(candidate.id)) {
      return;
    }
    setState(() => _savingCandidateIds.add(candidate.id));
    try {
      await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: widget.groupId,
              planId: widget.planId,
            )).notifier,
          )
          .addCandidate(candidate);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('장소 후보에 담았어요.'),
          action: SnackBarAction(
            label: '후보 비교',
            onPressed: () => context.go(
              RoutePaths.planPlaceCandidates(widget.groupId, widget.planId),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingCandidateIds.remove(candidate.id));
      }
    }
  }

  Future<void> _registerCandidate(PlaceCandidate candidate) async {
    if (_savingCandidateIds.contains(candidate.id)) {
      return;
    }
    setState(() => _savingCandidateIds.add(candidate.id));
    try {
      await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: widget.groupId,
              planId: widget.planId,
            )).notifier,
          )
          .addCandidateToSchedule(candidate);
      if (!mounted) {
        return;
      }
      context.go(RoutePaths.planItinerary(widget.groupId, widget.planId));
    } finally {
      if (mounted) {
        setState(() => _savingCandidateIds.remove(candidate.id));
      }
    }
  }

  Future<void> _openCandidateDetail(PlaceCandidate candidate) async {
    final saved = await ref
        .read(
          placeCandidatesViewModelProvider((
            groupId: widget.groupId,
            planId: widget.planId,
          )).notifier,
        )
        .addCandidate(candidate);
    if (!mounted) {
      return;
    }
    context.push(
      RoutePaths.planPlaceCandidateDetail(
        widget.groupId,
        widget.planId,
        saved.id,
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in _PlaceSearchFilterPageState._categories) ...[
            OnmuChip(
              label: category,
              selected: category == selectedCategory,
              onTap: () => onChanged(category),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SearchGuideCard extends StatelessWidget {
  const _SearchGuideCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_outlined, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '어디서 만날지 검색해 보세요',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '지역, 분위기, 음식 종류를 같이 입력하면 바로 후보로 담을 수 있어요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.candidates,
    required this.query,
    required this.savingCandidateIds,
    required this.onAddCandidate,
    required this.onRegisterCandidate,
    required this.onDetailCandidate,
  });

  final List<PlaceCandidate> candidates;
  final String query;
  final Set<int> savingCandidateIds;
  final ValueChanged<PlaceCandidate> onAddCandidate;
  final ValueChanged<PlaceCandidate> onRegisterCandidate;
  final ValueChanged<PlaceCandidate> onDetailCandidate;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.lineSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('검색 결과가 없어요', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"$query" 대신 지역명이나 카테고리를 조금 넓혀서 다시 찾아보세요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '검색 결과 ${candidates.length}개',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in candidates) ...[
          PlaceCandidateCard(
            candidate: candidate,
            compact: true,
            onDetailPressed: () => onDetailCandidate(candidate),
            onAddCandidatePressed: savingCandidateIds.contains(candidate.id)
                ? null
                : () => onAddCandidate(candidate),
            onRegisterPressed: savingCandidateIds.contains(candidate.id)
                ? null
                : () => onRegisterCandidate(candidate),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SearchErrorCard extends StatelessWidget {
  const _SearchErrorCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Text(
        '장소 검색 결과를 불러오지 못했어요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
