import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';

abstract interface class ISupportMessageRepository {
  Future<SupportMessageResult> getMessages({
    required int page,
    required int limit,
  });

  Future<SupportMessageEntity> sendMessage(String message);
  Future<void> markMessagesAsRead();
}
