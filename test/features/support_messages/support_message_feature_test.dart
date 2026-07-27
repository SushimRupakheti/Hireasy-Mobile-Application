import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:hireasy_mobile/features/notifications/presentation/navigation/notification_navigation.dart';
import 'package:hireasy_mobile/features/support_messages/data/models/support_message_model.dart';
import 'package:hireasy_mobile/features/support_messages/data/repositories/support_message_repository.dart';
import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';
import 'package:hireasy_mobile/features/support_messages/domain/repositories/support_message_repository.dart';
import 'package:hireasy_mobile/features/support_messages/presentation/pages/support_chat_screen.dart';
import 'package:hireasy_mobile/features/support_messages/presentation/view_model/support_message_view_model.dart';

void main() {
  group('SupportMessageResponseModel', () {
    test('parses sender information, body, dates, and pagination', () {
      final response = SupportMessageResponseModel.fromJson({
        'data': [
          {
            '_id': 'message-1',
            'conversationId': 'conversation-1',
            'sender': {'_id': 'admin-1', 'role': 'admin', 'name': 'Support'},
            'senderRole': 'admin',
            'body': 'How can I help?',
            'readAt': null,
            'createdAt': '2026-07-26T12:00:00.000Z',
            'updatedAt': '2026-07-26T12:01:00.000Z',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 30,
          'total': 1,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      });

      final message = response.messages.single;
      expect(message.id, 'message-1');
      expect(message.conversationId, 'conversation-1');
      expect(message.sender['name'], 'Support');
      expect(message.isAdmin, isTrue);
      expect(message.body, 'How can I help?');
      expect(response.pagination.limit, 30);
    });
  });

  group('SupportMessageViewModel', () {
    late TokenService tokens;
    late FakeSupportMessageRepository repository;
    late ProviderContainer container;

    setUp(() async {
      tokens = TokenService();
      await tokens.saveToken('token-one');
      await tokens.saveUserId('user-one');
      repository = FakeSupportMessageRepository();
      container = ProviderContainer(
        overrides: [
          tokenServiceProvider.overrideWithValue(tokens),
          supportMessageRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('validates trimmed empty and oversized messages', () {
      expect(SupportMessageViewModel.validateMessage('  '), isNotNull);
      expect(
        SupportMessageViewModel.validateMessage(
          'x' * (SupportMessageViewModel.maxMessageLength + 1),
        ),
        isNotNull,
      );
      expect(SupportMessageViewModel.validateMessage(' Need help '), isNull);
    });

    test('adds a successful send immediately and trims its body', () async {
      repository.pages[1] = _result(const []);
      repository.sentMessage = _message(
        'sent',
        role: 'user',
        body: 'Need help',
      );
      final notifier = container.read(supportMessageViewModelProvider.notifier);
      await notifier.initialize();
      final sent = await notifier.sendMessage('  Need help  ');

      expect(sent?.id, 'sent');
      expect(repository.lastSentBody, 'Need help');
      expect(
        container.read(supportMessageViewModelProvider).messages.single.id,
        'sent',
      );
    });

    test('reports failed sends without adding a message', () async {
      repository.pages[1] = _result(const []);
      repository.failSend = true;
      final notifier = container.read(supportMessageViewModelProvider.notifier);
      await notifier.initialize();

      expect(await notifier.sendMessage('Keep this text'), isNull);
      final state = container.read(supportMessageViewModelProvider);
      expect(state.messages, isEmpty);
      expect(state.sendErrorMessage, 'Unable to send your message.');
    });

    test('loads older pages chronologically without duplicates', () async {
      repository.pages[1] = _result([
        _message('new', minute: 3),
        _message('duplicate', minute: 2),
      ], hasNextPage: true);
      repository.pages[2] = _result([
        _message('duplicate', minute: 2),
        _message('old', minute: 1),
      ], page: 2);
      final notifier = container.read(supportMessageViewModelProvider.notifier);
      await notifier.initialize();
      await notifier.loadOlder();

      expect(
        container
            .read(supportMessageViewModelProvider)
            .messages
            .map((message) => message.id),
        ['old', 'duplicate', 'new'],
      );
    });

    test('marks only unread admin replies as read', () async {
      repository.pages[1] = _result([
        _message('admin', role: 'admin'),
        _message('user', role: 'user'),
      ]);
      final notifier = container.read(supportMessageViewModelProvider.notifier);
      await notifier.initialize();
      expect(await notifier.markAdminMessagesAsRead(), isTrue);

      final messages = container.read(supportMessageViewModelProvider).messages;
      expect(messages.firstWhere((item) => item.id == 'admin').isRead, isTrue);
      expect(messages.firstWhere((item) => item.id == 'user').isRead, isFalse);
      expect(repository.markReadCalls, 1);
    });

    test(
      'clears messages before loading another account and on logout',
      () async {
        repository.pages[1] = _result([_message('old')]);
        final notifier = container.read(
          supportMessageViewModelProvider.notifier,
        );
        await notifier.initialize();

        await tokens.saveToken('token-two');
        await tokens.saveUserId('user-two');
        repository.pages[1] = _result([_message('new')]);
        await notifier.initialize();
        expect(
          container
              .read(supportMessageViewModelProvider)
              .messages
              .map((message) => message.id),
          ['new'],
        );

        notifier.clear();
        final state = container.read(supportMessageViewModelProvider);
        expect(state.messages, isEmpty);
        expect(state.isAuthenticated, isFalse);
      },
    );
  });

  test('bubble alignment distinguishes user and admin senders', () {
    expect(
      supportMessageAlignment(_message('admin', role: 'admin')),
      Alignment.centerLeft,
    );
    expect(
      supportMessageAlignment(_message('user', role: 'user')),
      Alignment.centerRight,
    );
  });

  test('polling runs only while the app is resumed', () {
    expect(shouldPollSupportMessages(AppLifecycleState.resumed), isTrue);
    expect(shouldPollSupportMessages(AppLifecycleState.paused), isFalse);
    expect(shouldPollSupportMessages(AppLifecycleState.inactive), isFalse);
    expect(shouldPollSupportMessages(AppLifecycleState.detached), isFalse);
  });

  test('support reply notification maps to support chat', () {
    final target = notificationNavigationTarget(
      NotificationEntity(
        id: 'notification',
        recipient: 'user',
        type: 'support_reply_received',
        title: 'New support reply',
        message: 'Admin replied.',
        data: const {},
        actionUrl: null,
        readAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    expect(target.destination, NotificationDestination.support);
  });
}

SupportMessageEntity _message(
  String id, {
  String role = 'admin',
  String body = 'Message',
  int minute = 0,
}) {
  return SupportMessageEntity(
    id: id,
    conversationId: 'conversation',
    sender: {'_id': '$role-id', 'role': role},
    senderRole: role,
    body: body,
    readAt: null,
    createdAt: DateTime.utc(2026, 7, 26, 12, minute),
    updatedAt: DateTime.utc(2026, 7, 26, 12, minute),
  );
}

SupportMessageResult _result(
  List<SupportMessageEntity> messages, {
  int page = 1,
  bool hasNextPage = false,
}) {
  return SupportMessageResult(
    messages: messages,
    pagination: SupportMessagePagination(
      page: page,
      limit: 30,
      total: messages.length,
      totalPages: hasNextPage ? 2 : page,
      hasNextPage: hasNextPage,
      hasPreviousPage: page > 1,
    ),
  );
}

class FakeSupportMessageRepository implements ISupportMessageRepository {
  final Map<int, SupportMessageResult> pages = {};
  SupportMessageEntity? sentMessage;
  bool failSend = false;
  int markReadCalls = 0;
  String? lastSentBody;

  @override
  Future<SupportMessageResult> getMessages({
    required int page,
    required int limit,
  }) async {
    return pages[page] ?? _result(const [], page: page);
  }

  @override
  Future<void> markMessagesAsRead() async {
    markReadCalls++;
  }

  @override
  Future<SupportMessageEntity> sendMessage(String message) async {
    lastSentBody = message;
    if (failSend) throw Exception('failed');
    return sentMessage ?? _message('sent', role: 'user', body: message);
  }
}
