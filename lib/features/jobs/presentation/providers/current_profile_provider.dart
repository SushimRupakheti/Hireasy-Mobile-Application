import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/get_current_user.dart';

final currentProfileProvider = FutureProvider.autoDispose<AuthEntity?>((ref) {
  return ref.read(getCurrentUserUsecaseProvider).call();
});
