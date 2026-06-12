import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';

void main() {
  test('maps group member profile image urls from API', () async {
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
                  'profileImageUrl': 'https://example.test/jiwoo.png',
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
    expect(members.single.name, '지우');
    expect(members.single.profileImageUrl, 'https://example.test/jiwoo.png');
  });
}
