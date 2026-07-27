import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_client.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/features/support_messages/data/models/support_message_model.dart';
import 'package:hireasy_mobile/features/support_messages/domain/entities/support_message_entity.dart';
import 'package:hireasy_mobile/features/support_messages/domain/repositories/support_message_repository.dart';

final supportMessageRepositoryProvider = Provider<ISupportMessageRepository>((
  ref,
) {
  return SupportMessageRepository(ref.read(apiClientProvider));
});

class SupportMessageRepository implements ISupportMessageRepository {
  final ApiClient _apiClient;

  const SupportMessageRepository(this._apiClient);

  @override
  Future<SupportMessageResult> getMessages({
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.messages,
      queryParameters: {'page': page, 'limit': limit},
    );
    return SupportMessageResponseModel.fromJson(response.data).toEntity();
  }

  @override
  Future<SupportMessageEntity> sendMessage(String message) async {
    final response = await _apiClient.post(
      ApiEndpoints.messages,
      data: {'message': message},
    );
    return parseSentSupportMessage(response.data);
  }

  @override
  Future<void> markMessagesAsRead() async {
    await _apiClient.patch(ApiEndpoints.messagesRead);
  }
}
