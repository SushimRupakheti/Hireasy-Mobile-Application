import 'package:flutter/material.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/session_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SessionGate(),
    );
  }
}
