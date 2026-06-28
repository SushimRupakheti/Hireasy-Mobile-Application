import 'dart:typed_data';

import 'package:hireasy_mobile/features/auth/data/models/auth_model.dart';

abstract interface class IAuthRemoteDataSource {
  Future<AuthApiModel?> login(String email, String password);
  Future<AuthApiModel> register(AuthApiModel user);
  Future<void> logout();
  Future<AuthApiModel?> getUserById(String authId);
  Future<AuthApiModel?> updateUser(String authId, Map<String, dynamic> data);
  Future<AuthApiModel?> getCurrentUser();
  Future<AuthApiModel?> uploadDocument({
    required String fileName,
    required Uint8List bytes,
  });
  Future<AuthApiModel?> uploadProfilePicture({
    required String fileName,
    required Uint8List bytes,
  });
  Future<void> deleteDocument();
  Future<Uint8List> downloadDocument();
}
