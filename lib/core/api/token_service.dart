import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenServiceProvider = Provider<TokenService>((ref) => TokenService());

class TokenService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userStatusKey = 'auth_user_status';

  final FlutterSecureStorage _storage;

  TokenService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  String? _token;
  String? _userId;
  String? _userStatus;

  String? get token => _token;
  String? get userId => _userId;
  String? get userStatus => _userStatus;
  bool get hasSession => _token?.isNotEmpty == true;
  bool get isVerified => _userStatus?.trim().toLowerCase() == 'verified';

  Future<void> restoreSession() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _tokenKey),
        _storage.read(key: _userIdKey),
        _storage.read(key: _userStatusKey),
      ]);
      _token = values[0];
      _userId = values[1];
      _userStatus = values[2];
    } catch (_) {
      _token = null;
      _userId = null;
      _userStatus = null;
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Keep the in-memory session when secure storage is unavailable.
    }
  }

  Future<void> saveUserId(String userId) async {
    _userId = userId;
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (_) {
      // Keep the in-memory session when secure storage is unavailable.
    }
  }

  Future<void> saveUserStatus(String status) async {
    _userStatus = status;
    try {
      await _storage.write(key: _userStatusKey, value: status);
    } catch (_) {
      // Keep the in-memory session when secure storage is unavailable.
    }
  }

  Future<void> clearToken() async {
    _token = null;
    _userId = null;
    _userStatus = null;
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userStatusKey),
      ]);
    } catch (_) {
      // The local session is already cleared in memory.
    }
  }
}
