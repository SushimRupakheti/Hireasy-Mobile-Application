import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/support_messages/data/repositories/support_message_repository.dart';
import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';
import 'package:hireasy_mobile/features/support_messages/presentation/state/support_message_state.dart';

final supportMessageViewModelProvider =
    NotifierProvider<SupportMessageViewModel, SupportMessageState>(
      SupportMessageViewModel.new,
    );

class SupportMessageViewModel extends Notifier<SupportMessageState> {
  static const pageSize = 30;
  static const maxMessageLength = 5000;

  String? _accountKey;
  bool _fetchInFlight = false;

  @override
  SupportMessageState build() => const SupportMessageState();

  String? get _currentAccountKey {
    final tokens = ref.read(tokenServiceProvider);
    final token = tokens.token;
    if (token == null || token.isEmpty) return null;
    return '${tokens.userId ?? ''}:${token.hashCode}';
  }

  static String? validateMessage(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'Enter a message.';
    if (clean.length > maxMessageLength) {
      return 'Messages can be up to $maxMessageLength characters.';
    }
    return null;
  }

  Future<void> initialize() async {
    final key = _currentAccountKey;
    if (key == null) {
      clear();
      return;
    }
    if (_accountKey != key) {
      _accountKey = key;
      state = const SupportMessageState(isAuthenticated: true);
    }
    await refresh(showLoading: state.messages.isEmpty);
  }

  Future<void> refresh({bool showLoading = false}) async {
    final key = _currentAccountKey;
    if (key == null) {
      clear();
      return;
    }
    if (_accountKey != key) {
      _accountKey = key;
      state = const SupportMessageState(isAuthenticated: true);
      showLoading = true;
    }
    if (_fetchInFlight) return;
    _fetchInFlight = true;
    state = state.copyWith(
      isLoading: showLoading,
      isRefreshing: !showLoading,
      isAuthenticated: true,
      clearError: true,
    );
    try {
      final result = await ref
          .read(supportMessageRepositoryProvider)
          .getMessages(page: 1, limit: pageSize);
      if (_currentAccountKey != key || _accountKey != key) return;
      final hadOlderPages = state.currentPage > 1;
      state = state.copyWith(
        messages: _chronologicalUnique([...state.messages, ...result.messages]),
        currentPage: hadOlderPages ? state.currentPage : 1,
        hasMore: hadOlderPages ? state.hasMore : result.pagination.hasNextPage,
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
          fallback: 'Unable to load your support conversation.',
        ),
      );
    } catch (error) {
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: error is FormatException
            ? error.message
            : 'Unable to load your support conversation.',
      );
    } finally {
      _fetchInFlight = false;
    }
  }

  Future<void> loadOlder() async {
    final key = _currentAccountKey;
    if (key == null || key != _accountKey || _fetchInFlight || !state.hasMore) {
      return;
    }
    _fetchInFlight = true;
    state = state.copyWith(isLoadingOlder: true, clearError: true);
    final nextPage = state.currentPage + 1;
    try {
      final result = await ref
          .read(supportMessageRepositoryProvider)
          .getMessages(page: nextPage, limit: pageSize);
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        messages: _chronologicalUnique([...state.messages, ...result.messages]),
        currentPage: nextPage,
        hasMore: result.pagination.hasNextPage,
        isLoadingOlder: false,
      );
    } catch (_) {
      if (_currentAccountKey != key || _accountKey != key) return;
      state = state.copyWith(
        isLoadingOlder: false,
        errorMessage: 'Unable to load older messages.',
      );
    } finally {
      _fetchInFlight = false;
    }
  }

  Future<SupportMessageEntity?> sendMessage(String value) async {
    final key = _currentAccountKey;
    final validation = validateMessage(value);
    if (key == null || key != _accountKey || validation != null) {
      state = state.copyWith(sendErrorMessage: validation);
      return null;
    }
    if (state.isSending) return null;
    final clean = value.trim();
    state = state.copyWith(isSending: true, clearSendError: true);
    try {
      final sent = await ref
          .read(supportMessageRepositoryProvider)
          .sendMessage(clean);
      if (_currentAccountKey != key || _accountKey != key) return null;
      state = state.copyWith(
        messages: _chronologicalUnique([...state.messages, sent]),
        isSending: false,
        clearSendError: true,
      );
      return sent;
    } on DioException catch (error) {
      if (_currentAccountKey != key || _accountKey != key) return null;
      state = state.copyWith(
        isSending: false,
        sendErrorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to send your message.',
        ),
      );
      return null;
    } catch (_) {
      if (_currentAccountKey != key || _accountKey != key) return null;
      state = state.copyWith(
        isSending: false,
        sendErrorMessage: 'Unable to send your message.',
      );
      return null;
    }
  }

  Future<bool> markAdminMessagesAsRead() async {
    final key = _currentAccountKey;
    if (key == null ||
        key != _accountKey ||
        state.isMarkingRead ||
        !state.hasUnreadAdminMessages) {
      return key != null;
    }
    state = state.copyWith(isMarkingRead: true);
    try {
      await ref.read(supportMessageRepositoryProvider).markMessagesAsRead();
      if (_currentAccountKey != key || _accountKey != key) return false;
      final now = DateTime.now();
      state = state.copyWith(
        messages: [
          for (final message in state.messages)
            message.isAdmin && !message.isRead
                ? message.copyWith(readAt: now)
                : message,
        ],
        isMarkingRead: false,
      );
      return true;
    } catch (_) {
      if (_currentAccountKey == key && _accountKey == key) {
        state = state.copyWith(isMarkingRead: false);
      }
      return false;
    }
  }

  void clear() {
    _accountKey = null;
    _fetchInFlight = false;
    state = const SupportMessageState();
  }

  List<SupportMessageEntity> _chronologicalUnique(
    Iterable<SupportMessageEntity> messages,
  ) {
    final byId = <String, SupportMessageEntity>{};
    for (final message in messages) {
      byId[message.id] = message;
    }
    final result = byId.values.toList();
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }
}
