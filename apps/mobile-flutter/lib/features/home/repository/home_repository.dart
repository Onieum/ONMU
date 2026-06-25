import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/error/onmu_exception.dart';
import '../../../shared/models/group_models.dart';
import '../../../shared/utils/character_draft_json.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../../../shared/utils/onmu_profile_image.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return ApiHomeRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class HomeRepository {
  Future<HomeSummary> fetchSummary();
}

class HomeSummary {
  const HomeSummary({
    required this.groups,
    required this.upcomingPlans,
    this.nextPlan,
    this.activePlan,
    this.settlementId = '',
  });

  final List<GroupSummary> groups;
  final List<GroupPlanSummary> upcomingPlans;
  final GroupPlanSummary? nextPlan;
  final GroupPlanSummary? activePlan;
  final String settlementId;
}

class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<HomeSummary> fetchSummary() async {
    try {
      final response = await _client.getObject('/api/v1/home/summary');
      return _homeSummary(response);
    } on OnmuApiException catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }
      return _legacyHomeSummary();
    }
  }

  Future<HomeSummary> _legacyHomeSummary() async {
    final groups = (await _client.getList(
      '/api/v1/groups',
    )).map(_groupSummary).toList(growable: false);
    final plans = <GroupPlanSummary>[];

    for (final group in groups) {
      try {
        final summary = await _client.getObject(
          '/api/v1/groups/${group.id}/summary',
        );
        plans.addAll(
          OnmuJson.asMapList(
            summary['plans'],
          ).map((plan) => _groupPlanSummary(plan, fallbackGroupId: group.id)),
        );
      } on OnmuApiException {
        final groupPlans = await _client.getList(
          '/api/v1/groups/${group.id}/plans',
        );
        plans.addAll(
          groupPlans.map(
            (plan) => _groupPlanSummary(plan, fallbackGroupId: group.id),
          ),
        );
      }
    }

    plans.sort(GroupPlanSummary.compareUpcoming);
    final now = DateTime.now();
    final activePlan = _firstWhereOrNull(
      plans,
      (plan) => plan.isOngoingAt(now),
    );
    final nextPlan = plans.isEmpty ? null : plans.first;
    return HomeSummary(
      groups: groups,
      upcomingPlans: List.unmodifiable(plans),
      nextPlan: nextPlan,
      activePlan: activePlan,
      settlementId: activePlan?.settlementId ?? nextPlan?.settlementId ?? '',
    );
  }

  HomeSummary _homeSummary(Map<String, dynamic> json) {
    final upcomingPlans = OnmuJson.asMapList(
      json['upcomingPlans'],
    ).map(_groupPlanSummary).toList(growable: false);
    final activePlan = _optionalPlan(json['activePlan']);
    final nextPlan = _optionalPlan(json['nextPlan']);
    return HomeSummary(
      groups: OnmuJson.asMapList(
        json['groups'],
      ).map(_groupSummary).toList(growable: false),
      upcomingPlans: upcomingPlans,
      nextPlan: nextPlan,
      activePlan: activePlan,
      settlementId: OnmuJson.readString(
        json,
        'settlementId',
        activePlan?.settlementId ?? nextPlan?.settlementId ?? '',
      ),
    );
  }

  GroupSummary _groupSummary(Map<String, dynamic> json) {
    return GroupSummary(
      id: OnmuJson.readInt(json, 'id'),
      name: OnmuJson.readString(json, 'name', '온모임'),
      description: OnmuJson.readString(json, 'description'),
      members: _memberNames(json),
      memberAvatars: _memberAvatars(json),
      lastMessage: OnmuJson.readString(json, 'lastMessage'),
      unreadCount: OnmuJson.readInt(json, 'unreadCount'),
      pinnedPlanTitle: OnmuJson.readString(json, 'pinnedPlanTitle'),
    );
  }

  List<String> _memberNames(Map<String, dynamic> json) {
    final names = OnmuJson.stringList(json['members'])
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList(growable: false);
    if (names.isNotEmpty) {
      return names;
    }
    return OnmuJson.asMapList(json['memberProfiles'])
        .map((profile) {
          return OnmuJson.readString(
            profile,
            'name',
            OnmuJson.readString(profile, 'nickname'),
          ).trim();
        })
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  List<GroupPlanMemberAvatar> _memberAvatars(Map<String, dynamic> json) {
    return OnmuJson.asMapList(
      json['memberProfiles'],
    ).map(_memberAvatar).toList(growable: false);
  }

  GroupPlanSummary? _optionalPlan(Object? raw) {
    final json = OnmuJson.asMap(raw);
    if (json.isEmpty) {
      return null;
    }
    return _groupPlanSummary(json);
  }

  GroupPlanSummary _groupPlanSummary(
    Map<String, dynamic> json, {
    int? fallbackGroupId,
  }) {
    return GroupPlanSummary(
      id: OnmuJson.readInt(json, 'id'),
      groupId: _optionalInt(json, 'groupId') ?? fallbackGroupId,
      title: OnmuJson.readString(json, 'title', '약속'),
      dateLabel: OnmuJson.readString(json, 'dateLabel', '일정 미정'),
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
      endsAt: DateTime.tryParse(OnmuJson.readString(json, 'endsAt')),
      placeName: OnmuJson.readString(json, 'placeName', '장소 미정'),
      statusLabel: OnmuJson.readString(
        json,
        'statusLabel',
        OnmuJson.readString(json, 'status', '예정'),
      ),
      statusType: OnmuJson.readString(json, 'status', '예정'),
      memberCount: OnmuJson.readInt(json, 'memberCount', 1),
      extraMemberCount: OnmuJson.readInt(json, 'extraMemberCount'),
      iconKind: OnmuJson.readString(json, 'iconKind', 'coffee'),
      isPast: OnmuJson.readBool(json, 'isPast'),
      memberAvatars: _planMemberAvatars(json),
      settlementId: OnmuJson.readString(json, 'settlementId'),
    );
  }

  int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  List<GroupPlanMemberAvatar> _planMemberAvatars(Map<String, dynamic> json) {
    final memberProfiles = OnmuJson.asMapList(json['memberProfiles']);
    final participants = OnmuJson.asMapList(json['participants']);
    final members = OnmuJson.asMapList(json['members']);
    final profiles = memberProfiles.isNotEmpty
        ? memberProfiles
        : participants.isNotEmpty
        ? participants
        : members;
    return profiles.map(_memberAvatar).toList(growable: false);
  }

  GroupPlanMemberAvatar _memberAvatar(Map<String, dynamic> profile) {
    final name = resolveOnmuDisplayName([
      OnmuJson.readString(profile, 'name'),
      OnmuJson.readString(profile, 'nickname'),
    ], fallback: '참여자');
    return GroupPlanMemberAvatar(
      name: name,
      profileImageUrl: resolveOnmuProfileImageUrl(
        profile,
        baseUrl: _client.baseUrl,
      ),
      character: characterDraftFromJson(
        profile['pixelCharacter'],
        nickname: name,
      ),
    );
  }

  GroupPlanSummary? _firstWhereOrNull(
    List<GroupPlanSummary> plans,
    bool Function(GroupPlanSummary plan) test,
  ) {
    for (final plan in plans) {
      if (test(plan)) {
        return plan;
      }
    }
    return null;
  }
}
