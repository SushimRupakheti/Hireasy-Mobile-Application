import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/register_usecase.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/login_screen.dart';

class WorkerSignupScreen extends ConsumerStatefulWidget {
  const WorkerSignupScreen({super.key});

  @override
  ConsumerState<WorkerSignupScreen> createState() => _WorkerSignupScreenState();
}

class _WorkerSignupScreenState extends ConsumerState<WorkerSignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;
  String? selectedField;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNoController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (selectedField == null) {
      _showMessage('Please select an interested field');
      return;
    }

    setState(() => isLoading = true);
    try {
      await ref
          .read(registerUsecaseProvider)
          .call(
            RegisterUsecaseParams(
              role: 'user',
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              contactNo: _contactNoController.text.trim(),
              address: _addressController.text.trim(),
              password: _passwordController.text,
              interestedFields: [selectedField!],
            ),
          );

      if (!mounted) return;
      _showMessage('Registered successfully. Please log in.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on DioException catch (error) {
      _showMessage(apiErrorMessage(error, fallback: 'Signup failed'));
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            children: [
              const SizedBox(height: 25),

              /// LOGO
              Image.asset("assets/icons/logo.png", width: 120),

              const SizedBox(height: 14),

              /// TITLE
              const Text(
                "Create your Personal account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                "Join Hireasy Workforce and start your journey",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 20),

              /// GOOGLE BUTTON
              OutlinedButton.icon(
                onPressed: () {},

                icon: Image.asset("assets/icons/google.png", width: 20),

                label: const Text(
                  "Sign in with Google",
                  style: TextStyle(color: Colors.black),
                ),

                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),

              const SizedBox(height: 20),

              /// OR
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Color(0xFF25478D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),

              const SizedBox(height: 20),

              /// FIRST + LAST NAME
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      hint: "First Name",
                      controller: _firstNameController,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildTextField(
                      hint: "Last Name",
                      controller: _lastNameController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildTextField(
                hint: "Email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                hint: "Contact No.",
                controller: _contactNoController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              _buildTextField(hint: "Address", controller: _addressController),

              const SizedBox(height: 14),

              /// PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",

                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),

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

              const SizedBox(height: 14),

              /// DROPDOWN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedField,
                    isExpanded: true,

                    hint: const Text("Select interested field"),

                    items: const [
                      DropdownMenuItem(value: "IT", child: Text("IT")),
                      DropdownMenuItem(
                        value: "Hospitality",
                        child: Text("Hospitality"),
                      ),
                      DropdownMenuItem(value: "Retail", child: Text("Retail")),
                    ],

                    onChanged: (value) {
                      setState(() {
                        selectedField = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// SIGNUP BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signup,

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
                          "Signup",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },

                child: const Text(
                  "Already have an account?",
                  style: TextStyle(color: Color(0xFF25478D), fontSize: 16),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,

        filled: true,
        fillColor: const Color(0xFFF2F2F2),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
