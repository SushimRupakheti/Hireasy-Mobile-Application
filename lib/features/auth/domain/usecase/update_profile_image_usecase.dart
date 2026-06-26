import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileImageUsecaseParams {
  final String profileImage;

  const UpdateProfileImageUsecaseParams({required this.profileImage});
}

final updateProfileImageUsecaseProvider = Provider<UpdateProfileImageUsecase>((
  ref,
) {
  return UpdateProfileImageUsecase(
    authRepository: ref.read(authRepositoryProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class UpdateProfileImageUsecase {
  final IAuthRepository _authRepository;
  final TokenService _tokenService;

  const UpdateProfileImageUsecase({
    required IAuthRepository authRepository,
    required TokenService tokenService,
  }) : _authRepository = authRepository,
       _tokenService = tokenService;

  Future<AuthEntity?> call(UpdateProfileImageUsecaseParams params) {
    final authId = _tokenService.userId;
    if (authId == null || authId.isEmpty) {
      return Future.value();
    }

    return _authRepository.updateProfileImage(
      authId,
      params.profileImage.trim(),
    );
  }
}
