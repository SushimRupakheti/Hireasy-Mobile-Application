import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_client.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:hireasy_mobile/features/auth/data/models/auth_model.dart';

final authRemoteDataSourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  AuthRemoteDatasource({required this._apiClient, required this._tokenService});

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final responseData = response.data as Map<String, dynamic>;
    if (responseData['success'] == true) {
      final data = responseData['data'] as Map<String, dynamic>;
      final user = AuthApiModel.fromJson(data);
      final token = responseData['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _tokenService.saveToken(token);
      }
      if (user.id != null && user.id!.isNotEmpty) {
        await _tokenService.saveUserId(user.id!);
      }
      await _tokenService.saveUserStatus(user.status);
      return user;
    }

    return null;
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: user.toJson(),
    );

    final responseData = response.data as Map<String, dynamic>;
    if (responseData['success'] == true) {
      final data = responseData['data'] as Map<String, dynamic>;
      return AuthApiModel.fromJson(data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: responseData['message'] as String? ?? 'Registration failed',
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } finally {
      await _tokenService.clearToken();
    }
  }

  @override
  Future<AuthApiModel?> getUserById(String authId) async {
    final response = await _apiClient.get(ApiEndpoints.userById(authId));
    final responseData = response.data as Map<String, dynamic>;
    if (responseData['success'] == true) {
      final data = responseData['data'] as Map<String, dynamic>;
      final user = AuthApiModel.fromJson(data);
      await _tokenService.saveUserStatus(user.status);
      return user;
    }

    return null;
  }

  @override
  Future<AuthApiModel?> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.currentUser);
    return _parseUserResponse(response);
  }

  @override
  Future<AuthApiModel?> uploadDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final formData = FormData.fromMap({
      'document': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _apiClient.post(
      ApiEndpoints.currentUserDocument,
      data: formData,
    );
    return _parseUserResponse(response);
  }

  @override
  Future<AuthApiModel?> uploadProfilePicture({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final formData = FormData.fromMap({
      'profileImage': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _apiClient.post(
      ApiEndpoints.currentUserProfilePicture,
      data: formData,
    );
    return _parseUserResponse(response);
  }

  @override
  Future<void> deleteDocument() async {
    await _apiClient.delete(ApiEndpoints.currentUserDocument);
  }

  @override
  Future<Uint8List> downloadDocument() async {
    final response = await _apiClient.get(
      ApiEndpoints.downloadCurrentUserDocument,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'The server returned an invalid document.',
    );
  }

  @override
  Future<AuthApiModel?> updateUser(
    String authId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.updateUser(authId),
      data: data,
    );

    final responseData = response.data as Map<String, dynamic>;
    if (responseData['success'] == true) {
      final data = responseData['data'] as Map<String, dynamic>;
      final user = AuthApiModel.fromJson(data);
      await _tokenService.saveUserStatus(user.status);
      return user;
    }

    return null;
  }

  Future<AuthApiModel?> _parseUserResponse(Response<dynamic> response) async {
    final responseData = response.data;
    if (responseData is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'The server returned an invalid user.',
      );
    }
    var data = responseData['data'] ?? responseData['user'];
    if (data is Map && data['user'] is Map) {
      data = data['user'];
    }
    if (responseData['success'] == true && data is Map) {
      final user = AuthApiModel.fromJson(Map<String, dynamic>.from(data));
      if (user.id != null && user.id!.isNotEmpty) {
        await _tokenService.saveUserId(user.id!);
      }
      await _tokenService.saveUserStatus(user.status);
      return user;
    }
    return null;
  }
}
