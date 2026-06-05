import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/demo_route_seeds.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class PlaceVoteCreatePage extends StatefulWidget {
  const PlaceVoteCreatePage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;

  @override
  State<PlaceVoteCreatePage> createState() => _PlaceVoteCreatePageState();
}

class _PlaceVoteCreatePageState extends State<PlaceVoteCreatePage> {
  final Set<String> _selectedCandidateIds = {
    for (final candidate in demoPlaceCandidates) candidate.id,
  };
  var _voteMode = '단일 선택';

  @override
  Widget build(BuildContext context) {
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
            : () => context.go(
                RoutePaths.planVote(
                  widget.onmoimId,
                  widget.meetupId,
                  DemoRouteSeeds.voteId,
                ),
              ),
      ),
      children: [
        TextFormField(
          initialValue: '제주도 여행 장소 투표',
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
                      initialValue: '2026.06.08',
                      decoration: const InputDecoration(
                        labelText: '마감 날짜',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      initialValue: '18:00',
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
        for (final candidate in demoPlaceCandidates) ...[
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
