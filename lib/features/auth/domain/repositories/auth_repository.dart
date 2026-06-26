import 'dart:typed_data';

import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<AuthEntity> register(AuthEntity user);
  Future<AuthEntity?> login(String email, String password);
  Future<void> logout();
  Future<AuthEntity?> getCurrentUser(String authId);
  Future<AuthEntity?> updateProfileImage(String authId, String profileImage);
  Future<AuthEntity?> uploadDocument({
    required String fileName,
    required Uint8List bytes,
  });
  Future<void> deleteDocument();
  Future<Uint8List> downloadDocument();
}
