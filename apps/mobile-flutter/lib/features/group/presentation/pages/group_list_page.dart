import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_empty_state_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/group_list_view_model.dart';
import '../widgets/group_cards.dart';

class GroupListPage extends ConsumerWidget {
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupListViewModelProvider);

    return state.when(
      data: (state) => _GroupListContent(state: state),
      loading: () => const OnmuScaffold(
        title: '온모임',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '온모임',
        children: [
          Text(
            '온모임 목록을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupListContent extends StatefulWidget {
  const _GroupListContent({required this.state});

  final GroupListState state;

  @override
  State<_GroupListContent> createState() => _GroupListContentState();
}

class _GroupListContentState extends State<_GroupListContent> {
  final _searchController = TextEditingController();

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
    super.dispose();
  }

  void _syncSearch() => setState(() {});

  List<GroupSummary> _visibleGroups() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.state.groups;
    }
    return widget.state.groups
        .where((group) {
          final haystack = [
            group.name,
            group.description,
            group.members.join(' '),
            group.pinnedPlanTitle,
            group.lastMessage,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visibleGroups = _visibleGroups();
    final searchActive = _searchController.text.trim().isNotEmpty;

    return OnmuScaffold(
      title: searchActive ? '검색 결과' : '온모임',
      pinnedHeader: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: _GroupSearchField(
          key: const ValueKey('group-list-sticky-search'),
          controller: _searchController,
          resultCount: visibleGroups.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '온모임 만들기',
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textMain,
        shape: const CircleBorder(),
        onPressed: () => context.push(RoutePaths.groupNew),
        child: const Icon(Icons.add),
      ),
      children: [
        Row(
          children: [
            Text(
              searchActive ? '검색 결과' : '내 모임',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            _GroupCountBadge(
              count: searchActive
                  ? visibleGroups.length
                  : widget.state.groupCount,
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  _showGroupListSnack(context, '최근 활동순으로 정렬된 상태예요.'),
              child: const Text('최근 활동순'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (visibleGroups.isEmpty)
          OnmuEmptyStateCard(
            title: searchActive ? '검색 결과가 없어요.' : '아직 온모임이 없어요.',
            description: searchActive
                ? '모임 이름, 멤버, 약속, 최근 대화 키워드로 다시 찾아보세요.'
                : '첫 온모임을 만들어 약속과 대화를 시작해보세요.',
            icon: searchActive
                ? Icons.search_off_outlined
                : Icons.groups_2_outlined,
          )
        else
          for (final group in visibleGroups) ...[
            GroupSummaryCard(
              group: group,
              onTap: () => context.push(RoutePaths.groupDetail(group.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: 72),
      ],
    );
  }
}

class _GroupCountBadge extends StatelessWidget {
  const _GroupCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSticker,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, size: 14, color: AppColors.primaryPink),
            const SizedBox(width: AppSpacing.xxs),
            Text('$count', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _GroupSearchField extends StatelessWidget {
  const _GroupSearchField({
    required this.controller,
    required this.resultCount,
    super.key,
  });

  final TextEditingController controller;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final searchActive = controller.text.trim().isNotEmpty;
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('group-list-search-field'),
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '모임, 멤버, 약속 검색',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textMuted,
                size: 20,
              ),
              suffixIcon: !searchActive
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: controller.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          if (searchActive) ...[
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

void _showGroupListSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
