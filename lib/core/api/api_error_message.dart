import 'package:dio/dio.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';

String apiErrorMessage(DioException error, {required String fallback}) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final fieldErrors = data['errors']?['fieldErrors'];
    if (fieldErrors is Map && fieldErrors.isNotEmpty) {
      final firstError = fieldErrors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }
    return data['message']?.toString() ?? fallback;
  }

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Cannot connect to the server at ${ApiEndpoints.baseUrl}. '
          'Make sure the backend is running and this phone is on the same Wi-Fi.';
    default:
      return error.message ?? fallback;
  }
}
