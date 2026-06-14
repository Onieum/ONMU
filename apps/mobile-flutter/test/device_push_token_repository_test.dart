import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/notifications/repository/device_push_token_repository.dart';
import 'package:onmu_mobile/shared/models/device_push_token_models.dart';

void main() {
  test('register sends push token in request body only', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/api/v1/devices/push-token');
          expect(options.uri.query, isEmpty);
          expect(options.data, {
            'provider': 'fcm',
            'token': 'synthetic-fcm-token-123456',
            'platform': 'android',
            'appVersion': '1.0.0',
            'osVersion': 'android-test',
            'deviceLabel': 'Pixel',
          });
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'deviceId': 'device-1',
                'provider': 'fcm',
                'platform': 'android',
                'status': 'active',
                'registered': true,
                'tokenLast4': '3456',
                'updatedAt': '2026-06-14T01:00:00Z',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiDevicePushTokenRepository(OnmuApiClient(dio));

    final result = await repository.register(
      const DevicePushToken(
        provider: 'fcm',
        token: 'synthetic-fcm-token-123456',
        platform: 'android',
        appVersion: '1.0.0',
        osVersion: 'android-test',
        deviceLabel: 'Pixel',
      ),
    );

    expect(result.registered, isTrue);
    expect(result.deviceId, 'device-1');
    expect(result.tokenLast4, '3456');
  });

  test('deactivate sends push token in delete body', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'DELETE');
          expect(options.path, '/api/v1/devices/push-token');
          expect(options.uri.query, isEmpty);
          expect(options.data, {
            'provider': 'apns',
            'token': 'synthetic-apns-token-9999',
            'platform': 'ios',
          });
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'deviceId': 'device-2',
                'provider': 'apns',
                'platform': 'ios',
                'status': 'inactive',
                'registered': false,
                'tokenLast4': '9999',
                'updatedAt': '2026-06-14T01:00:00Z',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiDevicePushTokenRepository(OnmuApiClient(dio));

    final result = await repository.deactivate(
      const DevicePushToken(
        provider: 'apns',
        token: 'synthetic-apns-token-9999',
        platform: 'ios',
      ),
    );

    expect(result.registered, isFalse);
    expect(result.status, 'inactive');
  });

  test('coordinator skips when native push source is unavailable', () async {
    final coordinator = PushTokenRegistrationCoordinator(
      repository: _RecordingPushTokenRepository(),
      tokenSource: const NoopDevicePushTokenSource(),
    );

    final result = await coordinator.registerCurrentDevice();

    expect(result.status, 'skipped');
    expect(result.reason, 'push_token_source_unavailable');
  });

  test(
    'coordinator registers current token when source provides one',
    () async {
      final repository = _RecordingPushTokenRepository();
      final coordinator = PushTokenRegistrationCoordinator(
        repository: repository,
        tokenSource: const _StaticPushTokenSource(
          DevicePushToken(
            provider: 'fcm',
            token: 'synthetic-fcm-token-123456',
            platform: 'android',
          ),
        ),
      );

      final result = await coordinator.registerCurrentDevice();

      expect(result.isSynced, isTrue);
      expect(repository.registeredToken?.provider, 'fcm');
      expect(repository.registeredToken?.token, 'synthetic-fcm-token-123456');
    },
  );
}

class _StaticPushTokenSource implements DevicePushTokenSource {
  const _StaticPushTokenSource(this.token);

  final DevicePushToken token;

  @override
  Future<DevicePushToken?> currentToken() async => token;
}

class _RecordingPushTokenRepository implements DevicePushTokenRepository {
  DevicePushToken? registeredToken;
  DevicePushToken? deactivatedToken;

  @override
  Future<DevicePushTokenRegistration> register(DevicePushToken token) async {
    registeredToken = token;
    return const DevicePushTokenRegistration(
      deviceId: 'device-1',
      provider: 'fcm',
      platform: 'android',
      status: 'active',
      registered: true,
      tokenLast4: '3456',
    );
  }

  @override
  Future<DevicePushTokenRegistration> deactivate(DevicePushToken token) async {
    deactivatedToken = token;
    return const DevicePushTokenRegistration(
      deviceId: 'device-1',
      provider: 'fcm',
      platform: 'android',
      status: 'inactive',
      registered: false,
      tokenLast4: '3456',
    );
  }
}
