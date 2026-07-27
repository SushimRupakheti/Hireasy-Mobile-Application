import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';

class NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final NotificationPagination? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isAuthenticated;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  bool get hasNextPage => pagination?.hasNextPage == true;

  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    int? unreadCount,
    NotificationPagination? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isAuthenticated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
