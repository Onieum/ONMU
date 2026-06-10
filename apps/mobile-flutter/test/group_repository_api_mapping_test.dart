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
}
