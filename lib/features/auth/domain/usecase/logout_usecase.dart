import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(authRepository: ref.read(authRepositoryProvider));
});

class LogoutUsecase {
  final IAuthRepository _authRepository;

  const LogoutUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<void> call() {
    return _authRepository.logout();
  }
}
