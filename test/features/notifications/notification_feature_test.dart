import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/notifications/data/models/notification_model.dart';
import 'package:hireasy_mobile/features/notifications/data/repositories/notification_repository.dart';
import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:hireasy_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:hireasy_mobile/features/notifications/presentation/navigation/notification_navigation.dart';
import 'package:hireasy_mobile/features/notifications/presentation/view_model/notification_view_model.dart';

void main() {
  group('NotificationResponseModel', () {
    test(
      'parses notifications, dynamic data, unread count, and pagination',
      () {
        final response = NotificationResponseModel.fromJson({
          'success': true,
          'data': [
            {
              '_id': 'notification-1',
              'recipient': 'user-1',
              'type': 'application_status_changed',
              'title': 'Application accepted',
              'message': 'Your application was accepted.',
              'data': {'jobId': 'job-1', 'status': 'accepted'},
              'actionUrl': '/jobs/job-1',
              'readAt': null,
              'createdAt': '2026-07-26T12:00:00.000Z',
              'updatedAt': '2026-07-26T12:00:00.000Z',
            },
          ],
          'unreadCount': 1,
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
            'hasNextPage': false,
            'hasPreviousPage': false,
          },
        });

        expect(response.notifications.single.id, 'notification-1');
        expect(response.notifications.single.data['jobId'], 'job-1');
        expect(response.notifications.single.readAt, isNull);
        expect(response.unreadCount, 1);
        expect(response.pagination.page, 1);
      },
    );
  });

  group('NotificationViewModel', () {
    late TokenService tokens;
    late FakeNotificationRepository repository;
    late ProviderContainer container;

    setUp(() async {
      tokens = TokenService();
      await tokens.saveToken('token-one');
      await tokens.saveUserId('user-one');
      repository = FakeNotificationRepository();
      container = ProviderContainer(
        overrides: [
          tokenServiceProvider.overrideWithValue(tokens),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('updates unread count for mark-one and mark-all', () async {
      repository.pages[1] = _result([
        _notification('one'),
        _notification('two'),
      ], unreadCount: 2);
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.initialize();

      expect(container.read(notificationViewModelProvider).unreadCount, 2);
      expect(await notifier.markAsRead('one'), isTrue);
      expect(container.read(notificationViewModelProvider).unreadCount, 1);
      expect(await notifier.markAllAsRead(), isTrue);
      final state = container.read(notificationViewModelProvider);
      expect(state.unreadCount, 0);
      expect(state.notifications.every((item) => item.isRead), isTrue);
    });

    test('restores unread state when mark-as-read fails', () async {
      repository.pages[1] = _result([_notification('one')], unreadCount: 1);
      repository.failMarkOne = true;
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.initialize();

      expect(await notifier.markAsRead('one'), isFalse);
      final state = container.read(notificationViewModelProvider);
      expect(state.unreadCount, 1);
      expect(state.notifications.single.isRead, isFalse);
    });

    test('merges pagination without duplicate notification ids', () async {
      repository.pages[1] = _result(
        [_notification('one'), _notification('two')],
        unreadCount: 3,
        hasNextPage: true,
      );
      repository.pages[2] = _result(
        [_notification('two'), _notification('three')],
        unreadCount: 3,
        page: 2,
      );
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.initialize();
      await notifier.loadMore();

      expect(
        container
            .read(notificationViewModelProvider)
            .notifications
            .map((item) => item.id)
            .toSet(),
        {'one', 'two', 'three'},
      );
    });

    test(
      'clears previous account state before loading a new account',
      () async {
        repository.pages[1] = _result([_notification('old')], unreadCount: 1);
        final notifier = container.read(notificationViewModelProvider.notifier);
        await notifier.initialize();
        expect(
          container.read(notificationViewModelProvider).notifications,
          isNotEmpty,
        );

        await tokens.saveToken('token-two');
        await tokens.saveUserId('user-two');
        repository.pages[1] = _result([_notification('new')], unreadCount: 0);
        await notifier.initialize();

        final state = container.read(notificationViewModelProvider);
        expect(state.notifications.map((item) => item.id), ['new']);
        notifier.clear();
        expect(
          container.read(notificationViewModelProvider).notifications,
          isEmpty,
        );
        expect(
          container.read(notificationViewModelProvider).isAuthenticated,
          isFalse,
        );
      },
    );

    test('exposes empty and error states safely', () async {
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.initialize();
      expect(
        container.read(notificationViewModelProvider).notifications,
        isEmpty,
      );
      expect(
        container.read(notificationViewModelProvider).errorMessage,
        isNull,
      );

      repository.failFetch = true;
      await notifier.refresh(showLoading: true);
      final state = container.read(notificationViewModelProvider);
      expect(state.notifications, isEmpty);
      expect(state.errorMessage, 'Unable to load notifications.');
      expect(state.isLoading, isFalse);
    });
  });

  group('notificationNavigationTarget', () {
    test('maps profile and job destinations safely', () {
      expect(
        notificationNavigationTarget(
          _notification('profile', type: 'account_verified'),
        ).destination,
        NotificationDestination.profile,
      );
      final job = notificationNavigationTarget(
        _notification(
          'job',
          type: 'application_status_changed',
          data: {'jobId': 'job-42'},
        ),
      );
      expect(job.destination, NotificationDestination.job);
      expect(job.jobId, 'job-42');
      expect(
        notificationNavigationTarget(
          _notification('missing', type: 'job_status_changed'),
        ).destination,
        NotificationDestination.none,
      );
    });
  });
}

NotificationEntity _notification(
  String id, {
  String type = 'application_status_changed',
  Map<String, dynamic> data = const {},
}) {
  return NotificationEntity(
    id: id,
    recipient: 'user',
    type: type,
    title: 'Title',
    message: 'Message',
    data: data,
    actionUrl: null,
    readAt: null,
    createdAt: DateTime.utc(2026, 7, 26, 12),
    updatedAt: DateTime.utc(2026, 7, 26, 12),
  );
}

NotificationResult _result(
  List<NotificationEntity> notifications, {
  required int unreadCount,
  int page = 1,
  bool hasNextPage = false,
}) {
  return NotificationResult(
    notifications: notifications,
    unreadCount: unreadCount,
    pagination: NotificationPagination(
      page: page,
      limit: 20,
      total: notifications.length,
      totalPages: hasNextPage ? 2 : page,
      hasNextPage: hasNextPage,
      hasPreviousPage: page > 1,
    ),
  );
}

class FakeNotificationRepository implements INotificationRepository {
  final Map<int, NotificationResult> pages = {};
  bool failMarkOne = false;
  bool failMarkAll = false;
  bool failFetch = false;

  @override
  Future<NotificationResult> getNotifications({
    required int page,
    required int limit,
    required bool unreadOnly,
  }) async {
    if (failFetch) throw Exception('failed');
    return pages[page] ?? _result(const [], unreadCount: 0, page: page);
  }

  @override
  Future<void> markAllAsRead() async {
    if (failMarkAll) throw Exception('failed');
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    if (failMarkOne) throw Exception('failed');
  }
}
