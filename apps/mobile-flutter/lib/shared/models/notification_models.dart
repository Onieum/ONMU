import '../../core/api/onmu_api_client.dart';

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
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final payload = OnmuJson.asMap(json['payload']);
    final notificationType = OnmuJson.readString(
      json,
      'notificationType',
      OnmuJson.readString(json, 'type', 'notification'),
    );
    return NotificationItem(
      id: OnmuJson.readString(json, 'id'),
      notificationType: notificationType,
      title: OnmuJson.readString(json, 'title', '새 알림이 있어요'),
      body: OnmuJson.readString(json, 'body'),
      status: OnmuJson.readString(json, 'status', 'queued'),
      readAt: DateTime.tryParse(OnmuJson.readString(json, 'readAt')),
      createdAt: DateTime.tryParse(OnmuJson.readString(json, 'createdAt')),
      timeLabel: OnmuJson.readString(json, 'timeLabel'),
      groupId: _readOptionalString(json, payload, 'groupId'),
      planId: _readOptionalString(json, payload, 'planId'),
      payload: Map.unmodifiable(payload),
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
  final bool isRead;

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
