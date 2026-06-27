import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int _port = int.fromEnvironment('API_PORT', defaultValue: 5050);

  // Default LAN IP for physical device testing.
  static const String _defaultLanHost = '192.168.31.53';

  // Optional LAN override:
  // flutter run --dart-define=API_LAN_HOST=192.168.xx.xx
  static const String _lanHostFromEnv = String.fromEnvironment(
    'API_LAN_HOST',
    defaultValue: '',
  );

  // Full override, highest priority:
  // flutter run --dart-define=API_BASE_URL=http://192.168.xx.xx:5050/api
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get _lanHost =>
      _lanHostFromEnv.isNotEmpty ? _lanHostFromEnv : _defaultLanHost;

  static String baseUrl = _baseUrlOverride.isNotEmpty
      ? _baseUrlOverride
      : _startupBaseUrl();

  static bool isPhysicalDevice = true;

  static bool _initialized = false;
  static bool get initialized => _initialized;

  static String _startupBaseUrl() {
    if (kIsWeb) {
      return 'http://$_lanHost:$_port/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_port/api';
    }

    return 'http://localhost:$_port/api';
  }

  static Future<void> init() async {
    if (_initialized) return;

    if (_baseUrlOverride.isNotEmpty) {
      baseUrl = _baseUrlOverride;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[ApiEndpoints] Using override base URL -> $baseUrl');
      }
      return;
    }

    final deviceInfo = DeviceInfoPlugin();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      isPhysicalDevice = android.isPhysicalDevice;

      final host = isPhysicalDevice ? _lanHost : '10.0.2.2';
      baseUrl = 'http://$host:$_port/api';

      if (kDebugMode) {
        debugPrint(
          '[ApiEndpoints] Android '
          '${isPhysicalDevice ? "physical" : "emulator"} -> $baseUrl',
        );
      }

      _initialized = true;
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await deviceInfo.iosInfo;
      isPhysicalDevice = ios.isPhysicalDevice;

      final host = isPhysicalDevice ? _lanHost : 'localhost';
      baseUrl = 'http://$host:$_port/api';

      if (kDebugMode) {
        debugPrint(
          '[ApiEndpoints] iOS '
          '${isPhysicalDevice ? "physical" : "simulator"} -> $baseUrl',
        );
      }

      _initialized = true;
      return;
    }

    if (kIsWeb) {
      baseUrl = 'http://$_lanHost:$_port/api';
      isPhysicalDevice = true;

      if (kDebugMode) {
        debugPrint('[ApiEndpoints] Web -> $baseUrl');
      }

      _initialized = true;
      return;
    }

    baseUrl = 'http://localhost:$_port/api';
    isPhysicalDevice = true;

    if (kDebugMode) {
      debugPrint('[ApiEndpoints] Desktop/fallback -> $baseUrl');
    }

    _initialized = true;
  }

  // ================= AUTH ENDPOINTS =================
  static const String auth = '/auth';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String requestPasswordReset = '/auth/request-password-reset';
  static String resetPassword(String token) => '/auth/reset-password/$token';

  // ================= USER ENDPOINTS =================
  static String userById(String id) => '/auth/$id';
  static String updateUser(String id) => '/auth/update/$id';
  static const String currentUser = '/users/me';
  static const String currentUserDocument = '/users/me/document';
  static const String downloadCurrentUserDocument =
      '/users/me/document/download';

  // ================= JOB ENDPOINTS =================
  static const String jobs = '/jobs';
  static const String myJobs = '/jobs/mine';
  static String jobById(String jobId) => '/jobs/$jobId';
  static String applyForJob(String jobId) => '/jobs/$jobId/apply';
  static String jobApplicants(String jobId) => '/jobs/$jobId/applicants';
}
