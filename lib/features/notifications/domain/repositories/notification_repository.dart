import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';

abstract interface class INotificationRepository {
  Future<NotificationResult> getNotifications({
    required int page,
    required int limit,
    required bool unreadOnly,
  });

  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}
