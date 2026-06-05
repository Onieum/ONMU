import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
  final _categories = ['전체', '한식', '카페', '전시', '술집'];

  bool _searchActive = false;
  String _query = '';
  String _selectedCategory = '전체';
  PlaceCandidate? _selectedCandidate;

  List<PlaceCandidate> _visibleCandidates(List<PlaceCandidate> candidates) {
    final normalizedQuery = _query.trim().toLowerCase();

    final results = candidates.where((candidate) {
      final matchesCategory =
          _selectedCategory == '전체' || candidate.category == _selectedCategory;
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

  void _activateSearch() {
    if (_searchActive) {
      return;
    }

    setState(() {
      _searchActive = true;
    });
  }

  int? _focusedOrder(List<PlaceCandidate> candidates) {
    final candidate = _selectedCandidate;
    if (candidate == null) {
      return null;
    }

    final index = candidates.indexWhere((place) => place.id == candidate.id);
    return index == -1 ? null : index + 1;
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
      data: (state) => _buildContent(context, state.candidates),
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

  Widget _buildContent(BuildContext context, List<PlaceCandidate> candidates) {
    final visibleCandidates = _visibleCandidates(candidates);

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
                    child: _MapCanvas(
                      candidates: candidates,
                      focusedOrder: _focusedOrder(candidates),
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
                          _searchActive = category != '전체' || _query.isNotEmpty;
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
                          searchActive: _searchActive,
                          query: _query,
                          selectedCategory: _selectedCategory,
                          selectedCandidate: _selectedCandidate,
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
                          onRegisterPressed: () => _showConfirmation(
                            context,
                            message: '일정에 등록되었어요!',
                            actionLabel: '일정 보러가기',
                            targetPath: RoutePaths.planItinerary(
                              widget.groupId,
                              widget.planId,
                            ),
                          ),
                          onAddCandidatePressed: () => _showConfirmation(
                            context,
                            message: '후보에 추가되었어요!',
                            actionLabel: '후보 리스트 보러가기',
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

  void _showConfirmation(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required String targetPath,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  this.context.push(targetPath);
                }
              },
              child: Text(actionLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.candidates, required this.focusedOrder});

  final List<PlaceCandidate> candidates;
  final int? focusedOrder;

  @override
  Widget build(BuildContext context) {
    final positions = [
      (left: 92.0, top: 132.0, right: null, bottom: null),
      (left: null, top: 220.0, right: 96.0, bottom: null),
      (left: null, top: 128.0, right: 66.0, bottom: null),
    ];

    return CustomPaint(
      painter: _MapCanvasPainter(),
      child: Stack(
        children: [
          for (
            var index = 0;
            index < candidates.length && index < positions.length;
            index += 1
          )
            Positioned(
              left: positions[index].left,
              top: positions[index].top,
              right: positions[index].right,
              bottom: positions[index].bottom,
              child: _MapPin(
                order: index + 1,
                focused: focusedOrder == index + 1,
                candidateName: candidates[index].name,
              ),
            ),
          const Positioned(left: 184, top: 176, child: _CurrentLocationDot()),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 2;

    for (var y = 40.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 28), roadPaint);
    }

    for (var x = 24.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.order,
    required this.focused,
    required this.candidateName,
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

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

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
    required this.query,
    required this.selectedCategory,
    required this.selectedCandidate,
    required this.onBackToResults,
    required this.onCandidateSelected,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final ScrollController controller;
  final List<PlaceCandidate> candidates;
  final bool searchActive;
  final String query;
  final String selectedCategory;
  final PlaceCandidate? selectedCandidate;
  final VoidCallback onBackToResults;
  final ValueChanged<PlaceCandidate> onCandidateSelected;
  final VoidCallback onRegisterPressed;
  final VoidCallback onAddCandidatePressed;

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
          AppSpacing.xl,
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
              onBackToResults: onBackToResults,
              onRegisterPressed: onRegisterPressed,
              onAddCandidatePressed: onAddCandidatePressed,
            ),
          ] else ...[
            Text(
              searchActive ? '검색 결과' : '추천 장소',
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
              OnmuCard(
                backgroundColor: AppColors.bgDefault,
                borderColor: AppColors.lineSoft,
                child: Text(
                  '조건에 맞는 장소를 찾지 못했어요',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            for (var index = 0; index < candidates.length; index += 1) ...[
              _RecommendationTile(
                candidate: candidates[index],
                photoIndex: index,
                onTap: () => onCandidateSelected(candidates[index]),
                onRegisterPressed: onRegisterPressed,
                onAddCandidatePressed: onAddCandidatePressed,
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
    if (normalizedQuery.isEmpty) {
      if (selectedCategory == '전체') {
        return '지도 위에서 바로 찾아본 장소들이에요';
      }

      return '$selectedCategory 장소를 지도 위에서 확인해요';
    }

    return '"$normalizedQuery" 검색 결과를 지도 위에서 확인해요';
  }
}

class _SelectedPlaceDetailSheet extends StatelessWidget {
  const _SelectedPlaceDetailSheet({
    required this.candidate,
    required this.onBackToResults,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final PlaceCandidate candidate;
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
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final PlaceCandidate candidate;
  final int photoIndex;
  final VoidCallback onTap;
  final VoidCallback onRegisterPressed;
  final VoidCallback onAddCandidatePressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              _PlacePhoto(candidate: candidate, index: photoIndex),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${candidate.category} · ${candidate.travelTimeLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        for (final tag in candidate.tags.take(2))
                          OnmuChip(label: tag),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlaceActionButtons(
            candidateId: candidate.id,
            onAddCandidatePressed: onAddCandidatePressed,
            onRegisterPressed: onRegisterPressed,
          ),
        ],
      ),
    );
  }
}

class _PlaceActionButtons extends StatelessWidget {
  const _PlaceActionButtons({
    required this.candidateId,
    required this.onAddCandidatePressed,
    required this.onRegisterPressed,
  });

  static const _buttonHeight = 52.0;

  final int candidateId;
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
              label: '후보에 추가',
              icon: Icons.favorite_border,
              onPressed: onAddCandidatePressed,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SizedBox(
            key: ValueKey('place-action-$candidateId-schedule'),
            height: _buttonHeight,
            child: OnmuPrimaryButton(
              label: '일정에 추가',
              icon: Icons.event_available_outlined,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: onRegisterPressed,
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
          height: 72,
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
                  bottom: 10,
                  child: Icon(
                    _photoIcon,
                    color: AppColors.textInverse,
                    size: 28,
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
