import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/repositories/auth_repository.dart';

const maxDocumentSize = 5 * 1024 * 1024;
const allowedDocumentExtensions = {'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'};

final documentUsecaseProvider = Provider<DocumentUsecase>((ref) {
  return DocumentUsecase(ref.read(authRepositoryProvider));
});

class DocumentUsecase {
  final IAuthRepository _authRepository;

  const DocumentUsecase(this._authRepository);

  Future<AuthEntity?> upload({
    required String fileName,
    required Uint8List bytes,
  }) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    if (!allowedDocumentExtensions.contains(extension)) {
      throw const FormatException(
        'Only PDF, DOC, DOCX, JPG, and PNG files are allowed.',
      );
    }
    if (bytes.isEmpty) {
      throw const FormatException('The selected document is empty.');
    }
    if (bytes.length > maxDocumentSize) {
      throw const FormatException('The document must be 5 MB or smaller.');
    }
    return _authRepository.uploadDocument(fileName: fileName, bytes: bytes);
  }

  Future<void> delete() => _authRepository.deleteDocument();

  Future<Uint8List> download() => _authRepository.downloadDocument();
}
