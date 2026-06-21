import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/plan_models.dart';
import '../../group/repository/group_repository.dart';
import '../../group/view_model/group_home_view_model.dart';
import '../../group/view_model/group_list_view_model.dart';
import '../../group/view_model/group_plan_list_view_model.dart';
import '../../home/view_model/home_view_model.dart';
import '../repository/plan_repository.dart';

final planCreateControllerProvider = Provider<PlanCreateController>(
  (ref) => PlanCreateController(ref),
);

final groupPlanMemberOptionsProvider =
    FutureProvider.family<List<PlanMember>, String>((ref, groupId) async {
      final repository = ref.watch(groupRepositoryProvider);
      final members = await repository.fetchMembers(groupId);
      final options = members
          .where((member) => !member.invited && member.userId.trim().isNotEmpty)
          .map(
            (member) => PlanMember(
              userId: member.userId,
              name: member.name,
              message: member.note,
              badge: '추가 가능',
              selected: true,
              profileImageUrl: member.profileImageUrl,
              preferenceProfile: member.preferenceProfile,
            ),
          )
          .toList(growable: false);
      final missingAssetUserIds = options
          .where(_needsProfileAsset)
          .map((member) => member.userId.trim())
          .where((userId) => userId.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (missingAssetUserIds.isEmpty) {
        return options;
      }

      try {
        final enrichedMembers = await repository.fetchPlanParticipantCandidates(
          groupId: groupId,
          userIds: missingAssetUserIds,
        );
        final enrichedByUserId = {
          for (final member in enrichedMembers)
            if (member.userId.trim().isNotEmpty) member.userId.trim(): member,
        };
        return options
            .map(
              (member) => _mergeProfileAsset(
                member,
                enrichedByUserId[member.userId.trim()],
              ),
            )
            .toList(growable: false);
      } catch (_) {
        return options;
      }
    });

bool _needsProfileAsset(PlanMember member) {
  return member.profileImageUrl.trim().isEmpty && member.character == null;
}

PlanMember _mergeProfileAsset(PlanMember member, GroupMemberProfile? enriched) {
  if (enriched == null) {
    return member;
  }
  return PlanMember(
    userId: member.userId,
    name: member.name,
    message: member.message,
    badge: member.badge,
    selected: member.selected,
    profileImageUrl: enriched.profileImageUrl.trim().isNotEmpty
        ? enriched.profileImageUrl
        : member.profileImageUrl,
    character: enriched.character ?? member.character,
    preferenceProfile: member.preferenceProfile,
    fallbackToViewerCharacter: member.fallbackToViewerCharacter,
  );
}

class PlanCreateController {
  const PlanCreateController(this._ref);

  final Ref _ref;

  Future<Plan> createPlan(PlanCreateInput input) async {
    final plan = await _ref.read(planRepositoryProvider).createPlan(input);
    final groupId = input.groupId.toString();
    _ref.invalidate(groupPlanListViewModelProvider(groupId));
    _ref.invalidate(groupHomeViewModelProvider(groupId));
    _ref.invalidate(groupListViewModelProvider);
    _ref.invalidate(homeViewModelProvider);
    return plan;
  }

  Future<PlanMember> enrichParticipantCandidate({
    required String groupId,
    required PlanMember member,
  }) async {
    final userId = member.userId.trim();
    if (userId.isEmpty || member.preferenceProfile != null) {
      return member;
    }
    final candidates = await _ref
        .read(groupRepositoryProvider)
        .fetchPlanParticipantCandidates(groupId: groupId, userIds: [userId]);
    final enriched = candidates.where((candidate) {
      return candidate.userId.trim() == userId;
    }).firstOrNull;
    if (enriched == null) {
      return member;
    }
    return PlanMember(
      userId: enriched.userId,
      name: enriched.name,
      message: member.message.isNotEmpty ? member.message : enriched.note,
      badge: member.badge,
      selected: member.selected,
      profileImageUrl: enriched.profileImageUrl.isNotEmpty
          ? enriched.profileImageUrl
          : member.profileImageUrl,
      character: enriched.character ?? member.character,
      preferenceProfile: enriched.preferenceProfile,
      fallbackToViewerCharacter: member.fallbackToViewerCharacter,
    );
  }
}
