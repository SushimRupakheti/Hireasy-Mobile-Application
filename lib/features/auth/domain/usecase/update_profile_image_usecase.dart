import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileImageUsecaseParams {
  final String fileName;
  final Uint8List bytes;

  const UpdateProfileImageUsecaseParams({
    required this.fileName,
    required this.bytes,
  });
}

final updateProfileImageUsecaseProvider = Provider<UpdateProfileImageUsecase>((
  ref,
) {
  return UpdateProfileImageUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});

class UpdateProfileImageUsecase {
  final IAuthRepository _authRepository;

  const UpdateProfileImageUsecase({
    required IAuthRepository authRepository,
  }) : _authRepository = authRepository;

  Future<AuthEntity?> call(UpdateProfileImageUsecaseParams params) {
    if (params.bytes.isEmpty) {
      throw const FormatException('The selected image is empty.');
    }
    if (params.bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('The image must be 5 MB or smaller.');
    }
    if (!_isAllowedImage(params.fileName)) {
      throw const FormatException('Only JPG, PNG or WEBP images are allowed.');
    }

    return _authRepository.uploadProfilePicture(
      fileName: params.fileName,
      bytes: params.bytes,
    );
  }

  bool _isAllowedImage(String fileName) {
    final extension = fileName.split('.').last.trim().toLowerCase();
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp';
  }
}
