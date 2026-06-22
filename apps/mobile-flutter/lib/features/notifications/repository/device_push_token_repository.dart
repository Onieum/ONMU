import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/observability/onmu_error_reporter.dart';
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
        errorReporter: ref.watch(onmuErrorReporterProvider),
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
    this.errorReporter = const FlutterOnmuErrorReporter(),
  });

  final DevicePushTokenRepository repository;
  final DevicePushTokenSource tokenSource;
  final OnmuErrorReporter errorReporter;

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
      errorReporter.captureException(
        error,
        stackTrace,
        feature: 'push_token_registration',
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
      errorReporter.captureException(
        error,
        stackTrace,
        feature: 'push_token_deactivation',
      );
      return const DevicePushTokenSyncResult.failed(
        'push_token_deactivate_failed',
      );
    }
  }
}
