import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/map/model/map_models.dart';
import '../../../../features/map/widgets/onmu_map_view.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_top_bar.dart';
import '../../view_model/place_candidates_view_model.dart';
import '../widgets/place_candidate_card.dart';

class PlaceMapPage extends ConsumerStatefulWidget {
  const PlaceMapPage({required this.groupId, required this.planId, super.key});

  final String groupId;
  final String planId;

  @override
  ConsumerState<PlaceMapPage> createState() => _PlaceMapPageState();
}

class _PlaceMapPageState extends ConsumerState<PlaceMapPage> {
  static const _allCategory = '전체';
  static const _categories = ['전체', '한식', '카페', '전시', '술집'];

  bool _searchActive = false;
  String _query = '';
  String _selectedCategory = _allCategory;
  PlaceCandidate? _selectedCandidate;
  final Set<int> _savingCandidateIds = {};

  List<PlaceCandidate> _visibleCandidates(List<PlaceCandidate> candidates) {
    final normalizedQuery = _query.trim().toLowerCase();

    final results = candidates.where((candidate) {
      final matchesCategory =
          _selectedCategory == _allCategory ||
          candidate.category == _selectedCategory ||
          candidate.tags.contains(_selectedCategory);
      final searchableText = [
        candidate.name,
        candidate.category,
        candidate.summary,
        ...candidate.tags,
      ].join(' ').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);

      return matchesCategory && matchesQuery;
    }).toList();

    return results;
  }

  List<PlaceCandidate> _mergeCandidates(
    List<PlaceCandidate> savedCandidates,
    List<PlaceCandidate> searchedCandidates,
  ) {
    final merged = <PlaceCandidate>[];
    final seen = <String>{};

    void addCandidate(PlaceCandidate candidate) {
      final identities = _candidateIdentities(candidate);
      if (identities.any(seen.contains)) {
        return;
      }
      seen.addAll(identities);
      merged.add(candidate);
    }

    for (final candidate in savedCandidates) {
      addCandidate(candidate);
    }
    for (final candidate in searchedCandidates) {
      addCandidate(candidate);
    }

    return merged;
  }

  Set<String> _candidateIdentities(PlaceCandidate candidate) {
    final identities = <String>{};
    final providerPlaceId = candidate.providerPlaceId.trim();
    if (providerPlaceId.isNotEmpty) {
      identities.add('provider:${candidate.provider}:$providerPlaceId');
    }
    final normalizedName = candidate.name.trim().toLowerCase();
    final normalizedAddress = candidate.address.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      identities.add('name:$normalizedName');
      identities.add('place:$normalizedName:$normalizedAddress');
    }
    return identities.isEmpty ? {'id:${candidate.id}'} : identities;
  }

  String _defaultSearchQuery(PlaceCandidatesState state) {
    final location = _normalizedPlanLocation(state.planLocation);
    final categoryKeyword = _selectedCategory == _allCategory
        ? '카페'
        : _selectedCategory;
    return [
      location,
      categoryKeyword,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  String _normalizedPlanLocation(String value) {
    var normalized = value.trim();
    for (final token in const ['일대', '주변', '근처', '장소 미정', '미정']) {
      normalized = normalized.replaceAll(token, '').trim();
    }
    return normalized;
  }

  void _activateSearch() {
    if (_searchActive) {
      return;
    }

    setState(() {
      _searchActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      placeCandidatesViewModelProvider((
        groupId: widget.groupId,
        planId: widget.planId,
      )),
    );

    return state.when(
      data: (state) => _buildContent(context, state),
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgGrid,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.bgGrid,
        body: SafeArea(
          child: Center(
            child: Text(
              '장소 후보를 불러오지 못했어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlaceCandidatesState state) {
    final localVisibleCandidates = _visibleCandidates(state.candidates);
    final autoSearch = _query.trim().isEmpty;
    final effectiveQuery = autoSearch ? _defaultSearchQuery(state) : _query;
    final searchActive =
        _searchActive || autoSearch || _selectedCategory != _allCategory;
    final remoteSearchState = effectiveQuery.trim().isEmpty
        ? null
        : ref.watch(
            placeSearchResultsProvider((
              groupId: widget.groupId,
              planId: widget.planId,
              query: effectiveQuery,
              category: _selectedCategory == _allCategory
                  ? null
                  : _selectedCategory,
            )),
          );
    final visibleCandidates =
        remoteSearchState?.maybeWhen(
          data: (results) => results.isEmpty
              ? localVisibleCandidates
              : _mergeCandidates(localVisibleCandidates, results),
          orElse: () => localVisibleCandidates,
        ) ??
        localVisibleCandidates;
    final searchLoading = remoteSearchState?.isLoading ?? false;
    final searchHadError = remoteSearchState?.hasError ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgGrid,
      body: SafeArea(
        child: Column(
          children: [
            OnmuTopBar(
              title: '장소 검색하기',
              showBackButton: true,
              onBack: () => context.popOrGo(
                RoutePaths.planDetail(widget.groupId, widget.planId),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: OnmuMapView(
                      points: _mapPointsFor(visibleCandidates),
                      fallbackLabel: _mapFallbackLabel(
                        visibleCandidates,
                        searchLoading: searchLoading,
                        searchHadError: searchHadError,
                      ),
                      focusedPointId: _selectedCandidate?.id.toString(),
                      onPointTap: (point) {
                        final selected = _candidateByPointId(
                          visibleCandidates,
                          point.id,
                        );
                        if (selected != null) {
                          setState(() => _selectedCandidate = selected);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.sm,
                    child: _SearchBar(
                      query: _query,
                      onTap: _activateSearch,
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                          _searchActive = true;
                          _selectedCandidate = null;
                        });
                      },
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: 0,
                    top: 76,
                    child: _CategoryPills(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onSelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                          _searchActive =
                              category != _allCategory || _query.isNotEmpty;
                          _selectedCandidate = null;
                        });
                      },
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    top: 126,
                    child: IconButton.filledTonal(
                      tooltip: '필터',
                      onPressed: _activateSearch,
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.52,
                    minChildSize: 0.32,
                    maxChildSize: 0.94,
                    builder: (context, scrollController) {
                      return KeyedSubtree(
                        key: const ValueKey('place-map-bottom-sheet'),
                        child: _RecommendationSheet(
                          controller: scrollController,
                          candidates: visibleCandidates,
                          searchActive: searchActive,
                          autoSearch: autoSearch,
                          query: effectiveQuery,
                          selectedCategory: _selectedCategory,
                          searchLoading: searchLoading,
                          searchHadError: searchHadError,
                          selectedCandidate: _selectedCandidate,
                          isSavingCandidate: (candidate) =>
                              _savingCandidateIds.contains(candidate.id),
                          onBackToResults: () {
                            setState(() {
                              _selectedCandidate = null;
                            });
                          },
                          onCandidateSelected: (candidate) {
                            setState(() {
                              _selectedCandidate = candidate;
                            });
                          },
                          onRegisterPressed: (candidate) =>
                              _saveCandidateAndNavigate(
                                candidate,
                                context,
                                message: '일정에 등록되었어요!',
                                targetPath: RoutePaths.planItinerary(
                                  widget.groupId,
                                  widget.planId,
                                ),
                              ),
                          onAddCandidatePressed: (candidate) =>
                              _saveCandidateAndNavigate(
                                candidate,
                                context,
                                message: '후보에 추가되었어요!',
                                targetPath: RoutePaths.planPlaceCandidates(
                                  widget.groupId,
                                  widget.planId,
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCandidateAndNavigate(
    PlaceCandidate candidate,
    BuildContext context, {
    required String message,
    required String targetPath,
  }) async {
    if (_savingCandidateIds.contains(candidate.id)) {
      return;
    }

    setState(() {
      _savingCandidateIds.add(candidate.id);
    });

    try {
      final savedCandidate = await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: widget.groupId,
              planId: widget.planId,
            )).notifier,
          )
          .addCandidate(candidate);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _selectedCandidate = savedCandidate;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.push(targetPath);
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('장소를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _savingCandidateIds.remove(candidate.id);
        });
      }
    }
  }

  PlaceCandidate? _candidateByPointId(
    List<PlaceCandidate> candidates,
    String pointId,
  ) {
    for (final candidate in candidates) {
      if (candidate.id.toString() == pointId) {
        return candidate;
      }
    }
    return null;
  }

  List<OnmuMapPoint> _mapPointsFor(List<PlaceCandidate> candidates) {
    const fallback = [
      OnmuLatLng(lat: 37.5665, lng: 126.9780),
      OnmuLatLng(lat: 37.5651, lng: 126.9895),
      OnmuLatLng(lat: 37.5326, lng: 126.9904),
      OnmuLatLng(lat: 37.5700, lng: 126.9820),
      OnmuLatLng(lat: 37.5580, lng: 126.9970),
    ];
    return [
      for (var index = 0; index < candidates.length; index += 1)
        OnmuMapPoint(
          id: candidates[index].id.toString(),
          label: candidates[index].name,
          coordinate: candidates[index].hasCoordinate
              ? OnmuLatLng(
                  lat: candidates[index].latitude!,
                  lng: candidates[index].longitude!,
                )
              : fallback[index % fallback.length],
          order: index + 1,
        ),
    ];
  }

  String _mapFallbackLabel(
    List<PlaceCandidate> candidates, {
    required bool searchLoading,
    required bool searchHadError,
  }) {
    if (candidates.isNotEmpty) {
      return '지도 타일을 준비하는 동안 후보 위치를 표시하고 있어요';
    }
    if (searchLoading) {
      return '지도 위에 보여줄 장소를 찾는 중이에요';
    }
    if (searchHadError) {
      return '지도 타일과 검색 결과를 다시 확인하고 있어요';
    }
    return '검색어를 입력하면 지도 위에 후보 위치가 표시돼요';
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.query,
    required this.onTap,
    required this.onChanged,
  });

  final String query;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSub),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              initialValue: query,
              onTap: onTap,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: '장소 검색 (카페, 식당, 관광지)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryPill(
            label: category,
            selected: category == selectedCategory,
            onTap: () => onSelected(category),
          );
        },
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.xs),
        itemCount: categories.length,
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? AppColors.primaryPink
        : AppColors.textSub;
    return Material(
      key: ValueKey('place-category-pill-$label'),
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.linePink : AppColors.lineSoft,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 30,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  strutStyle: const StrutStyle(
                    height: 1,
                    forceStrutHeight: true,
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  const MapPin({
    required this.order,
    required this.focused,
    required this.candidateName,
    super.key,
  });

  final int order;
  final bool focused;
  final String candidateName;

  @override
  Widget build(BuildContext context) {
    final pin = Column(
      key: focused ? ValueKey('focused-place-pin-$order') : null,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: focused ? AppColors.primaryPurple : AppColors.primaryPink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.bgDefault,
              width: focused ? 5 : 3,
            ),
            boxShadow: focused
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: SizedBox.square(
            dimension: focused ? 44 : 36,
            child: Center(
              child: Text(
                '$order',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ),
        Icon(
          Icons.location_on,
          color: focused ? AppColors.primaryPurple : AppColors.primaryPink,
        ),
      ],
    );

    if (!focused) {
      return pin;
    }

    return Semantics(
      label: '포커스된 장소 $candidateName',
      container: true,
      child: pin,
    );
  }
}

class CurrentLocationDot extends StatelessWidget {
  const CurrentLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.bgDefault, width: 4),
      ),
      child: const SizedBox.square(dimension: 24),
    );
  }
}

class _RecommendationSheet extends StatelessWidget {
  const _RecommendationSheet({
    required this.controller,
    required this.candidates,
    required this.searchActive,
    required this.autoSearch,
    required this.query,
    required this.selectedCategory,
    required this.searchLoading,
    required this.searchHadError,
    required this.selectedCandidate,
    required this.isSavingCandidate,
    required this.onBackToResults,
    required this.onCandidateSelected,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  static const _bottomNavigationSafePadding = 180.0;

  final ScrollController controller;
  final List<PlaceCandidate> candidates;
  final bool searchActive;
  final bool autoSearch;
  final String query;
  final String selectedCategory;
  final bool searchLoading;
  final bool searchHadError;
  final PlaceCandidate? selectedCandidate;
  final bool Function(PlaceCandidate candidate) isSavingCandidate;
  final VoidCallback onBackToResults;
  final ValueChanged<PlaceCandidate> onCandidateSelected;
  final ValueChanged<PlaceCandidate> onRegisterPressed;
  final ValueChanged<PlaceCandidate> onAddCandidatePressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          _bottomNavigationSafePadding,
        ),
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.lineBrown,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const SizedBox(width: 44, height: 5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (selectedCandidate != null) ...[
            _SelectedPlaceDetailSheet(
              candidate: selectedCandidate!,
              isSaving: isSavingCandidate(selectedCandidate!),
              onBackToResults: onBackToResults,
              onRegisterPressed: () => onRegisterPressed(selectedCandidate!),
              onAddCandidatePressed: () =>
                  onAddCandidatePressed(selectedCandidate!),
            ),
          ] else ...[
            Text(
              autoSearch
                  ? '장소 후보 ✨'
                  : searchActive
                  ? '검색 결과'
                  : '장소 후보',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              searchActive
                  ? _searchResultDescription
                  : '일정에 바로 넣거나 후보 리스트에 담아둘 수 있어요',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (candidates.isEmpty) ...[
              _EmptyPlaceSearchCard(
                searchActive: searchActive,
                searchLoading: searchLoading,
                searchHadError: searchHadError,
                selectedCategory: selectedCategory,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (var index = 0; index < candidates.length; index += 1) ...[
              _RecommendationTile(
                candidate: candidates[index],
                photoIndex: index,
                onTap: () => onCandidateSelected(candidates[index]),
                isSaving: isSavingCandidate(candidates[index]),
                onRegisterPressed: () => onRegisterPressed(candidates[index]),
                onAddCandidatePressed: () =>
                    onAddCandidatePressed(candidates[index]),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              '4명이 함께 정하고 있어요',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
            ),
          ],
        ],
      ),
    );
  }

  String get _searchResultDescription {
    final normalizedQuery = query.trim();
    if (autoSearch && normalizedQuery.isNotEmpty) {
      return '$normalizedQuery 주변에서 바로 후보를 불러왔어요.';
    }
    if (normalizedQuery.isEmpty) {
      if (selectedCategory == '전체') {
        return '지도 위에서 바로 찾아본 장소들이에요';
      }

      return '$selectedCategory 장소를 지도 위에서 확인해요';
    }

    return '"$normalizedQuery" 검색 결과를 지도 위에서 확인해요';
  }
}

class _EmptyPlaceSearchCard extends StatelessWidget {
  const _EmptyPlaceSearchCard({
    required this.searchActive,
    required this.searchLoading,
    required this.searchHadError,
    required this.selectedCategory,
  });

  final bool searchActive;
  final bool searchLoading;
  final bool searchHadError;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(_body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    if (searchLoading) {
      return Icons.explore_outlined;
    }
    if (searchHadError) {
      return Icons.refresh;
    }
    return Icons.search;
  }

  String get _title {
    if (searchLoading) {
      return '장소를 찾는 중이에요';
    }
    if (searchHadError) {
      return '검색 결과를 불러오지 못했어요';
    }
    return searchActive ? '다른 키워드로 다시 찾아볼까요?' : '검색어를 입력해 주세요';
  }

  String get _body {
    if (searchLoading) {
      return '잠시 뒤 후보가 지도와 함께 나타나요.';
    }
    if (searchHadError) {
      return '잠시 후 다시 검색하거나 카테고리를 바꿔보세요.';
    }
    if (searchActive && selectedCategory != '전체') {
      return '$selectedCategory 말고 전체로 넓혀서 찾아볼 수도 있어요.';
    }
    return '카페, 전시, 홍대 카페처럼 입력하면 후보를 지도에 표시해요.';
  }
}

class _SelectedPlaceDetailSheet extends StatelessWidget {
  const _SelectedPlaceDetailSheet({
    required this.candidate,
    required this.isSaving,
    required this.onBackToResults,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final PlaceCandidate candidate;
  final bool isSaving;
  final VoidCallback onBackToResults;
  final VoidCallback onRegisterPressed;
  final VoidCallback onAddCandidatePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '검색 결과로 돌아가기',
              onPressed: onBackToResults,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                '장소 상세',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${candidate.category} · ${candidate.distanceLabel}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                candidate.address,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoBlock(
                title: candidate.openingLabel,
                body: '방문 전 영업시간을 한 번 더 확인해 주세요.',
                trailing: candidate.isOpen ? '영업중' : '확인 필요',
              ),
              const Divider(height: AppSpacing.xl),
              Text('리뷰 키워드', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in candidate.tags)
                    OnmuChip(label: tag, selected: true),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              Text('참여자 선호', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              MemberPreferenceList(candidate: candidate),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlaceActionButtons(
          candidateId: candidate.id,
          isSaving: isSaving,
          onAddCandidatePressed: onAddCandidatePressed,
          onRegisterPressed: onRegisterPressed,
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
    required this.trailing,
  });

  final String title;
  final String body;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        OnmuChip(label: trailing, selected: true),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.candidate,
    required this.photoIndex,
    required this.onTap,
    required this.isSaving,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final PlaceCandidate candidate;
  final int photoIndex;
  final VoidCallback onTap;
  final bool isSaving;
  final VoidCallback onRegisterPressed;
  final VoidCallback onAddCandidatePressed;

  @override
  Widget build(BuildContext context) {
    final tags = candidate.tags.isEmpty
        ? <String>[candidate.category]
        : candidate.tags.take(3).toList(growable: false);

    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlacePhoto(candidate: candidate, index: photoIndex),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            candidate.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      candidate.address.isEmpty
                          ? candidate.summary
                          : candidate.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _MetricChip(
                          icon: Icons.directions_walk,
                          label: candidate.travelTimeLabel,
                        ),
                        _MetricChip(
                          icon: candidate.isOpen
                              ? Icons.circle
                              : Icons.error_outline,
                          label: candidate.isOpen ? '영업 중' : '확인 필요',
                          color: candidate.isOpen
                              ? AppColors.accentRed
                              : AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [for (final tag in tags) OnmuChip(label: tag)],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlaceActionButtons(
            candidateId: candidate.id,
            isSaving: isSaving,
            onAddCandidatePressed: onAddCandidatePressed,
            onRegisterPressed: onRegisterPressed,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryPink,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.lineWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceActionButtons extends StatelessWidget {
  const _PlaceActionButtons({
    required this.candidateId,
    required this.isSaving,
    required this.onAddCandidatePressed,
    required this.onRegisterPressed,
  });

  static const _buttonHeight = 52.0;

  final int candidateId;
  final bool isSaving;
  final VoidCallback onAddCandidatePressed;
  final VoidCallback onRegisterPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            key: ValueKey('place-action-$candidateId-candidate'),
            height: _buttonHeight,
            child: OnmuSecondaryButton(
              label: isSaving ? '저장 중' : '후보에 추가',
              icon: Icons.favorite_border,
              onPressed: isSaving ? null : onAddCandidatePressed,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SizedBox(
            key: ValueKey('place-action-$candidateId-schedule'),
            height: _buttonHeight,
            child: OnmuPrimaryButton(
              label: isSaving ? '저장 중' : '일정에 추가',
              icon: Icons.event_available_outlined,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: isSaving ? null : onRegisterPressed,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({required this.candidate, required this.index});

  final PlaceCandidate candidate;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${candidate.name} 대표 사진',
      image: true,
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: 72,
          height: 92,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _photoColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -8,
                  child: Icon(
                    Icons.circle,
                    size: 44,
                    color: AppColors.bgDefault.withValues(alpha: 0.36),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 16,
                  child: Icon(
                    _photoIcon,
                    color: AppColors.textInverse,
                    size: 28,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDefault.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDefault.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const SizedBox.square(dimension: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> get _photoColors {
    switch (index % 3) {
      case 0:
        return const [AppColors.accentBrown, AppColors.primaryPink];
      case 1:
        return const [AppColors.accentBlue, AppColors.primaryPurple];
      default:
        return const [AppColors.accentGreen, AppColors.accentOrange];
    }
  }

  IconData get _photoIcon {
    switch (candidate.category) {
      case '카페':
        return Icons.local_cafe;
      case '관광지':
        return Icons.park;
      default:
        return Icons.restaurant;
    }
  }
}
