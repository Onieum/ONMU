import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';

void main() {
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
