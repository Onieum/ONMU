import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/models/preference_profile.dart';
import '../../../shared/utils/character_draft_json.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../../../shared/utils/onmu_profile_image.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return ApiPlanRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class PlanRepository {
  Future<Plan> fetchPlan({required Object groupId, required Object planId});

  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  });

  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  });

  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  });

  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  });

  Future<Plan> createPlan(PlanCreateInput input);

  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  });

  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  });
}

class ApiPlanRepository implements PlanRepository {
  ApiPlanRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    final plan = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId',
    );
    return _plan(plan);
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) async {
    final plan = await _client.postObject(
      '/api/v1/groups/${input.groupId}/plans',
      body: {
        'title': input.title.trim(),
        'startsAt': _startsAtOrNull(input.dateTime),
        'endsAt': _startsAtOrNull(input.endsAt),
        'placeName': input.location.trim(),
        'memo': input.memo.trim(),
        'participantUserIds': _participantUserIds(input.members),
      },
    );
    return _plan(plan);
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) async {
    final plan = await _client.patchObject(
      '/api/v1/groups/${input.groupId}/plans/$planId',
      body: {
        'title': input.title.trim(),
        'startsAt': _startsAtOrNull(input.dateTime),
        'endsAt': _startsAtOrNull(input.endsAt),
        'placeName': input.location.trim(),
        'memo': input.memo.trim(),
      },
    );
    return _plan(plan);
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    final places = await _client.getList(
      '/api/v1/groups/$groupId/plans/$planId/schedule-places',
    );
    final visitPlans = places
        .map(_schedulePlace)
        .map(_visitPlanForSchedulePlace)
        .toList(growable: false);
    return visitPlans.isEmpty ? const [] : [visitPlans];
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    final participants = await _client.getList(
      '/api/v1/groups/$groupId/plans/$planId/participants',
    );
    return participants.map(_participantArrival).toList(growable: false);
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) async {
    final participant = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/participants/me',
      body: {'status': 'joined', 'response': status.apiValue},
    );
    return _participantArrival(participant);
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) async {
    final participant = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/participants/me',
      body: {'status': 'left'},
    );
    return _participantArrival(participant);
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) async {
    final participant = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/participants',
      body: {'userId': userId},
    );
    return _participantArrival(participant);
  }

  Plan _plan(Map<String, dynamic> json) {
    final title = OnmuJson.readString(json, 'title', '약속');
    final location = OnmuJson.readString(json, 'placeName', '장소 미정');
    return Plan(
      id: OnmuJson.readInt(json, 'id'),
      title: title,
      dateTime: OnmuJson.readString(json, 'dateLabel', '일정 미정'),
      location: location,
      status: _canonicalPlanStatus(OnmuJson.readString(json, 'status')),
      memo: OnmuJson.readString(json, 'memo'),
      members: _planMembers(json),
      timeCandidates: const [],
      visitPlan: const [],
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
      endsAt: DateTime.tryParse(OnmuJson.readString(json, 'endsAt')),
    );
  }

  String _canonicalPlanStatus(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      '' => 'scheduled',
      'scheduled' || 'active' || 'completed' || 'cancelled' => normalized,
      _ => 'unknown',
    };
  }

  SchedulePlace _schedulePlace(Map<String, dynamic> json) {
    return SchedulePlace(
      id: OnmuJson.readString(json, 'id'),
      groupId: OnmuJson.readString(json, 'groupId'),
      planId: OnmuJson.readString(json, 'planId'),
      candidateId: OnmuJson.readString(json, 'candidateId'),
      name: OnmuJson.readString(
        json,
        'name',
        OnmuJson.readString(json, 'placeName', '일정 장소'),
      ),
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
      endsAt: DateTime.tryParse(OnmuJson.readString(json, 'endsAt')),
      note: OnmuJson.readString(json, 'note'),
      sortOrder: OnmuJson.readInt(json, 'sortOrder'),
    );
  }

  VisitPlan _visitPlanForSchedulePlace(SchedulePlace place) {
    return VisitPlan(
      id: place.id,
      candidateId: place.candidateId,
      time: _timeLabel(place.startsAt),
      endTime: _timeLabel(place.endsAt),
      place: place.name,
      kind: '',
      duration: place.note.trim(),
      startsAt: place.startsAt,
      endsAt: place.endsAt,
    );
  }

  PlanParticipantArrival _participantArrival(Map<String, dynamic> json) {
    final nickname = resolveOnmuDisplayName([
      OnmuJson.readString(json, 'nickname'),
    ], fallback: '참여자');
    return PlanParticipantArrival(
      id: OnmuJson.readString(json, 'id'),
      userId: OnmuJson.readString(json, 'userId'),
      nickname: nickname,
      participantStatus: OnmuJson.readString(json, 'status', 'joined'),
      arrivalStatus: PlanArrivalStatus.fromApi(
        OnmuJson.readString(json, 'response'),
      ),
      isFallback: OnmuJson.readBool(json, 'fallback'),
      profileImageUrl: _profileImageUrl(json),
      character: characterDraftFromJson(
        json['pixelCharacter'],
        nickname: nickname,
      ),
      preferenceProfile: _preferenceProfile(json),
    );
  }

  List<PlanMember> _planMembers(Map<String, dynamic> json) {
    final rawMembers = OnmuJson.asMapList(json['members']).isNotEmpty
        ? OnmuJson.asMapList(json['members'])
        : OnmuJson.asMapList(json['participants']);
    return rawMembers
        .map((member) {
          final name = resolveOnmuDisplayName([
            OnmuJson.readString(member, 'name'),
            OnmuJson.readString(member, 'nickname'),
          ], fallback: '참여자');
          return PlanMember(
            name: name,
            message: OnmuJson.readString(member, 'message'),
            badge: OnmuJson.readString(
              member,
              'badge',
              OnmuJson.readString(member, 'statusLabel', '참여 중'),
            ),
            selected: OnmuJson.readBool(member, 'selected', true),
            userId: OnmuJson.readString(member, 'userId'),
            profileImageUrl: _profileImageUrl(member),
            character: characterDraftFromJson(
              member['pixelCharacter'],
              nickname: name,
            ),
            preferenceProfile: _preferenceProfile(member),
          );
        })
        .toList(growable: false);
  }

  String _profileImageUrl(Map<String, dynamic> json) {
    return resolveOnmuProfileImageUrl(json, baseUrl: _client.baseUrl);
  }

  List<String> _participantUserIds(List<PlanMember> members) {
    return members
        .map((member) => member.userId.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  PreferenceProfile? _preferenceProfile(Map<String, dynamic> json) {
    final preferenceJson = OnmuJson.asMap(json['preferenceProfile']);
    if (preferenceJson.isEmpty) {
      return null;
    }
    return PreferenceProfile.fromJson(preferenceJson);
  }

  String? _startsAtOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed)?.toUtc().toIso8601String();
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
