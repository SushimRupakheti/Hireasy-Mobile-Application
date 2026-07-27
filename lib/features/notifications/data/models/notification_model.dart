import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.recipient,
    required super.type,
    required super.title,
    required super.message,
    required super.data,
    required super.actionUrl,
    required super.readAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _requiredString(json['_id'] ?? json['id'], 'notification id'),
      recipient: _string(json['recipient']),
      type: _string(json['type']),
      title: _string(json['title']),
      message: _string(json['message']),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      actionUrl: _nullableString(json['actionUrl']),
      readAt: _date(json['readAt']),
      createdAt:
          _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _date(json['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _requiredString(dynamic value, String field) {
    final result = _string(value);
    if (result.isEmpty) throw FormatException('Missing $field.');
    return result;
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableString(dynamic value) {
    final result = _string(value);
    return result.isEmpty ? null : result;
  }

  static DateTime? _date(dynamic value) {
    final text = _string(value);
    return text.isEmpty ? null : DateTime.tryParse(text)?.toLocal();
  }
}

class NotificationResponseModel {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final NotificationPagination pagination;

  const NotificationResponseModel({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });

  factory NotificationResponseModel.fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Invalid notification response.');
    }
    final map = Map<String, dynamic>.from(json);
    final rawData = map['data'];
    final rawNotifications = rawData is List
        ? rawData
        : rawData is Map
        ? rawData['notifications'] ?? rawData['data']
        : map['notifications'];
    if (rawNotifications is! List) {
      throw const FormatException('Invalid notification list.');
    }
    final rawPagination = map['pagination'] is Map
        ? Map<String, dynamic>.from(map['pagination'] as Map)
        : rawData is Map && rawData['pagination'] is Map
        ? Map<String, dynamic>.from(rawData['pagination'] as Map)
        : <String, dynamic>{};
    return NotificationResponseModel(
      notifications: rawNotifications
          .whereType<Map>()
          .map(
            (item) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      unreadCount: _int(
        map['unreadCount'] ?? (rawData is Map ? rawData['unreadCount'] : null),
      ),
      pagination: NotificationPagination(
        page: _int(rawPagination['page'], fallback: 1),
        limit: _int(rawPagination['limit'], fallback: 20),
        total: _int(rawPagination['total']),
        totalPages: _int(rawPagination['totalPages'], fallback: 1),
        hasNextPage: _bool(rawPagination['hasNextPage']),
        hasPreviousPage: _bool(rawPagination['hasPreviousPage']),
      ),
    );
  }

  NotificationResult toEntity() => NotificationResult(
    notifications: notifications,
    unreadCount: unreadCount,
    pagination: pagination,
  );

  static int _int(dynamic value, {int fallback = 0}) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

  static bool _bool(dynamic value) =>
      value == true || value?.toString().toLowerCase() == 'true';
}
