import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/home/repository/home_repository.dart';

void main() {
  test(
    'home summary plan avatars keep profile image aliases and character',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.onmu.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            switch (options.path) {
              case '/api/v1/home/summary':
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    data: {
                      'groups': const [],
                      'upcomingPlans': const [],
                      'activePlan': {
                        'id': 101,
                        'groupId': 1,
                        'title': '오늘 약속',
                        'dateLabel': '6월 25일',
                        'placeName': '수원',
                        'status': 'scheduled',
                        'memberCount': 1,
                        'startsAt': DateTime.now().toUtc().toIso8601String(),
                        'participants': const [
                          {
                            'name': '박진희',
                            'profilePhotoUrl': '/media/avatar.png',
                            'pixelCharacter': {
                              'gender': 'female',
                              'skinTone': 'skin_1',
                              'hairStyle': 'hair_style_3',
                              'hairColor': 'hair_color_4',
                              'eyeStyle': 'eye_style_1',
                              'eyeColor': 'eye_color_2',
                              'clothes': 'top_2',
                            },
                          },
                        ],
                      },
                    },
                  ),
                );
                return;
              default:
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Object?>(
                      requestOptions: options,
                      statusCode: 500,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
                return;
            }
          },
        ),
      );

      final repository = ApiHomeRepository(OnmuApiClient(dio));

      final summary = await repository.fetchSummary();
      final avatar = summary.activePlan!.memberAvatars.single;

      expect(avatar.name, '박진희');
      expect(avatar.profileImageUrl, 'https://api.onmu.test/media/avatar.png');
      expect(avatar.character, isNotNull);
      expect(avatar.character?.hairStyleIndex, 3);
      expect(avatar.character?.nickname, '박진희');
    },
  );

  test(
    'falls back to group summary when home summary endpoint is missing',
    () async {
      final requestedPaths = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            switch (options.path) {
              case '/api/v1/home/summary':
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Object?>(
                      requestOptions: options,
                      statusCode: 404,
                      data: {'status': 404, 'error': 'Not Found'},
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
                return;
              case '/api/v1/groups':
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': '온모임',
                        'description': '테스트 모임',
                        'members': ['나', '친구'],
                      },
                    ],
                  ),
                );
                return;
              case '/api/v1/groups/1/summary':
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    data: {
                      'plans': [
                        {
                          'id': 101,
                          'groupId': 1,
                          'title': '저녁 약속',
                          'dateLabel': '6월 25일',
                          'placeName': '장소 미정',
                          'status': 'scheduled',
                          'memberCount': 2,
                          'startsAt': DateTime.now()
                              .add(const Duration(hours: 2))
                              .toUtc()
                              .toIso8601String(),
                        },
                      ],
                    },
                  ),
                );
                return;
              default:
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Object?>(
                      requestOptions: options,
                      statusCode: 500,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
                return;
            }
          },
        ),
      );

      final repository = ApiHomeRepository(OnmuApiClient(dio));

      final summary = await repository.fetchSummary();

      expect(requestedPaths, [
        '/api/v1/home/summary',
        '/api/v1/groups',
        '/api/v1/groups/1/summary',
      ]);
      expect(summary.groups.single.name, '온모임');
      expect(summary.upcomingPlans.single.title, '저녁 약속');
      expect(summary.nextPlan?.groupId, 1);
    },
  );
}
