import '../../core/api/onmu_api_client.dart';
import 'character_model.dart';
import '../utils/character_draft_json.dart';
import '../utils/onmu_profile_image.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.timeLabel,
    required this.payload,
    required this.isRead,
    this.readAt,
    this.groupId,
    this.planId,
    this.senderName = '',
    this.senderProfileImageUrl = '',
    this.senderCharacter,
  });

  factory NotificationItem.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = defaultOnmuApiBaseUrl,
  }) {
    final payload = OnmuJson.asMap(json['payload']);
    final createdAt = DateTime.tryParse(OnmuJson.readString(json, 'createdAt'));
    final notificationType = OnmuJson.readString(
      json,
      'notificationType',
      OnmuJson.readString(json, 'type', 'notification'),
    );
    final senderName =
        _readOptionalString(json, payload, 'senderName') ??
        _readOptionalString(json, payload, 'senderDisplayName') ??
        '';
    return NotificationItem(
      id: OnmuJson.readString(json, 'id'),
      notificationType: notificationType,
      title: OnmuJson.readString(json, 'title', '새 알림이 있어요'),
      body: OnmuJson.readString(json, 'body'),
      status: OnmuJson.readString(json, 'status', 'queued'),
      readAt: DateTime.tryParse(OnmuJson.readString(json, 'readAt')),
      createdAt: createdAt,
      timeLabel: _localTimeLabel(
        createdAt,
        OnmuJson.readString(json, 'timeLabel'),
      ),
      groupId: _readOptionalString(json, payload, 'groupId'),
      planId: _readOptionalString(json, payload, 'planId'),
      payload: Map.unmodifiable(payload),
      senderName: senderName,
      senderProfileImageUrl: resolveOnmuProfileImageUrl(
        _payloadBackedJson(json, payload),
        primaryKey: 'senderProfileImageUrl',
        baseUrl: baseUrl,
      ),
      senderCharacter: characterDraftFromJson(
        json['senderPixelCharacter'] ??
            payload['senderPixelCharacter'] ??
            json['pixelCharacter'] ??
            payload['pixelCharacter'],
        nickname: senderName.isEmpty ? 'ONMU' : senderName,
      ),
      isRead: OnmuJson.readBool(
        json,
        'isRead',
        OnmuJson.readString(json, 'readAt').isNotEmpty,
      ),
    );
  }

  final String id;
  final String notificationType;
  final String title;
  final String body;
  final String status;
  final DateTime? readAt;
  final DateTime? createdAt;
  final String timeLabel;
  final String? groupId;
  final String? planId;
  final Map<String, dynamic> payload;
  final String senderName;
  final String senderProfileImageUrl;
  final CharacterDraft? senderCharacter;
  final bool isRead;

  bool get hasSenderIdentity =>
      senderName.trim().isNotEmpty ||
      senderProfileImageUrl.trim().isNotEmpty ||
      senderCharacter != null;

  NotificationItem copyWith({String? status, DateTime? readAt, bool? isRead}) {
    return NotificationItem(
      id: id,
      notificationType: notificationType,
      title: title,
      body: body,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      timeLabel: timeLabel,
      groupId: groupId,
      planId: planId,
      payload: payload,
      senderName: senderName,
      senderProfileImageUrl: senderProfileImageUrl,
      senderCharacter: senderCharacter,
      isRead: isRead ?? this.isRead,
    );
  }

  NotificationItem markRead({DateTime? readAt}) {
    return copyWith(
      status: 'read',
      readAt: readAt ?? this.readAt ?? DateTime.now(),
      isRead: true,
    );
  }

  String? payloadString(String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _readOptionalString(
    Map<String, dynamic> json,
    Map<String, dynamic> payload,
    String key,
  ) {
    final direct = OnmuJson.readString(json, key);
    if (direct.isNotEmpty) {
      return direct;
    }
    final fallback = payload[key]?.toString().trim() ?? '';
    return fallback.isEmpty ? null : fallback;
  }
}

Map<String, dynamic> _payloadBackedJson(
  Map<String, dynamic> json,
  Map<String, dynamic> payload,
) {
  return {...payload, ...json};
}

String _localTimeLabel(DateTime? value, String fallback) {
  if (value == null) {
    return fallback;
  }
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class NotificationPreferenceItem {
  const NotificationPreferenceItem({
    required this.notificationType,
    required this.channel,
    required this.enabled,
    this.quietHours = const {},
  });

  factory NotificationPreferenceItem.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceItem(
      notificationType: OnmuJson.readString(json, 'notificationType'),
      channel: OnmuJson.readString(json, 'channel'),
      enabled: OnmuJson.readBool(json, 'enabled', true),
      quietHours: Map.unmodifiable(OnmuJson.asMap(json['quietHours'])),
    );
  }

  final String notificationType;
  final String channel;
  final bool enabled;
  final Map<String, dynamic> quietHours;

  NotificationPreferenceItem copyWith({bool? enabled}) {
    return NotificationPreferenceItem(
      notificationType: notificationType,
      channel: channel,
      enabled: enabled ?? this.enabled,
      quietHours: quietHours,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'notificationType': notificationType,
      'channel': channel,
      'enabled': enabled,
      'quietHours': quietHours,
    };
  }
}

class NotificationPreferences {
  const NotificationPreferences({required this.items});

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final rawItems = json['preferences'];
    final items = rawItems is List
        ? rawItems
              .map(
                (item) =>
                    NotificationPreferenceItem.fromJson(OnmuJson.asMap(item)),
              )
              .toList(growable: false)
        : const <NotificationPreferenceItem>[];
    return NotificationPreferences(items: items);
  }

  final List<NotificationPreferenceItem> items;

  bool enabledFor(String notificationType, String channel) {
    for (final item in items) {
      if (item.notificationType == notificationType &&
          item.channel == channel) {
        return item.enabled;
      }
    }
    return true;
  }

  NotificationPreferences replace({
    required String notificationType,
    required String channel,
    required bool enabled,
  }) {
    var replaced = false;
    final updated = <NotificationPreferenceItem>[];
    for (final item in items) {
      if (item.notificationType == notificationType &&
          item.channel == channel) {
        updated.add(item.copyWith(enabled: enabled));
        replaced = true;
      } else {
        updated.add(item);
      }
    }
    if (!replaced) {
      updated.add(
        NotificationPreferenceItem(
          notificationType: notificationType,
          channel: channel,
          enabled: enabled,
        ),
      );
    }
    return NotificationPreferences(items: List.unmodifiable(updated));
  }
}
