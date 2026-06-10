import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/auth/repository/auth_repository.dart';

void main() {
  test('maps the current dev user from users me API', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/v1/users/me');
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'databaseId': '00000000-0000-0000-0000-000000000001',
                'id': 'user-me',
                'displayName': '나',
                'email': 'me@example.test',
                'profileImageUrl': 'dev/avatars/user-me.png',
                'onboardingStatus': 'COMPLETED',
                'authProvider': 'NAVER',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final user = await repository.fetchCurrentUser();

    expect(user, isNotNull);
    expect(user!.id, '00000000-0000-0000-0000-000000000001');
    expect(user.publicId, 'user-me');
    expect(user.displayName, '나');
    expect(user.onboardingStatus, 'COMPLETED');
    expect(user.hasCompletedOnboarding, isTrue);
  });

  test('maps fallback user name fields when displayName is absent', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'databaseId': '00000000-0000-0000-0000-000000000001',
                'id': 'user-me',
                'nickname': '지무',
                'email': 'me@example.test',
                'authProvider': 'NAVER',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final user = await repository.fetchCurrentUser();

    expect(user, isNotNull);
    expect(user!.displayName, '지무');
  });

}
