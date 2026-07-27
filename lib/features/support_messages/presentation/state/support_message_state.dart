import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';

class SupportMessageState {
  final List<SupportMessageEntity> messages;
  final int currentPage;
  final bool hasMore;
  final bool isAuthenticated;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingOlder;
  final bool isSending;
  final bool isMarkingRead;
  final String? errorMessage;
  final String? sendErrorMessage;

  const SupportMessageState({
    this.messages = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingOlder = false,
    this.isSending = false,
    this.isMarkingRead = false,
    this.errorMessage,
    this.sendErrorMessage,
  });

  bool get hasUnreadAdminMessages {
    return messages.any((message) => message.isAdmin && !message.isRead);
  }

  SupportMessageState copyWith({
    List<SupportMessageEntity>? messages,
    int? currentPage,
    bool? hasMore,
    bool? isAuthenticated,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingOlder,
    bool? isSending,
    bool? isMarkingRead,
    String? errorMessage,
    String? sendErrorMessage,
    bool clearError = false,
    bool clearSendError = false,
  }) {
    return SupportMessageState(
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
      isMarkingRead: isMarkingRead ?? this.isMarkingRead,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      sendErrorMessage: clearSendError
          ? null
          : sendErrorMessage ?? this.sendErrorMessage,
    );
  }
}
