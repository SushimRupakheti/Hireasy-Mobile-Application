import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:hireasy_mobile/features/notifications/presentation/navigation/notification_navigation.dart';
import 'package:hireasy_mobile/features/notifications/presentation/state/notification_state.dart';
import 'package:hireasy_mobile/features/notifications/presentation/view_model/notification_view_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onOpenJob;
  final ValueChanged<String> onOpenApplicants;
  final VoidCallback onOpenSupport;

  const NotificationScreen({
    super.key,
    required this.onOpenProfile,
    required this.onOpenJob,
    required this.onOpenApplicants,
    required this.onOpenSupport,
  });

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 250) {
      ref.read(notificationViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationViewModelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: state.unreadCount == 0 ? null : _markAllAsRead,
            child: const Text('Mark all as read'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _body(state),
    );
  }

  Widget _body(NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return _NotificationFeedback(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load notifications',
        message: state.errorMessage!,
        actionLabel: 'Try again',
        onAction: () => ref
            .read(notificationViewModelProvider.notifier)
            .refresh(showLoading: true),
      );
    }
    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationViewModelProvider.notifier).refresh(),
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NotificationFeedback(
                icon: Icons.notifications_none_rounded,
                title: 'No notifications yet',
                message:
                    'Updates about your account and jobs will appear here.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationViewModelProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = state.notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _open(notification),
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final succeeded = await ref
        .read(notificationViewModelProvider.notifier)
        .markAllAsRead();
    if (!succeeded && mounted) {
      _showError('Unable to mark notifications as read.');
    }
  }

  Future<void> _open(NotificationEntity notification) async {
    final succeeded = await ref
        .read(notificationViewModelProvider.notifier)
        .markAsRead(notification.id);
    if (!succeeded && mounted) {
      _showError('Unable to mark this notification as read.');
    }
    if (!mounted) return;
    final target = notificationNavigationTarget(notification);
    switch (target.destination) {
      case NotificationDestination.profile:
      case NotificationDestination.verification:
        widget.onOpenProfile();
        break;
      case NotificationDestination.job:
        if (target.jobId != null) widget.onOpenJob(target.jobId!);
        break;
      case NotificationDestination.applicants:
        if (target.jobId != null) widget.onOpenApplicants(target.jobId!);
        break;
      case NotificationDestination.support:
        widget.onOpenSupport();
        break;
      case NotificationDestination.none:
        break;
    }
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

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(
      color: unread ? const Color(0xFFEAF1FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _iconColor.withValues(alpha: 0.12),
                foregroundColor: _iconColor,
                child: Icon(_icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isEmpty
                                ? 'Notification'
                                : notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFF3F7CF4),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Color(0xFF626873),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF8B9099),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    final type = notification.type.toLowerCase();
    if (type.startsWith('application')) {
      return Icons.assignment_turned_in_outlined;
    }
    if (type.startsWith('job')) return Icons.work_outline_rounded;
    if (type.startsWith('document')) return Icons.description_outlined;
    if (type.startsWith('account')) return Icons.verified_user_outlined;
    return Icons.notifications_outlined;
  }

  Color get _iconColor {
    final status = notification.data['status']?.toString().toLowerCase();
    if (status == 'accepted' || status == 'verified' || status == 'approved') {
      return const Color(0xFF237A45);
    }
    if (status == 'rejected') return const Color(0xFFB42318);
    return const Color(0xFF435D95);
  }
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}

class _NotificationFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NotificationFeedback({
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
            Icon(icon, size: 50, color: const Color(0xFF71809C)),
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
              style: const TextStyle(color: Color(0xFF777C86)),
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
