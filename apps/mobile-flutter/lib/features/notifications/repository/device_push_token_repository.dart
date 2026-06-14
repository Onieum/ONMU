import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/device_push_token_models.dart';

final devicePushTokenRepositoryProvider = Provider<DevicePushTokenRepository>((
  ref,
) {
  return ApiDevicePushTokenRepository(ref.watch(onmuApiClientProvider));
});

final devicePushTokenSourceProvider = Provider<DevicePushTokenSource>((ref) {
  return const NoopDevicePushTokenSource();
});

final pushTokenRegistrationCoordinatorProvider =
    Provider<PushTokenRegistrationCoordinator>((ref) {
      return PushTokenRegistrationCoordinator(
        repository: ref.watch(devicePushTokenRepositoryProvider),
        tokenSource: ref.watch(devicePushTokenSourceProvider),
      );
    });

abstract interface class DevicePushTokenRepository {
  Future<DevicePushTokenRegistration> register(DevicePushToken token);

  Future<DevicePushTokenRegistration> deactivate(DevicePushToken token);
}

class ApiDevicePushTokenRepository implements DevicePushTokenRepository {
  ApiDevicePushTokenRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<DevicePushTokenRegistration> register(DevicePushToken token) async {
    final response = await _client.postObject(
      '/api/v1/devices/push-token',
      body: token.toJson(),
    );
    return DevicePushTokenRegistration.fromJson(response);
  }

  @override
  Future<DevicePushTokenRegistration> deactivate(DevicePushToken token) async {
    final response = await _client.deleteObject(
      '/api/v1/devices/push-token',
      body: token.toJson(),
    );
    return DevicePushTokenRegistration.fromJson(response);
  }
}

abstract interface class DevicePushTokenSource {
  Future<DevicePushToken?> currentToken();
}

class NoopDevicePushTokenSource implements DevicePushTokenSource {
  const NoopDevicePushTokenSource();

  @override
  Future<DevicePushToken?> currentToken() async => null;
}

class PushTokenRegistrationCoordinator {
  const PushTokenRegistrationCoordinator({
    required this.repository,
    required this.tokenSource,
  });

  final DevicePushTokenRepository repository;
  final DevicePushTokenSource tokenSource;

  Future<DevicePushTokenSyncResult> registerCurrentDevice() async {
    final token = await tokenSource.currentToken();
    if (token == null) {
      return const DevicePushTokenSyncResult.skipped(
        'push_token_source_unavailable',
      );
    }
    try {
      final registration = await repository.register(token);
      return DevicePushTokenSyncResult.synced(registration);
    } catch (error, stackTrace) {
      debugPrint('Push token registration failed: ${error.runtimeType}');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'onmu push token registration',
          context: ErrorDescription('registering a device push token'),
        ),
      );
      return const DevicePushTokenSyncResult.failed(
        'push_token_register_failed',
      );
    }
  }

  Future<DevicePushTokenSyncResult> deactivateCurrentDevice() async {
    final token = await tokenSource.currentToken();
    if (token == null) {
      return const DevicePushTokenSyncResult.skipped(
        'push_token_source_unavailable',
      );
    }
    try {
      final registration = await repository.deactivate(token);
      return DevicePushTokenSyncResult.synced(registration);
    } catch (error, stackTrace) {
      debugPrint('Push token deactivation failed: ${error.runtimeType}');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'onmu push token registration',
          context: ErrorDescription('deactivating a device push token'),
        ),
      );
      return const DevicePushTokenSyncResult.failed(
        'push_token_deactivate_failed',
      );
    }
  }
}
