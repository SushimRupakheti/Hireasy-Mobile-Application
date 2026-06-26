import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  return GetCurrentUserUsecase(
    authRepository: ref.read(authRepositoryProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class GetCurrentUserUsecase {
  final IAuthRepository _authRepository;
  final TokenService _tokenService;

  const GetCurrentUserUsecase({
    required IAuthRepository authRepository,
    required TokenService tokenService,
  }) : _authRepository = authRepository,
       _tokenService = tokenService;

  Future<AuthEntity?> call() {
    if (!_tokenService.hasSession) {
      return Future.value();
    }

    return _authRepository.getCurrentUser(_tokenService.userId ?? '');
  }
}
