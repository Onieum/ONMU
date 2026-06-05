import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
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
  final _titleController = TextEditingController(text: '제주도 여행 장소 투표');
  final _deadlineDateController = TextEditingController(text: '2026.06.08');
  final _deadlineTimeController = TextEditingController(text: '18:00');
  final Set<int> _selectedCandidateIds = {};
  var _voteMode = '단일 선택';

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineDateController.dispose();
    _deadlineTimeController.dispose();
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
        if (_selectedCandidateIds.isEmpty) {
          _selectedCandidateIds.addAll(
            state.candidates.map((candidate) => candidate.id),
          );
        }

        return _buildContent(context, state.candidates);
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

  Widget _buildContent(BuildContext context, List<PlaceCandidate> candidates) {
    final provider = placeCandidatesViewModelProvider((
      groupId: widget.groupId,
      planId: widget.planId,
    ));

    return OnmuScaffold(
      title: '투표 만들기',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuPrimaryButton(
        label: '투표 만들기',
        icon: Icons.how_to_vote_outlined,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: _selectedCandidateIds.isEmpty
            ? null
            : () async {
                final voteId = await ref
                    .read(provider.notifier)
                    .createPlaceVote(
                      title: _titleController.text,
                      modeLabel: _voteMode,
                      deadlineDate: _deadlineDateController.text,
                      deadlineTime: _deadlineTimeController.text,
                      selectedCandidateIds: _selectedCandidateIds,
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
              Text('투표 방식', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final label in const ['단일 선택', '중복 선택'])
                    GestureDetector(
                      onTap: () => setState(() => _voteMode = label),
                      child: OnmuChip(
                        label: label,
                        icon: label == '단일 선택'
                            ? Icons.radio_button_checked
                            : Icons.checklist_rounded,
                        selected: _voteMode == label,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
                  Expanded(
                    child: TextFormField(
                      controller: _deadlineDateController,
                      decoration: const InputDecoration(
                        labelText: '마감 날짜',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _deadlineTimeController,
                      decoration: const InputDecoration(
                        labelText: '마감 시간',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '직접 입력한 날짜와 시간으로 투표가 마감돼요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('투표 후보', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in candidates) ...[
          _VoteCandidateTile(
            candidate: candidate,
            selected: _selectedCandidateIds.contains(candidate.id),
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
