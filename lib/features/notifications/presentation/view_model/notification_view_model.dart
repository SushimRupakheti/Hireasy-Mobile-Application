import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/notifications/data/repositories/notification_repository.dart';
import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:hireasy_mobile/features/notifications/presentation/state/notification_state.dart';

final notificationViewModelProvider =
    NotifierProvider<NotificationViewModel, NotificationState>(
      NotificationViewModel.new,
    );

class NotificationViewModel extends Notifier<NotificationState> {
  static const pageSize = 20;
  String? _accountKey;
  bool _requestInFlight = false;

  @override
  NotificationState build() => const NotificationState();

  String? get _currentAccountKey {
    final tokens = ref.read(tokenServiceProvider);
    final token = tokens.token;
    if (token == null || token.isEmpty) return null;
    return '${tokens.userId ?? ''}:${token.hashCode}';
  }

  Future<void> initialize() async {
    final key = _currentAccountKey;
    if (key == null) {
      clear();
      return;
    }
    if (_accountKey != key) {
      _accountKey = key;
      state = const NotificationState(isAuthenticated: true);
    }
    await refresh(showLoading: state.notifications.isEmpty);
  }

  Future<void> refresh({bool showLoading = false}) async {
    final key = _currentAccountKey;
    if (key == null) {
      clear();
      return;
    }
    if (_accountKey != key) {
      _accountKey = key;
      state = const NotificationState(isAuthenticated: true);
      showLoading = true;
    }
    if (_requestInFlight) return;
    _requestInFlight = true;
    state = state.copyWith(
      isLoading: showLoading,
      isRefreshing: !showLoading,
      isAuthenticated: true,
      clearError: true,
    );
    try {
      final result = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(page: 1, limit: pageSize, unreadOnly: false);
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        notifications: _sortedUnique(result.notifications),
        unreadCount: result.unreadCount,
        pagination: result.pagination,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } on DioException catch (error) {
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to load notifications.',
        ),
      );
    } catch (error) {
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: error is FormatException
            ? error.message
            : 'Unable to load notifications.',
      );
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final key = _currentAccountKey;
    final pagination = state.pagination;
    if (key == null ||
        key != _accountKey ||
        _requestInFlight ||
        pagination == null ||
        !pagination.hasNextPage) {
      return;
    }
    _requestInFlight = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final result = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(
            page: pagination.page + 1,
            limit: pageSize,
            unreadOnly: false,
          );
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        notifications: _sortedUnique([
          ...state.notifications,
          ...result.notifications,
        ]),
        unreadCount: result.unreadCount,
        pagination: result.pagination,
        isLoadingMore: false,
      );
    } catch (_) {
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Unable to load more notifications.',
      );
    } finally {
      _requestInFlight = false;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    final key = _currentAccountKey;
    if (key == null || key != _accountKey) return false;
    final index = state.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index < 0 || state.notifications[index].isRead) return true;
    final previous = state;
    final updated = [...state.notifications];
    updated[index] = updated[index].copyWith(readAt: DateTime.now());
    state = state.copyWith(
      notifications: updated,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
      if (_currentAccountKey != key || _accountKey != key) return false;
      return true;
    } catch (_) {
      if (_currentAccountKey == key && _accountKey == key) state = previous;
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final key = _currentAccountKey;
    if (key == null || key != _accountKey || state.unreadCount == 0) {
      return key != null;
    }
    final previous = state;
    final now = DateTime.now();
    state = state.copyWith(
      notifications: [
        for (final notification in state.notifications)
          notification.isRead
              ? notification
              : notification.copyWith(readAt: now),
      ],
      unreadCount: 0,
    );
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      if (_currentAccountKey != key || _accountKey != key) return false;
      return true;
    } catch (_) {
      if (_currentAccountKey == key && _accountKey == key) state = previous;
      return false;
    }
  }

  void clear() {
    _accountKey = null;
    _requestInFlight = false;
    state = const NotificationState();
  }

  List<NotificationEntity> _sortedUnique(Iterable<NotificationEntity> values) {
    final byId = <String, NotificationEntity>{};
    for (final value in values) {
      byId[value.id] = value;
    }
    final result = byId.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
