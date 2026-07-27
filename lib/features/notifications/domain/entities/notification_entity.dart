class NotificationEntity {
  final String id;
  final String recipient;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEntity({
    required this.id,
    required this.recipient,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.actionUrl,
    required this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRead => readAt != null;

  NotificationEntity copyWith({DateTime? readAt, bool clearReadAt = false}) {
    return NotificationEntity(
      id: id,
      recipient: recipient,
      type: type,
      title: title,
      message: message,
      data: data,
      actionUrl: actionUrl,
      readAt: clearReadAt ? null : readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}

class NotificationResult {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final NotificationPagination pagination;

  const NotificationResult({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });
}
