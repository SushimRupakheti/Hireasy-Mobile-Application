import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:hireasy_mobile/features/auth/data/datasources/auth_remote_datasources.dart';
import 'package:hireasy_mobile/features/auth/data/models/auth_model.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    authRemoteDataSource: ref.read(authRemoteDataSourceProvider),
  );
});

class AuthRepository implements IAuthRepository {
  final IAuthRemoteDataSource _authRemoteDataSource;

  AuthRepository({required this._authRemoteDataSource});

  @override
  Future<AuthEntity> register(AuthEntity user) async {
    final model = AuthApiModel.fromEntity(user);
    final registeredUser = await _authRemoteDataSource.register(model);
    return registeredUser.toEntity();
  }

  @override
  Future<AuthEntity?> login(String email, String password) async {
    final user = await _authRemoteDataSource.login(email, password);
    return user?.toEntity();
  }

  @override
  Future<void> logout() {
    return _authRemoteDataSource.logout();
  }

  @override
  Future<AuthEntity?> getCurrentUser(String authId) async {
    final user = await _authRemoteDataSource.getCurrentUser();
    return user?.toEntity();
  }

  @override
  Future<AuthEntity?> updateProfileImage(
    String authId,
    String profileImage,
  ) async {
    final user = await _authRemoteDataSource.updateUser(authId, {
      'profileImage': profileImage,
    });
    return user?.toEntity();
  }

  @override
  Future<AuthEntity?> uploadDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final user = await _authRemoteDataSource.uploadDocument(
      fileName: fileName,
      bytes: bytes,
    );
    return user?.toEntity();
  }

  @override
  Future<void> deleteDocument() => _authRemoteDataSource.deleteDocument();

  @override
  Future<Uint8List> downloadDocument() {
    return _authRemoteDataSource.downloadDocument();
  }
}
