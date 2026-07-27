import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/notifications/presentation/view_model/notification_view_model.dart';
import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';
import 'package:hireasy_mobile/features/support_messages/presentation/state/support_message_state.dart';
import 'package:hireasy_mobile/features/support_messages/presentation/view_model/support_message_view_model.dart';

Alignment supportMessageAlignment(SupportMessageEntity message) {
  return message.isAdmin ? Alignment.centerLeft : Alignment.centerRight;
}

bool shouldPollSupportMessages(AppLifecycleState state) {
  return state == AppLifecycleState.resumed;
}

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _loadingOlder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    Future.microtask(_start);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shouldPollSupportMessages(state)) {
      _startPolling(refreshNow: true);
    } else {
      _stopPolling();
    }
  }

  Future<void> _start() async {
    await ref.read(supportMessageViewModelProvider.notifier).initialize();
    if (!mounted) return;
    await _markRepliesRead();
    _scrollToBottom(jump: true);
    _startPolling();
  }

  void _startPolling({bool refreshNow = false}) {
    if (!mounted) return;
    if (refreshNow) _poll();
    _pollTimer ??= Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final wasNearBottom = _isNearBottom;
    await ref.read(supportMessageViewModelProvider.notifier).refresh();
    if (!mounted) return;
    await _markRepliesRead();
    if (wasNearBottom) _scrollToBottom();
  }

  Future<void> _markRepliesRead() async {
    final marked = await ref
        .read(supportMessageViewModelProvider.notifier)
        .markAdminMessagesAsRead();
    if (!mounted || !marked) return;
    final notifications = ref
        .read(notificationViewModelProvider)
        .notifications
        .where(
          (notification) =>
              notification.type.trim().toLowerCase() ==
                  'support_reply_received' &&
              !notification.isRead,
        )
        .toList();
    for (final notification in notifications) {
      await ref
          .read(notificationViewModelProvider.notifier)
          .markAsRead(notification.id);
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.extentAfter < 120;
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels < 120) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    final state = ref.read(supportMessageViewModelProvider);
    if (_loadingOlder || state.isLoadingOlder || !state.hasMore) return;
    _loadingOlder = true;
    final oldExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final oldOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    await ref.read(supportMessageViewModelProvider.notifier).loadOlder();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final addedExtent =
            _scrollController.position.maxScrollExtent - oldExtent;
        _scrollController.jumpTo(oldOffset + addedExtent);
      });
    }
    _loadingOlder = false;
  }

  Future<void> _refresh() async {
    await ref.read(supportMessageViewModelProvider.notifier).refresh();
    if (mounted) await _markRepliesRead();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (SupportMessageViewModel.validateMessage(text) != null) return;
    final sent = await ref
        .read(supportMessageViewModelProvider.notifier)
        .sendMessage(text);
    if (!mounted) return;
    if (sent != null) {
      _messageController.clear();
      setState(() {});
      _scrollToBottom();
    } else {
      final error = ref.read(supportMessageViewModelProvider).sendErrorMessage;
      if (error != null) _showError(error);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportMessageViewModelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Private conversation with Hireasy admin',
              style: TextStyle(
                color: Color(0xFF777C86),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _conversation(state)),
            _Composer(
              controller: _messageController,
              isSending: state.isSending,
              onChanged: (_) => setState(() {}),
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversation(SupportMessageState state) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.messages.isEmpty) {
      return _ChatFeedback(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load your conversation',
        message: state.errorMessage!,
        actionLabel: 'Try again',
        onAction: () => ref
            .read(supportMessageViewModelProvider.notifier)
            .refresh(showLoading: true),
      );
    }
    if (state.messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _ChatFeedback(
                icon: Icons.support_agent_rounded,
                title: 'How can we help?',
                message:
                    'Send a message and the Hireasy support team will reply here.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        itemCount: state.messages.length + (state.isLoadingOlder ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingOlder && index == 0) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final messageIndex = index - (state.isLoadingOlder ? 1 : 0);
          return _MessageBubble(message: state.messages[messageIndex]);
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageEntity message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final admin = message.isAdmin;
    return Align(
      alignment: supportMessageAlignment(message),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
        decoration: BoxDecoration(
          color: admin ? Colors.white : const Color(0xFF18346F),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(admin ? 4 : 16),
            bottomRight: Radius.circular(admin ? 16 : 4),
          ),
          border: admin ? Border.all(color: const Color(0xFFDDE2EC)) : null,
        ),
        child: Column(
          crossAxisAlignment: admin
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (admin) ...[
              const Text(
                'Hireasy Support',
                style: TextStyle(
                  color: Color(0xFF435D95),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message.body,
              style: TextStyle(
                color: admin ? const Color(0xFF252830) : Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _messageTime(message.createdAt),
                  style: TextStyle(
                    color: admin ? const Color(0xFF8A909A) : Colors.white70,
                    fontSize: 10,
                  ),
                ),
                if (!admin) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF8ED6FF)
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final valid =
        SupportMessageViewModel.validateMessage(controller.text) == null;
    return Material(
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 5,
                maxLength: SupportMessageViewModel.maxMessageLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message Hireasy support',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF2F4F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: valid && !isSending ? onSend : null,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ChatFeedback({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF71809C)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF777C86), height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _messageTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
