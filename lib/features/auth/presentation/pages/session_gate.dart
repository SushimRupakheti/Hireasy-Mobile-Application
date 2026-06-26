import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/get_current_user.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/collective_screen.dart';

class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key});

  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate> {
  late Future<AuthEntity?> _session;

  @override
  void initState() {
    super.initState();
    _session = _loadSession();
  }

  Future<AuthEntity?> _loadSession() async {
    final tokenService = ref.read(tokenServiceProvider);
    if (!tokenService.hasSession) return null;

    try {
      return await ref.read(getCurrentUserUsecaseProvider).call();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await tokenService.clearToken();
        return null;
      }
      rethrow;
    }
  }

  void _retry() {
    setState(() => _session = _loadSession());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthEntity?>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SessionLoadingScreen();
        }

        if (snapshot.hasError) {
          return _SessionErrorScreen(
            onRetry: _retry,
            onLogin: () async {
              await ref.read(tokenServiceProvider).clearToken();
              if (mounted) _retry();
            },
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return CollectiveScreen(role: user.role);
      },
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SessionErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onLogin;

  const _SessionErrorScreen({required this.onRetry, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 50,
                color: Color(0xFF7A8498),
              ),
              const SizedBox(height: 14),
              const Text(
                'Could not restore your session',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(onPressed: onLogin, child: const Text('Log in again')),
            ],
          ),
        ),
      ),
    );
  }
}
