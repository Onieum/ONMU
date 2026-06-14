import '../../core/api/onmu_api_client.dart';

class DevicePushToken {
  const DevicePushToken({
    required this.provider,
    required this.token,
    this.platform = 'unknown',
    this.appVersion,
    this.osVersion,
    this.deviceLabel,
    this.deviceFingerprintHash,
  });

  final String provider;
  final String token;
  final String platform;
  final String? appVersion;
  final String? osVersion;
  final String? deviceLabel;
  final String? deviceFingerprintHash;

  Map<String, Object?> toJson() {
    return {
      'provider': provider,
      'token': token,
      'platform': platform,
      if (appVersion != null && appVersion!.trim().isNotEmpty)
        'appVersion': appVersion,
      if (osVersion != null && osVersion!.trim().isNotEmpty)
        'osVersion': osVersion,
      if (deviceLabel != null && deviceLabel!.trim().isNotEmpty)
        'deviceLabel': deviceLabel,
      if (deviceFingerprintHash != null &&
          deviceFingerprintHash!.trim().isNotEmpty)
        'deviceFingerprintHash': deviceFingerprintHash,
    };
  }
}

class DevicePushTokenRegistration {
  const DevicePushTokenRegistration({
    required this.provider,
    required this.platform,
    required this.status,
    required this.registered,
    this.deviceId,
    this.tokenLast4,
    this.updatedAt,
  });

  factory DevicePushTokenRegistration.fromJson(Map<String, dynamic> json) {
    return DevicePushTokenRegistration(
      deviceId: OnmuJson.readString(json, 'deviceId'),
      provider: OnmuJson.readString(json, 'provider'),
      platform: OnmuJson.readString(json, 'platform', 'unknown'),
      status: OnmuJson.readString(json, 'status', 'inactive'),
      registered: OnmuJson.readBool(json, 'registered'),
      tokenLast4: OnmuJson.readString(json, 'tokenLast4'),
      updatedAt: OnmuJson.readString(json, 'updatedAt'),
    );
  }

  final String? deviceId;
  final String provider;
  final String platform;
  final String status;
  final bool registered;
  final String? tokenLast4;
  final String? updatedAt;
}

class DevicePushTokenSyncResult {
  const DevicePushTokenSyncResult({
    required this.status,
    this.registration,
    this.reason,
  });

  const DevicePushTokenSyncResult.skipped(String reason)
    : this(status: 'skipped', reason: reason);

  const DevicePushTokenSyncResult.synced(
    DevicePushTokenRegistration registration,
  ) : this(status: 'synced', registration: registration);

  const DevicePushTokenSyncResult.failed(String reason)
    : this(status: 'failed', reason: reason);

  final String status;
  final DevicePushTokenRegistration? registration;
  final String? reason;

  bool get isSynced => status == 'synced';
}
