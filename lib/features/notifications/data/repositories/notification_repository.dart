import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_client.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/features/notifications/data/models/notification_model.dart';
import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:hireasy_mobile/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

class NotificationRepository implements INotificationRepository {
  final ApiClient _apiClient;

  const NotificationRepository(this._apiClient);

  @override
  Future<NotificationResult> getNotifications({
    required int page,
    required int limit,
    required bool unreadOnly,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'limit': limit, 'unreadOnly': unreadOnly},
    );
    return NotificationResponseModel.fromJson(response.data).toEntity();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.patch(ApiEndpoints.notificationRead(notificationId));
  }

  @override
  Future<void> markAllAsRead() async {
    await _apiClient.patch(ApiEndpoints.notificationsReadAll);
  }
}
