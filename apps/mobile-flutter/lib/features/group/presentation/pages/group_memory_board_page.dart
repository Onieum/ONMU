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
import '../../../../shared/widgets/onmu_empty_state_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/group_memory_view_model.dart';
import '../widgets/group_memory_photo.dart';

class GroupMemoryBoardPage extends ConsumerWidget {
  const GroupMemoryBoardPage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupMemoryBoardViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupMemoryBoardContent(state: state),
      loading: () => const OnmuScaffold(
        title: '기록',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '기록',
        children: [
          Text(
            '모임 기록을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupMemoryBoardContent extends StatefulWidget {
  const _GroupMemoryBoardContent({required this.state});

  final GroupMemoryBoardState state;

  @override
  State<_GroupMemoryBoardContent> createState() =>
      _GroupMemoryBoardContentState();
}

enum _MemoryFilter { all, photo, cafe, travel, other }

class _GroupMemoryBoardContentState extends State<_GroupMemoryBoardContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _selectedFilter = _MemoryFilter.all;
  var _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_syncSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_syncSearch)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _syncSearch() => setState(() {});

  void _openSearch() {
    if (_isSearchVisible) {
      _searchFocusNode.requestFocus();
      return;
    }
    setState(() => _isSearchVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    if (_isSearchVisible) {
      setState(() => _isSearchVisible = false);
    }
  }

  bool _matchesSearch(GroupMemoryRecord memory, String query) {
    final haystack = [
      memory.title,
      memory.description,
      memory.author,
      memory.dateLabel,
      memory.tags.join(' '),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _matchesFilter(GroupMemoryRecord memory) {
    final normalizedTags = memory.tags
        .map((tag) => tag.trim().toLowerCase())
        .toSet();
    return switch (_selectedFilter) {
      _MemoryFilter.all => true,
      _MemoryFilter.photo => memory.imageUrls.isNotEmpty,
      _MemoryFilter.cafe => normalizedTags.contains('카페'),
      _MemoryFilter.travel => normalizedTags.contains('여행'),
      _MemoryFilter.other => normalizedTags.contains('기타'),
    };
  }

  List<GroupMemoryRecord> _visibleMemories() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.state.memories
        .where((memory) {
          final matchesQuery = query.isEmpty || _matchesSearch(memory, query);
          return matchesQuery && _matchesFilter(memory);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.state.group;
    final visibleMemories = _visibleMemories();
    final searchActive = _searchController.text.trim().isNotEmpty;
    final filtered = searchActive || _selectedFilter != _MemoryFilter.all;

    return OnmuScaffold(
      title: group.name,
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(group.id)),
      pinnedHeader: !_isSearchVisible
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: _MemorySearchCard(
                controller: _searchController,
                focusNode: _searchFocusNode,
                resultCount: visibleMemories.length,
                onClose: _closeSearch,
              ),
            ),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '기록 검색',
            onPressed: _isSearchVisible ? _closeSearch : _openSearch,
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: '기록 옵션',
            onPressed: () => context.push(RoutePaths.groupSettings(group.id)),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      useWarmBackground: false,
      children: [
        _GroupTabs(group: group),
        const SizedBox(height: AppSpacing.md),
        _MemoryFilterRow(
          selectedFilter: _selectedFilter,
          onSelected: (filter) => setState(() => _selectedFilter = filter),
        ),
        const SizedBox(height: AppSpacing.md),
        if (visibleMemories.isEmpty)
          OnmuEmptyStateCard(
            title: filtered ? '검색 결과가 없어요.' : '아직 모임 기록이 없어요.',
            description: filtered
                ? '다른 키워드나 필터로 다시 찾아보세요.'
                : '사진과 메모가 쌓이면 여기서 함께 돌아볼 수 있어요.',
            icon: filtered
                ? Icons.search_off_outlined
                : Icons.photo_album_outlined,
          )
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.63,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var index = 0; index < visibleMemories.length; index += 1)
                _MemoryCard(
                  groupId: group.id,
                  memory: visibleMemories[index],
                  photoIndex: index,
                ),
            ],
          ),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GroupTab(
          label: '약속',
          selected: false,
          onTap: () => context.push(RoutePaths.groupDetail(group.id)),
        ),
        _GroupTab(label: '기록', selected: true, onTap: () {}),
        _GroupTab(
          label: '채팅',
          selected: false,
          onTap: () => context.push(RoutePaths.groupChat(group.id)),
        ),
      ],
    );
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryPink : AppColors.lineSoft,
                width: selected ? 3 : 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryFilterRow extends StatelessWidget {
  const _MemoryFilterRow({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _MemoryFilter selectedFilter;
  final ValueChanged<_MemoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = [
      (_MemoryFilter.all, '전체'),
      (_MemoryFilter.photo, '사진'),
      (_MemoryFilter.cafe, '카페'),
      (_MemoryFilter.travel, '여행'),
      (_MemoryFilter.other, '기타'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index += 1) ...[
            _MemoryFilterChip(
              label: filters[index].$2,
              selected: selectedFilter == filters[index].$1,
              onTap: () => onSelected(filters[index].$1),
            ),
            if (index != filters.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MemoryFilterChip extends StatelessWidget {
  const _MemoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.bgDefault : AppColors.bgWarm,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.lineBrown : AppColors.lineSoft,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.textMain : AppColors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemorySearchCard extends StatelessWidget {
  const _MemorySearchCard({
    required this.controller,
    required this.focusNode,
    required this.resultCount,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int resultCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.trim().isNotEmpty;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기록 검색', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('group-memory-search-field'),
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '제목, 설명, 작성자, 태그 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: !hasQuery
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: controller.clear,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: '검색 닫기',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (hasQuery) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$resultCount개 결과',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.groupId,
    required this.memory,
    required this.photoIndex,
  });

  final int groupId;
  final GroupMemoryRecord memory;
  final int photoIndex;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () =>
          context.push(RoutePaths.groupMemoryDetail(groupId, memory.routeId)),
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxs,
              AppSpacing.xxs,
              AppSpacing.xxs,
              0,
            ),
            child: Row(
              children: [
                PixelAvatar(
                  label: memory.author,
                  size: 24,
                  profileImageUrl: memory.authorProfileImageUrl,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  memory.author,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              memory.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              memory.dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GroupMemoryPhoto(
                    index: photoIndex,
                    imageUrl: memory.primaryImageUrl,
                  ),
                  Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.bgDefault.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: photoIndex == 3
                              ? AppColors.accentRed
                              : AppColors.textInverse,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
