import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

class RegisterUsecaseParams {
  final String role;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String email;
  final String contactNo;
  final String address;
  final String password;
  final List<String> interestedFields;

  const RegisterUsecaseParams({
    required this.role,
    this.firstName,
    this.lastName,
    this.companyName,
    required this.email,
    required this.contactNo,
    required this.address,
    required this.password,
    this.interestedFields = const [],
  });
}

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(authRepository: ref.read(authRepositoryProvider));
});

class RegisterUsecase {
  final IAuthRepository _authRepository;

  const RegisterUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  Future<AuthEntity> call(RegisterUsecaseParams params) {
    final user = AuthEntity(
      role: params.role,
      firstName: params.firstName?.trim(),
      lastName: params.lastName?.trim(),
      companyName: params.companyName?.trim(),
      email: params.email.trim(),
      contactNo: params.contactNo.trim(),
      address: params.address.trim(),
      password: params.password,
      interestedFields: params.interestedFields,
    );

    return _authRepository.register(user);
  }
}
