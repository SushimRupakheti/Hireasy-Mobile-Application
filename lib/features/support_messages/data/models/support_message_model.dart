import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';

class SupportMessageModel extends SupportMessageEntity {
  const SupportMessageModel({
    required super.id,
    required super.conversationId,
    required super.sender,
    required super.senderRole,
    required super.body,
    required super.readAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    final senderValue = json['sender'] ?? json['senderId'];
    final sender = senderValue is Map
        ? Map<String, dynamic>.from(senderValue)
        : <String, dynamic>{
            if (_string(senderValue).isNotEmpty) '_id': _string(senderValue),
          };
    final createdAt = _date(json['createdAt']);
    return SupportMessageModel(
      id: _required(json['_id'] ?? json['id'], 'message id'),
      conversationId: _string(
        json['conversationId'] ??
            json['conversation'] ??
            json['supportConversationId'],
      ),
      sender: sender,
      senderRole: _string(json['senderRole'] ?? sender['role'] ?? json['role']),
      body: _required(json['body'] ?? json['message'] ?? json['text'], 'body'),
      readAt: _date(json['readAt']),
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _date(json['updatedAt']) ??
          createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _required(dynamic value, String field) {
    final result = _string(value);
    if (result.isEmpty) throw FormatException('Missing $field.');
    return result;
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static DateTime? _date(dynamic value) {
    final text = _string(value);
    return text.isEmpty ? null : DateTime.tryParse(text)?.toLocal();
  }
}

class SupportMessageResponseModel {
  final List<SupportMessageModel> messages;
  final SupportMessagePagination pagination;

  const SupportMessageResponseModel({
    required this.messages,
    required this.pagination,
  });

  factory SupportMessageResponseModel.fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Invalid support message response.');
    }
    final root = Map<String, dynamic>.from(json);
    final data = root['data'];
    final rawMessages = data is List
        ? data
        : data is Map
        ? data['messages'] ?? data['data']
        : root['messages'];
    if (rawMessages is! List) {
      throw const FormatException('Invalid support message list.');
    }
    final rawPagination = root['pagination'] is Map
        ? Map<String, dynamic>.from(root['pagination'] as Map)
        : data is Map && data['pagination'] is Map
        ? Map<String, dynamic>.from(data['pagination'] as Map)
        : <String, dynamic>{};
    return SupportMessageResponseModel(
      messages: rawMessages
          .whereType<Map>()
          .map(
            (item) =>
                SupportMessageModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      pagination: SupportMessagePagination(
        page: _int(rawPagination['page'], fallback: 1),
        limit: _int(rawPagination['limit'], fallback: 30),
        total: _int(rawPagination['total']),
        totalPages: _int(rawPagination['totalPages'], fallback: 1),
        hasNextPage: _bool(rawPagination['hasNextPage']),
        hasPreviousPage: _bool(rawPagination['hasPreviousPage']),
      ),
    );
  }

  SupportMessageResult toEntity() {
    return SupportMessageResult(messages: messages, pagination: pagination);
  }

  static int _int(dynamic value, {int fallback = 0}) {
    return value is int
        ? value
        : int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _bool(dynamic value) {
    return value == true || value?.toString().toLowerCase() == 'true';
  }
}

SupportMessageModel parseSentSupportMessage(dynamic json) {
  if (json is! Map) {
    throw const FormatException('Invalid sent message response.');
  }
  final root = Map<String, dynamic>.from(json);
  dynamic data = root['data'] ?? root['message'];
  if (data is Map && data['message'] is Map) data = data['message'];
  if (data is! Map) {
    throw const FormatException('The server did not return the sent message.');
  }
  return SupportMessageModel.fromJson(Map<String, dynamic>.from(data));
}
