import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/login_usecase.dart';
import 'package:hireasy_mobile/features/auth/presentation/widget/google_auth_section.dart';
import 'package:hireasy_mobile/features/home_screen/presentation/pages/role_selection_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/collective_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => isLoading = true);
    try {
      final user = await ref
          .read(loginUsecaseProvider)
          .call(
            LoginUsecaseParams(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );

      if (!mounted) return;
      if (user == null) {
        _showMessage('Invalid email or password');
        return;
      }

      final role = _normalizeRole(user.role);
      if (role == null) {
        _showMessage(
          'This account has an unsupported role: ${user.role}.',
          isError: true,
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => CollectiveScreen(role: role)),
        (_) => false,
      );
    } on DioException catch (error) {
      _showMessage(apiErrorMessage(error, fallback: 'Login failed'));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String? _normalizeRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'company':
      case 'client':
      case 'employer':
        return 'company';
      case 'user':
      case 'worker':
      case 'individual':
        return 'user';
      default:
        return null;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB42318) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 100),

                      /// LOGO
                      Image.asset("assets/icons/logo.png", width: 250),

                      const SizedBox(height: 40),

                      /// TITLE
                      const Text(
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Log in to continue to Hireasy Workforce",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),

                      const SizedBox(height: 40),

                      GoogleAuthSection(onGooglePressed: () {}),

                      const SizedBox(height: 40),

                      /// EMAIL
                      _buildTextField(
                        hint: "Email",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      /// PASSWORD
                      SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Password",
                            filled: true,
                            fillColor: const Color(0xFFF2F2F2),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Color(0xFF25478D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25478D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// SIGN UP LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(fontSize: 15),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to signup screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RoleSelectionScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Color(0xFF25478D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF2F2F2),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
