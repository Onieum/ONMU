import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

void main() {
  test(
    'createGroup sends description and selected member names to API',
    () async {
      final requestedBodies = <Map<String, dynamic>>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedBodies.add(Map<String, dynamic>.from(options.data as Map));
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'id': 4,
                  'name': '초대 테스트 모임',
                  'description': '같이 갈 친구들',
                  'members': ['은지', '태호'],
                },
              ),
            );
          },
        ),
      );
      final repository = ApiGroupRepository(OnmuApiClient(dio));

      final group = await repository.createGroup(
        GroupCreateInput(
          name: '초대 테스트 모임',
          description: '같이 갈 친구들',
          memberNames: const ['은지', '태호'],
        ),
      );

      expect(requestedBodies.single, {
        'name': '초대 테스트 모임',
        'description': '같이 갈 친구들',
        'memberNames': ['은지', '태호'],
      });
      expect(group.members, ['은지', '태호']);
    },
  );

  test('updateGroup patches name and description through Spring API', () async {
    final requestedPaths = <String>[];
    final requestedBodies = <Map<String, dynamic>>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestedBodies.add(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 4,
                'name': '새 모임 이름',
                'description': '새 소개',
                'members': ['나'],
              },
            ),
          );
        },
      ),
    );
    final repository = ApiGroupRepository(OnmuApiClient(dio));

    final group = await repository.updateGroup(
      groupId: 4,
      name: '새 모임 이름',
      description: '새 소개',
    );

    expect(requestedPaths.single, '/api/v1/groups/4');
    expect(requestedBodies.single, {'name': '새 모임 이름', 'description': '새 소개'});
    expect(group.name, '새 모임 이름');
    expect(group.description, '새 소개');
  });

  test('addMember posts DB userId and maps returned member profile', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'userId': '00000000-0000-0000-0000-000000000002',
                'nickname': '박진희',
                'note': '멤버',
                'statusLabel': '참여 중',
                'profileImageUrl': 'https://cdn.onmu.test/profile.png',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiGroupRepository(OnmuApiClient(dio));

    final member = await repository.addMember(
      groupId: 4,
      userId: '00000000-0000-0000-0000-000000000002',
    );

    expect(requests.single.path, '/api/v1/groups/4/members');
    expect(requests.single.method, 'POST');
    expect(requests.single.data, {
      'userId': '00000000-0000-0000-0000-000000000002',
    });
    expect(member.userId, '00000000-0000-0000-0000-000000000002');
    expect(member.name, '박진희');
  });

  test(
    'does not synthesize Spring API copy for missing group fields',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {'id': 4, 'name': '대학 동기 여행단'},
                ],
              ),
            );
          },
        ),
      );
      final repository = ApiGroupRepository(OnmuApiClient(dio));

      final groups = await repository.fetchGroups();

      expect(groups.single.description, isEmpty);
      expect(groups.single.lastMessage, isEmpty);
      expect(groups.single.members, isEmpty);
      expect(groups.single.pinnedPlanTitle, isEmpty);
    },
  );

  test(
    'fetchVotes keeps description empty when vote options are missing',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {
                    'id': 501,
                    'title': '제주도 여행 장소 투표',
                    'targetType': 'PLAN',
                    'targetId': '101',
                    'participantCount': 4,
                    'closed': false,
                    'options': [],
                  },
                ],
              ),
            );
          },
        ),
      );

      final votes = await ApiGroupRepository(
        OnmuApiClient(dio),
      ).fetchVotes(1, targetType: 'PLAN', targetId: 101);

      expect(votes.single.description, isEmpty);
      expect(votes.single.displayDescription, '등록된 투표 후보가 없어요');
      expect(votes.single.options, isEmpty);
    },
  );

  test('fetchVotes treats expired deadline as closed vote', () async {
    final expiredDeadline = DateTime.now()
        .subtract(const Duration(minutes: 1))
        .toUtc()
        .toIso8601String();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'id': 501,
                  'title': '마감 지난 장소 투표',
                  'targetType': 'PLAN',
                  'targetId': '101',
                  'participantCount': 4,
                  'closed': false,
                  'deadlineAt': expiredDeadline,
                  'options': [
                    {'label': '온무식당'},
                  ],
                },
              ],
            ),
          );
        },
      ),
    );

    final votes = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).fetchVotes(1, targetType: 'PLAN', targetId: 101);

    expect(votes.single.closed, isTrue);
    expect(votes.single.statusLabel, '마감');
    expect(votes.single.actionLabel, '결과 보기');
  });

  test('maps group member profiles into group summary avatars', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 1,
                'name': '대학 동기 여행단',
                'description': '여행 모임',
                'members': ['지민'],
                'memberProfiles': [
                  {
                    'userId': '00000000-0000-0000-0000-000000000001',
                    'name': '지민',
                    'profileImageUrl': 'dev/avatars/jiwoo.png',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final group = await ApiGroupRepository(OnmuApiClient(dio)).fetchGroup(1);

    expect(group.memberAvatars.single.name, '지민');
    expect(
      group.memberAvatars.single.profileImageUrl,
      'https://dev-api.onmu.cloud/api/v1/media/public?key=dev%2Favatars%2Fjiwoo.png',
    );
  });

  test(
    'fetchVotes can request plan scoped votes and maps participant count',
    () async {
      final requestedPaths = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {
                    'id': 501,
                    'title': '제주도 여행 장소 투표',
                    'targetType': 'PLAN',
                    'targetId': '101',
                    'participantCount': 4,
                    'participants': [
                      {
                        'nickname': '지우',
                        'profileImageUrl': 'dev/avatars/jiwoo.png',
                      },
                    ],
                    'closed': false,
                    'options': [
                      {
                        'id': 'vopt-501-1',
                        'label': '카페 오션뷰',
                        'countLabel': '3표',
                        'progress': 0.75,
                        'responseCount': 3,
                      },
                    ],
                  },
                ],
              ),
            );
          },
        ),
      );

      final votes = await ApiGroupRepository(
        OnmuApiClient(dio),
      ).fetchVotes(1, targetType: 'PLAN', targetId: 101);

      expect(
        requestedPaths.single,
        '/api/v1/groups/1/votes?targetType=PLAN&targetId=101',
      );
      expect(votes.single.participantCountLabel, '4명 참여');
      expect(votes.single.targetType, 'PLAN');
      expect(votes.single.targetId, '101');
      expect(votes.single.participantAvatars.single.name, '지우');
      expect(
        votes.single.participantAvatars.single.profileImageUrl,
        'dev/avatars/jiwoo.png',
      );
      expect(votes.single.options.single.countLabel, '3표');
      expect(votes.single.options.single.progress, 0.75);
    },
  );

  test('fetchVoteCard maps raw status to a display label', () async {
    final requestedPaths = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 501,
                'title': '제주도 여행 장소 투표',
                'status': 'open',
                'participantCount': 4,
                'targetType': 'PLAN',
                'targetId': '101',
                'options': [
                  {
                    'id': 'vopt-501-1',
                    'label': '온무식당',
                    'candidateId': '201',
                    'responseCount': 3,
                    'countLabel': '3표',
                    'progress': 0.75,
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final vote = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).fetchVoteCard(groupId: 1, voteId: 501);

    expect(requestedPaths.single, '/api/v1/groups/1/votes/501');
    expect(vote.statusLabel, 'open');
    expect(vote.displayStatusLabel, '진행 중');
    expect(vote.options.single.candidateId, '201');
    expect(vote.options.single.responseCount, 3);
  });

  test(
    'fetchVoteVoters maps option voter projections by candidate id',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'id': 501,
                  'title': '제주도 여행 장소 투표',
                  'status': 'open',
                  'options': [
                    {
                      'id': 'vopt-501-1',
                      'label': '온무식당',
                      'candidateId': '201',
                      'voters': [
                        {'nickname': '민서'},
                        {'name': '하린'},
                      ],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final voters = await ApiGroupRepository(
        OnmuApiClient(dio),
      ).fetchVoteVoters(groupId: 1, voteId: 501);

      expect(voters[201], ['민서', '하린']);
    },
  );

  test('createVote sends selected place candidate ids to Spring API', () async {
    final requestedBodies = <Map<String, dynamic>>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedBodies.add(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 501,
                'title': '제주도 여행 장소 투표',
                'targetType': 'PLAN',
                'targetId': '101',
                'participantCount': 0,
                'closed': false,
                'options': [],
              },
            ),
          );
        },
      ),
    );

    await ApiGroupRepository(OnmuApiClient(dio)).createVote(
      VoteCreateInput(
        groupId: 1,
        planId: 101,
        title: '제주도 여행 장소 투표',
        modeLabel: '단일 선택',
        deadlineDate: '2026-06-20',
        deadlineTime: '18:00',
        candidateNames: const ['카페 오션뷰'],
        placeCandidateIds: const ['201'],
      ),
    );

    expect(requestedBodies.single['placeCandidateIds'], ['201']);
    final deadlineAt = requestedBodies.single['deadlineAt'] as String?;
    expect(deadlineAt, isNotNull);
    expect(DateTime.parse(deadlineAt!).toLocal(), DateTime(2026, 6, 20, 18));
  });

  test('submitVote sends selected option id to Spring API', () async {
    final requestedPaths = <String>[];
    final requestedBodies = <Map<String, dynamic>>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestedBodies.add(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 501,
                'title': '제주도 여행 장소 투표',
                'targetType': 'PLAN',
                'targetId': '101',
                'participantCount': 1,
                'closed': false,
                'options': [
                  {
                    'id': 'vopt-501-1',
                    'label': '온무식당',
                    'candidateId': '201',
                    'responseCount': 1,
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final vote = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).submitVote(groupId: 1, voteId: 501, optionId: 'vopt-501-1');

    expect(requestedPaths.single, '/api/v1/groups/1/votes/501/responses/me');
    expect(requestedBodies.single, {'optionId': 'vopt-501-1'});
    expect(vote.participantCount, 1);
  });

  test('maps plan member profile image urls for plan cards', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'id': 101,
                  'title': '성수 브런치',
                  'dateLabel': '오늘 12:00',
                  'placeName': '성수동',
                  'status': 'scheduled',
                  'memberCount': 2,
                  'members': [
                    {
                      'nickname': '지우',
                      'profileImageUrl': 'dev/avatars/jiwoo.png',
                      'pixelCharacter': {
                        'skinTone': 'skin_2',
                        'hairStyle': 'hair_style_3',
                        'hairColor': 'hair_color_1',
                        'eyeStyle': 'eye_style_1',
                        'eyeColor': 'eye_color_2',
                        'clothes': 'top_4',
                      },
                    },
                    {
                      'name': '민수',
                      'profilePhotoUrl': 'https://example.test/minsu.png',
                    },
                  ],
                },
              ],
            ),
          );
        },
      ),
    );
    final repository = ApiGroupRepository(OnmuApiClient(dio));

    final plans = await repository.fetchPlans(1);

    expect(plans.single.memberAvatars.map((member) => member.name), [
      '지우',
      '민수',
    ]);
    expect(plans.single.memberAvatars.map((member) => member.profileImageUrl), [
      'dev/avatars/jiwoo.png',
      'https://example.test/minsu.png',
    ]);
    expect(plans.single.memberAvatars.first.character?.skinToneIndex, 2);
    expect(plans.single.memberAvatars.first.character?.hairStyleIndex, 3);
    expect(plans.single.memberAvatars.first.character?.hairColorIndex, 1);
    expect(plans.single.memberAvatars.first.character?.eyeShapeIndex, 1);
    expect(plans.single.memberAvatars.first.character?.eyeColorIndex, 2);
    expect(plans.single.memberAvatars.first.character?.topStyleIndex, 4);
  });

  test('maps plan thumbnail image url for plan cards', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'id': 101,
                  'title': '성수 브런치',
                  'dateLabel': '오늘 12:00',
                  'placeName': '성수동',
                  'status': 'scheduled',
                  'memberCount': 1,
                  'thumbnailImageUrl':
                      '/api/v1/media/public?key=dev%2Fplaces%2Fcoffee.jpg',
                },
              ],
            ),
          );
        },
      ),
    );
    final repository = ApiGroupRepository(OnmuApiClient(dio));

    final plans = await repository.fetchPlans(1);

    expect(
      plans.single.thumbnailImageUrl,
      'https://dev-api.onmu.cloud/api/v1/media/public?key=dev%2Fplaces%2Fcoffee.jpg',
    );
  });

  test('API 메시지 목록 JSON을 GroupMessage로 매핑한다', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'messages': [
                  {
                    'id': 'message-1',
                    'cursor': '2026-06-09T05:00:00Z',
                    'senderName': '지민',
                    'senderProfilePhotoUrl': 'dev/avatars/jimin.png',
                    'senderPixelCharacter': {
                      'gender': 'female',
                      'skinTone': 'skin_1',
                      'hairStyle': 'hair_style_3',
                      'hairColor': 'hair_color_2',
                      'eyeStyle': 'eye_style_1',
                      'eyeColor': 'eye_color_1',
                      'clothes': 'top_0',
                    },
                    'message': '안녕!',
                    'timeLabel': '14:00',
                    'isMine': false,
                    'attachments': [
                      {
                        'type': 'image',
                        'publicUrl':
                            '/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg',
                        'storageKey': 'records/media/photo.jpg',
                        'contentType': 'image/jpeg',
                        'fileName': 'photo.jpg',
                      },
                      {'type': 'file', 'publicUrl': '/ignored.pdf'},
                    ],
                  },
                  {
                    'sender': 'ONMU',
                    'content': '새 투표가 열렸어요.',
                    'messageType': 'vote_card',
                    'cardType': 'vote_card',
                    'targetType': 'PLAN',
                    'targetId': '101',
                    'planId': '101',
                    'voteId': '501',
                    'createdAt': '2026-06-09T14:03:00+09:00',
                  },
                  {
                    'senderName': 'ONMU',
                    'message': '성수 브런치 정산이 만들어졌어요.',
                    'messageType': 'settlement_card',
                    'cardType': 'settlement',
                    'planId': '101',
                    'settlementId': '301',
                    'isMine': false,
                  },
                  {'createdAt': 'not-a-date'},
                ],
              },
            ),
          );
        },
      ),
    );

    final messages = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).fetchMessages('1');

    expect(requestedPaths.single, '/api/v1/groups/1/chat/messages');
    expect(messages, hasLength(4));
    expect(messages[0].sender, '지민');
    expect(messages[0].message, '안녕!');
    expect(messages[0].timeLabel, '14:00');
    expect(messages[0].isMine, isFalse);
    expect(messages[0].id, 'message-1');
    expect(messages[0].cursor, '2026-06-09T05:00:00Z');
    expect(messages[0].sendStatus, GroupMessageSendStatus.sent);
    expect(
      messages[0].senderProfileImageUrl,
      'https://dev-api.onmu.cloud/api/v1/media/public?key=dev%2Favatars%2Fjimin.png',
    );
    expect(messages[0].senderCharacter?.hairStyleIndex, 3);
    expect(messages[0].attachments, hasLength(1));
    expect(messages[0].attachments.single.type, 'image');
    expect(
      messages[0].attachments.single.storageKey,
      'records/media/photo.jpg',
    );
    expect(
      messages[0].attachments.single.publicUrl,
      startsWith('https://dev-api.onmu.cloud/api/v1/media/public'),
    );
    expect(messages[1].sender, 'ONMU');
    expect(messages[1].message, '새 투표가 열렸어요.');
    expect(messages[1].timeLabel, _localTimeLabel('2026-06-09T14:03:00+09:00'));
    expect(messages[1].isMine, isFalse);
    expect(messages[1].messageType, 'vote_card');
    expect(messages[1].isVoteCard, isTrue);
    expect(messages[1].cardType, 'vote_card');
    expect(messages[1].targetType, 'PLAN');
    expect(messages[1].targetId, '101');
    expect(messages[1].planId, '101');
    expect(messages[1].voteId, '501');
    expect(messages[2].sender, 'ONMU');
    expect(messages[2].message, '성수 브런치 정산이 만들어졌어요.');
    expect(messages[2].messageType, 'settlement_card');
    expect(messages[2].cardType, 'settlement');
    expect(messages[2].planId, '101');
    expect(messages[2].settlementId, '301');
    expect(messages[2].isSettlementCard, isTrue);
    expect(messages[2].hasSettlementRoute, isTrue);
    expect(messages[3].sender, 'ONMU');
    expect(messages[3].message, '새 활동이 있어요.');
    expect(messages[3].timeLabel, '');
  });

  test('API 메시지 페이지 JSON을 cursor pagination 상태로 매핑한다', () async {
    final requestedPaths = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'messages': [
                  {
                    'id': 'message-2',
                    'cursor': '2026-06-09T05:01:00Z',
                    'senderName': '나',
                    'message': '페이지 메시지',
                    'timeLabel': '14:01',
                    'isMine': true,
                    'sendStatus': 'sent',
                  },
                ],
                'nextCursor': '2026-06-09T05:00:00Z',
                'hasMore': true,
                'unreadCount': 2,
              },
            ),
          );
        },
      ),
    );

    final page = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).fetchMessagePage('1', beforeCursor: '2026-06-09T05:02:00Z', limit: 1);

    expect(requestedPaths.single, contains('/api/v1/groups/1/chat/messages?'));
    expect(
      requestedPaths.single,
      contains('beforeCursor=2026-06-09T05%3A02%3A00Z'),
    );
    expect(requestedPaths.single, contains('limit=1'));
    expect(page.messages.single.id, 'message-2');
    expect(page.nextCursor, '2026-06-09T05:00:00Z');
    expect(page.hasMore, isTrue);
    expect(page.unreadCount, 2);
  });

  test('API 메시지 작성은 POST 응답을 GroupMessage로 매핑한다', () async {
    final requestedPaths = <String>[];
    final requestBodies = <Object?>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestBodies.add(options.data);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'senderName': '나',
                'senderProfileImageUrl': 'dev/avatars/me.png',
                'message': '서버로 보내요',
                'timeLabel': '방금',
                'isMine': true,
              },
            ),
          );
        },
      ),
    );

    final message = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).sendMessage(groupId: '1', message: '서버로 보내요');

    expect(requestedPaths.single, '/api/v1/groups/1/chat/messages');
    expect(requestBodies.single, {'message': '서버로 보내요'});
    expect(message.sender, '나');
    expect(message.senderProfileImageUrl, 'dev/avatars/me.png');
    expect(message.message, '서버로 보내요');
    expect(message.timeLabel, '방금');
    expect(message.isMine, isTrue);
  });

  test('API 첨부 메시지 작성은 request body에 attachments를 포함한다', () async {
    final requestBodies = <Object?>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestBodies.add(options.data);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'senderName': '나',
                'message': '',
                'timeLabel': '방금',
                'isMine': true,
                'attachments': [
                  {
                    'type': 'image',
                    'publicUrl':
                        '/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg',
                    'storageKey': 'records/media/photo.jpg',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final message = await ApiGroupRepository(OnmuApiClient(dio)).sendMessage(
      groupId: '1',
      message: '',
      attachments: const [
        GroupMessageAttachment(
          type: 'image',
          publicUrl: '/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg',
          storageKey: 'records/media/photo.jpg',
          contentType: 'image/jpeg',
          fileName: 'photo.jpg',
        ),
      ],
    );

    expect(requestBodies.single, {
      'message': '',
      'attachments': [
        {
          'type': 'image',
          'storageKey': 'records/media/photo.jpg',
          'publicUrl': '/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg',
          'contentType': 'image/jpeg',
          'fileName': 'photo.jpg',
          'width': null,
          'height': null,
        },
      ],
    });
    expect(message.message, isEmpty);
    expect(message.attachments.single.storageKey, 'records/media/photo.jpg');
  });

  test('API 읽음 상태 갱신은 PUT 응답의 unreadCount를 반환한다', () async {
    final requestedPaths = <String>[];
    final requestBodies = <Object?>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestBodies.add(options.data);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'lastReadMessageId': 'message-2',
                'lastReadAt': '2026-06-09T05:02:00Z',
                'unreadCount': 0,
              },
            ),
          );
        },
      ),
    );

    final unreadCount = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).markMessagesRead(groupId: '1', lastReadMessageId: 'message-2');

    expect(requestedPaths.single, '/api/v1/groups/1/chat/read-state');
    expect(requestBodies.single, {'lastReadMessageId': 'message-2'});
    expect(unreadCount, 0);
  });

  test('SSE data JSON을 GroupMessage stream으로 매핑하고 깨진 payload는 버린다', () async {
    final requestedPaths = <String>[];
    final requestedOptions = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestedOptions.add(options);
          handler.resolve(
            Response<ResponseBody>(
              requestOptions: options,
              data: ResponseBody.fromString(
                ': connected\n'
                'event: chat.message\n'
                'data: {"id":"message-3","message":"실시간 도착","senderName":"지우","timeLabel":"14:02"}\n'
                '\n'
                ': heartbeat\n'
                '\n'
                'data: {not-json\n'
                '\n'
                'data: {"id":"message-4","message":"마지막 메시지","senderName":"나","isMine":true}\n',
                200,
                headers: {
                  Headers.contentTypeHeader: ['text/event-stream'],
                },
              ),
            ),
          );
        },
      ),
    );

    final messages = await ApiGroupRepository(
      OnmuApiClient(dio),
    ).watchMessages('1', afterCursor: '2026-06-09T05:00:00Z').toList();

    expect(requestedPaths.single, contains('/api/v1/groups/1/chat/events?'));
    expect(
      requestedPaths.single,
      contains('afterCursor=2026-06-09T05%3A00%3A00Z'),
    );
    expect(requestedOptions.single.responseType, ResponseType.stream);
    expect(requestedOptions.single.receiveTimeout, Duration.zero);
    expect(messages, hasLength(2));
    expect(messages[0].id, 'message-3');
    expect(messages[0].message, '실시간 도착');
    expect(messages[1].id, 'message-4');
    expect(messages[1].isMine, isTrue);
  });

  test('plan status API enum values are displayed in Korean', () {
    expect(PlanProgressStatus.fromApi('completed').label, '완료');
    expect(PlanProgressStatus.fromApi('active').label, '진행 중');
    expect(PlanProgressStatus.fromApi('scheduled').label, '예정');
    expect(PlanProgressStatus.fromApi('진행중').label, '진행 중');
  });

  test('unknown plan status is not user-displayable', () {
    final status = PlanProgressStatus.fromApi('invalid');

    expect(status, PlanProgressStatus.unknown);
    expect(status.isDisplayable, isFalse);
    expect(status.label, isEmpty);
  });

  test('group plan summary exposes centralized Korean display status', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '6월 12일',
      placeName: '한강',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: true,
    );

    expect(plan.progressStatus, PlanProgressStatus.completed);
    expect(plan.hasDisplayStatus, isTrue);
    expect(plan.displayStatusLabel, '완료');
  });

  test('group plan summary hides unknown display status', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '6월 12일',
      placeName: '한강',
      statusLabel: 'invalid',
      statusType: 'invalid',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: false,
    );

    expect(plan.progressStatus, PlanProgressStatus.unknown);
    expect(plan.hasDisplayStatus, isFalse);
    expect(plan.displayStatusLabel, isEmpty);
  });

  test('group plan summary exposes participant summary label', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '6월 12일',
      placeName: '한강',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: false,
    );

    expect(plan.participantSummaryLabel, '2명 참여');
  });

  test('group plan summary hides empty participant summary label', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '6월 12일',
      placeName: '한강',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 0,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: false,
    );

    expect(plan.participantSummaryLabel, isEmpty);
  });

  test('group plan summary display date includes time from startsAt', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '5월 10일',
      startsAt: DateTime(2026, 5, 10, 13, 30),
      endsAt: DateTime(2026, 5, 10, 15),
      placeName: '한강',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: true,
    );

    expect(plan.displayDateTimeLabel, '5월 10일 13:30');
    expect(plan.displayTimeRangeLabel, '13:30~15:00');
  });

  test('multi-day plan exposes date-scoped time labels for today cards', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '제주 여행',
      dateLabel: '6월 19일',
      startsAt: DateTime(2026, 6, 19, 11),
      endsAt: DateTime(2026, 6, 21, 15),
      placeName: '제주',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: false,
    );

    expect(plan.displayTimeRangeLabelFor(DateTime(2026, 6, 19)), '11:00~');
    expect(plan.displayTimeRangeLabelFor(DateTime(2026, 6, 20)), '하루종일');
    expect(plan.displayTimeRangeLabelFor(DateTime(2026, 6, 21)), '~15:00');
  });

  test('multi-day plan remains a today plan on middle and end dates', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '제주 여행',
      dateLabel: '6월 19일',
      startsAt: DateTime(2026, 6, 19, 11),
      endsAt: DateTime(2026, 6, 21, 15),
      placeName: '제주',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: false,
    );

    expect(plan.isRemainingTodayAt(DateTime(2026, 6, 20, 12)), isTrue);
    expect(plan.isRemainingTodayAt(DateTime(2026, 6, 21, 14, 59)), isTrue);
    expect(plan.isRemainingTodayAt(DateTime(2026, 6, 21, 15)), isFalse);
  });

  test(
    'fetchMembers uses Spring group members endpoint with invited state',
    () async {
      final requestedPaths = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {
                    'name': '지우',
                    'note': '모임장',
                    'statusLabel': '참여 중',
                    'invited': false,
                  },
                  {
                    'name': '민수',
                    'note': '멤버',
                    'statusLabel': '초대 중',
                    'invited': true,
                  },
                ],
              ),
            );
          },
        ),
      );
      final repository = ApiGroupRepository(OnmuApiClient(dio));

      final members = await repository.fetchMembers(1);

      expect(requestedPaths.single, '/api/v1/groups/1/members');
      expect(members.first.name, '지우');
      expect(members.first.invited, isFalse);
      expect(members.last.name, '민수');
      expect(members.last.statusLabel, '초대 중');
      expect(members.last.invited, isTrue);
    },
  );

  test(
    'fetchPlanParticipantCandidates loads preference only for selected member ids',
    () async {
      final requestedPaths = <Uri>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.uri);
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {
                    'userId': '00000000-0000-0000-0000-000000000011',
                    'nickname': '찬도치',
                    'profileImageUrl': 'https://cdn.example/avatar.png',
                    'preferenceProfile': {
                      'preferredWeekdays': ['SATURDAY'],
                      'preferredTimes': ['afternoon'],
                    },
                  },
                ],
              ),
            );
          },
        ),
      );
      final repository = ApiGroupRepository(OnmuApiClient(dio));

      final candidates = await repository.fetchPlanParticipantCandidates(
        groupId: 1,
        userIds: const [
          '00000000-0000-0000-0000-000000000011',
          '00000000-0000-0000-0000-000000000011',
          '',
        ],
      );

      expect(
        requestedPaths.single.path,
        '/api/v1/groups/1/plans/participant-candidates',
      );
      expect(requestedPaths.single.queryParametersAll['userIds'], [
        '00000000-0000-0000-0000-000000000011',
      ]);
      expect(candidates.single.name, '찬도치');
      expect(
        candidates.single.profileImageUrl,
        'https://cdn.example/avatar.png',
      );
      expect(candidates.single.preferenceProfile?.preferredWeekdays, [
        'SATURDAY',
      ]);
      expect(candidates.single.preferenceProfile?.preferredTimes, [
        'afternoon',
      ]);
    },
  );

  test(
    'maps group memories from Spring API response with absolute media urls',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {
                    'id': '00000000-0000-0000-0000-000000001101',
                    'publicId': 'memory-1001',
                    'authorName': '소연',
                    'title': '성수동 카페',
                    'memo': '분위기 좋은 카페 발견!',
                    'date': '2026-06-09T13:00:00+09:00',
                    'tags': ['카페', '디저트'],
                    'imageUrls': [
                      '/api/v1/media/public?key=dev%2Fmedia%2Frecords%2Fmemory-1001%2Fimage-1.jpg',
                    ],
                  },
                ],
              ),
            );
          },
        ),
      );
      final repository = ApiGroupRepository(OnmuApiClient(dio));

      final memories = await repository.fetchMemories('1');

      expect(memories.single.id, 1001);
      expect(memories.single.apiId, 'memory-1001');
      expect(memories.single.author, '소연');
      expect(memories.single.title, '성수동 카페');
      expect(memories.single.description, '분위기 좋은 카페 발견!');
      expect(memories.single.dateLabel, '2026.06.09');
      expect(
        memories.single.imageUrls.single,
        startsWith('https://dev-api.onmu.cloud/api/v1/media/public'),
      );
    },
  );

  test('fetchMemory maps one Spring API memory detail response', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'publicId': 'memory-1004',
                'authorName': '현우',
                'title': '한강 피크닉',
                'memo': '다음에도 같이 가자!',
                'date': '2026-06-09T13:15:00+09:00',
                'tags': ['피크닉'],
                'imageUrls': [
                  '/api/v1/media/public?key=dev%2Fmedia%2Frecords%2Fmemory-1004%2Fimage-1.jpg',
                ],
              },
            ),
          );
        },
      ),
    );
    final repository = ApiGroupRepository(OnmuApiClient(dio));

    final memory = await repository.fetchMemory(
      groupId: '1',
      memoryId: 'memory-1004',
    );

    expect(requestedPaths.single, '/api/v1/groups/1/memories/memory-1004');
    expect(memory.id, 1004);
    expect(memory.routeId, 'memory-1004');
    expect(
      memory.primaryImageUrl,
      'http://127.0.0.1:8080/api/v1/media/public?key=dev%2Fmedia%2Frecords%2Fmemory-1004%2Fimage-1.jpg',
    );
  });
}

String _localTimeLabel(String value) {
  final local = DateTime.parse(value).toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
