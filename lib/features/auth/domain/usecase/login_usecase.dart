import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginUsecaseParams {
  final String email;
  final String password;

  const LoginUsecaseParams({required this.email, required this.password});
}

final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  return LoginUsecase(authRepository: ref.read(authRepositoryProvider));
});

class LoginUsecase {
  final IAuthRepository _authRepository;

  const LoginUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<AuthEntity?> call(LoginUsecaseParams params) {
    return _authRepository.login(params.email.trim(), params.password);
  }
}
