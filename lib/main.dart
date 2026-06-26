import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenService = TokenService();

  await Future.wait([
    ApiEndpoints.init().timeout(const Duration(seconds: 5)),
    tokenService.restoreSession().timeout(const Duration(seconds: 5)),
  ]).catchError((_) {
    // Start the UI even if device detection or secure storage is unavailable.
    return <void>[];
  });

  runApp(
    ProviderScope(
      overrides: [tokenServiceProvider.overrideWithValue(tokenService)],
      child: const App(),
    ),
  );
}
