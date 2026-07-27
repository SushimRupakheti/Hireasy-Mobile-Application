import 'package:hireasy_mobile/features/notifications/domain/entities/notification_entity.dart';

enum NotificationDestination {
  profile,
  verification,
  job,
  applicants,
  support,
  none,
}

class NotificationNavigationTarget {
  final NotificationDestination destination;
  final String? jobId;

  const NotificationNavigationTarget(this.destination, {this.jobId});
}

NotificationNavigationTarget notificationNavigationTarget(
  NotificationEntity notification,
) {
  final type = notification.type.trim().toLowerCase();
  final jobId = _jobId(notification);
  switch (type) {
    case 'account_verified':
    case 'account_status_changed':
      return const NotificationNavigationTarget(
        NotificationDestination.profile,
      );
    case 'account_rejected':
    case 'document_approved':
    case 'document_rejected':
      return const NotificationNavigationTarget(
        NotificationDestination.verification,
      );
    case 'job_status_changed':
    case 'application_status_changed':
      return jobId == null
          ? const NotificationNavigationTarget(NotificationDestination.none)
          : NotificationNavigationTarget(
              NotificationDestination.job,
              jobId: jobId,
            );
    case 'application_received':
      return jobId == null
          ? const NotificationNavigationTarget(NotificationDestination.none)
          : NotificationNavigationTarget(
              NotificationDestination.applicants,
              jobId: jobId,
            );
    case 'support_reply_received':
      return const NotificationNavigationTarget(
        NotificationDestination.support,
      );
    default:
      return const NotificationNavigationTarget(NotificationDestination.none);
  }
}

String? _jobId(NotificationEntity notification) {
  final fromData = notification.data['jobId'];
  final dataValue = fromData is Map
      ? fromData['_id'] ?? fromData['id']
      : fromData;
  final cleanData = dataValue?.toString().trim() ?? '';
  if (cleanData.isNotEmpty) return cleanData;
  final actionUrl = notification.actionUrl?.trim() ?? '';
  final match = RegExp(r'/jobs/([^/?#]+)').firstMatch(actionUrl);
  return match?.group(1);
}
