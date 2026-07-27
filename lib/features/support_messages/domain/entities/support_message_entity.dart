class SupportMessageEntity {
  final String id;
  final String conversationId;
  final Map<String, dynamic> sender;
  final String senderRole;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportMessageEntity({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.senderRole,
    required this.body,
    required this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin {
    final role = senderRole.trim().toLowerCase();
    return role == 'admin' || role == 'support' || role == 'superadmin';
  }

  bool get isRead => readAt != null;

  SupportMessageEntity copyWith({DateTime? readAt}) {
    return SupportMessageEntity(
      id: id,
      conversationId: conversationId,
      sender: sender,
      senderRole: senderRole,
      body: body,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class SupportMessagePagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const SupportMessagePagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}

class SupportMessageResult {
  final List<SupportMessageEntity> messages;
  final SupportMessagePagination pagination;

  const SupportMessageResult({
    required this.messages,
    required this.pagination,
  });
}
