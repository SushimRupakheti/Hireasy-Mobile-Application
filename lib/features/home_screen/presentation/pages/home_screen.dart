import 'package:flutter/material.dart';
import 'package:hireasy_mobile/core/widgets/button.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:hireasy_mobile/features/home_screen/presentation/pages/role_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🔷 Top Logo
                Image.asset("assets/icons/logo.png", height: 90),

                const SizedBox(height: 50),

                // 🔷 Your exported UI image
                Image.asset("assets/icons/home_group.png", fit: BoxFit.contain),

                const SizedBox(height: 40),

                // 🔷 Welcome Text
                const Text(
                  "Welcome to Hireasy Workforce",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Hire faster or get Hired faster!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // 🔷 Login Button
                CustomButton(
                  text: "Log In",
                  backgroundColor: Color(0xFF25478D),
                  textColor: Colors.white,
                  onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                  },
                ),

                const SizedBox(height: 10),

                // 🔷 Sign Up Button
               CustomButton(
                  text: "Sign Up",
                  textColor: Color(0xFF25478D),
                  onPressed: () {
                    // Navigate to the role selection screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(),
                      ),
                    );
                  },
                  type: ButtonType.text,

                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
