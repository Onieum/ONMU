import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_date_time_picker.dart';
import '../../../../shared/widgets/onmu_location_subtitle.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/place_candidates_view_model.dart';

class PlaceVoteCreatePage extends ConsumerStatefulWidget {
  const PlaceVoteCreatePage({
    required this.groupId,
    required this.planId,
    super.key,
  });

  final String groupId;
  final String planId;

  @override
  ConsumerState<PlaceVoteCreatePage> createState() =>
      _PlaceVoteCreatePageState();
}

class _PlaceVoteCreatePageState extends ConsumerState<PlaceVoteCreatePage> {
  final _titleController = TextEditingController();
  late DateTime _deadlineAt = _initialDeadlineAt();
  final Set<int> _selectedCandidateIds = {};
  var _titleSeeded = false;
  static const _voteMode = '단일 선택';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
      data: (state) {
        _seedTitleFromPlan(state.planTitle);
        return _buildContent(context, state);
      },
      loading: () => const OnmuScaffold(
        title: '투표 만들기',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '투표 만들기',
        children: [
          Text(
            '투표 후보를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlaceCandidatesState state) {
    final provider = placeCandidatesViewModelProvider((
      groupId: widget.groupId,
      planId: widget.planId,
    ));
    final candidates = state.candidates;
    final candidateIds = candidates.map((candidate) => candidate.id).toSet();
    final selectedCandidateIds = _selectedCandidateIds.intersection(
      candidateIds,
    );
    final hasSelectedCandidates = selectedCandidateIds.isNotEmpty;

    return OnmuScaffold(
      title: '투표 만들기',
      titleSubtitle: OnmuLocationSubtitle(location: state.planLocation),
      showBackButton: true,
      onBack: () => context.popOrGo(
        RoutePaths.planPlaceCandidates(widget.groupId, widget.planId),
      ),
      bottom: OnmuPrimaryButton(
        label: '투표 만들기',
        icon: Icons.how_to_vote_outlined,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: !hasSelectedCandidates
            ? null
            : () async {
                final voteId = await ref
                    .read(provider.notifier)
                    .createPlaceVote(
                      title: _titleController.text,
                      modeLabel: _voteMode,
                      deadlineDate: _formatDate(_deadlineAt),
                      deadlineTime: _formatTime(_deadlineAt),
                      selectedCandidateIds: selectedCandidateIds,
                    );
                if (!context.mounted) {
                  return;
                }
                context.go(
                  RoutePaths.planVote(widget.groupId, widget.planId, voteId),
                );
              },
      ),
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '투표 제목',
            hintText: '투표 제목을 입력해 주세요',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('마감일', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '마감 날짜와 시간',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSub),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _formatDeadlineLabel(_deadlineAt),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _pickDeadline(context),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: const Text('선택'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '캘린더에서 날짜와 시간을 함께 선택해 투표 마감일을 정해요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                '투표 후보',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            OutlinedButton.icon(
              onPressed: candidates.isEmpty
                  ? null
                  : () => _openCandidatePicker(context, candidates),
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('장소 후보 리스트에서 추가'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasSelectedCandidates)
          _EmptyVoteCandidateCard(candidatesAvailable: candidates.isNotEmpty)
        else
          for (final candidate in candidates.where(
            (candidate) => selectedCandidateIds.contains(candidate.id),
          )) ...[
            _VoteCandidateTile(
              candidate: candidate,
              selected: true,
              onChanged: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCandidateIds.add(candidate.id);
                  } else {
                    _selectedCandidateIds.remove(candidate.id);
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  void _seedTitleFromPlan(String planTitle) {
    if (_titleSeeded) {
      return;
    }
    final normalizedTitle = planTitle.trim();
    _titleController.text = normalizedTitle.isEmpty
        ? '장소 투표'
        : '$normalizedTitle 장소 투표';
    _titleSeeded = true;
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final picked = await OnmuDateTimePicker.show(
      context: context,
      initialDateTime: _deadlineAt,
      title: '마감 날짜와 시간',
    );
    if (picked == null) {
      return;
    }
    setState(() => _deadlineAt = picked);
  }

  String _formatDeadlineLabel(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  String _formatDate(DateTime dateTime) {
    return [
      dateTime.year.toString().padLeft(4, '0'),
      dateTime.month.toString().padLeft(2, '0'),
      dateTime.day.toString().padLeft(2, '0'),
    ].join('.');
  }

  String _formatTime(DateTime dateTime) {
    return [
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
    ].join(':');
  }

  static DateTime _initialDeadlineAt() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 18);
  }

  Future<void> _openCandidatePicker(
    BuildContext context,
    List<PlaceCandidate> candidates,
  ) async {
    final selectedIds = await showModalBottomSheet<Set<int>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _VoteCandidatePickerSheet(
        candidates: candidates,
        initialSelectedIds: _selectedCandidateIds,
      ),
    );
    if (selectedIds == null) {
      return;
    }
    setState(() {
      _selectedCandidateIds
        ..clear()
        ..addAll(selectedIds);
    });
  }
}

class _EmptyVoteCandidateCard extends StatelessWidget {
  const _EmptyVoteCandidateCard({required this.candidatesAvailable});

  final bool candidatesAvailable;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        children: [
          const Icon(Icons.how_to_vote_outlined, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              candidatesAvailable
                  ? '투표에 올릴 후보를 추가해 주세요.'
                  : '투표에 올릴 장소 후보 리스트가 비어있어요.',
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

class _VoteCandidatePickerSheet extends StatefulWidget {
  const _VoteCandidatePickerSheet({
    required this.candidates,
    required this.initialSelectedIds,
  });

  final List<PlaceCandidate> candidates;
  final Set<int> initialSelectedIds;

  @override
  State<_VoteCandidatePickerSheet> createState() =>
      _VoteCandidatePickerSheetState();
}

class _VoteCandidatePickerSheetState extends State<_VoteCandidatePickerSheet> {
  late final Set<int> _selectedIds = {...widget.initialSelectedIds};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('투표 후보 추가', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '장소 후보 리스트에서 투표에 올릴 후보를 선택해 주세요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.candidates.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final candidate = widget.candidates[index];
                  final selected = _selectedIds.contains(candidate.id);
                  return _VoteCandidateTile(
                    candidate: candidate,
                    selected: selected,
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          _selectedIds.add(candidate.id);
                        } else {
                          _selectedIds.remove(candidate.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OnmuPrimaryButton(
              label: '추가 완료',
              icon: Icons.check_rounded,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: () => Navigator.of(
                context,
              ).pop(Set<int>.unmodifiable(_selectedIds)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteCandidateTile extends StatelessWidget {
  const _VoteCandidateTile({
    required this.candidate,
    required this.selected,
    required this.onChanged,
  });

  final PlaceCandidate candidate;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: selected
          ? AppColors.primaryPinkSoft
          : AppColors.bgDefault,
      borderColor: selected ? AppColors.linePink : AppColors.lineSoft,
      onTap: () => onChanged(!selected),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            activeColor: AppColors.primaryPink,
            onChanged: (value) => onChanged(value ?? false),
          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
