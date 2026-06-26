import 'package:flutter/material.dart';
import 'package:hireasy_mobile/core/widgets/button.dart';
import 'package:hireasy_mobile/core/widgets/role_toggle.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/client_signup_screen.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/worker_signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool isWorker = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Image.asset(
              isWorker
                  ? "assets/images/worker.png"
                  : "assets/images/client.png",
              key: ValueKey(isWorker),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          /// DARK OVERLAY
          Container(color: Colors.black.withOpacity(0.15)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  /// LOGO
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Image.asset("assets/icons/logo.png", width: 140),
                    ),
                  ),

                  const Spacer(flex: 6),

                  /// INFO CARD
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Align(
                      key: ValueKey(isWorker),
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: const Offset(-20, 0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.90,
                          padding: const EdgeInsets.fromLTRB(40, 24, 24, 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADLINE
                              if (isWorker)
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF13284B),
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(text: "Find temporary\n"),
                                      TextSpan(
                                        text: "jobs",
                                        style: TextStyle(
                                          color: Color(0xFF25478D),
                                        ),
                                      ),
                                      TextSpan(
                                        text: " in your\nbest time slot.",
                                      ),
                                    ],
                                  ),
                                )
                              else
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF13284B),
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Find temporary\nworkers and\n",
                                      ),
                                      TextSpan(
                                        text: "hire",
                                        style: TextStyle(
                                          color: Color(0xFF25478D),
                                        ),
                                      ),
                                      TextSpan(text: " immediately."),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 20),

                              /// ICON + DESCRIPTION
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.asset(
                                      isWorker
                                          ? "assets/icons/worker_icon.png"
                                          : "assets/icons/client_icon.png",
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Text(
                                      isWorker
                                          ? "Flexible jobs. Real opportunities.\nWork when it suits you."
                                          : "Quick hiring. Reliable workers.\nBuilt for your business.",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF25478D),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// ROLE TOGGLE
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: RoleToggle(
                      isWorker: isWorker,
                      onChanged: (value) {
                        setState(() {
                          isWorker = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// SIGN UP BUTTON
              CustomButton(
  text: "Sign Up",
  backgroundColor: Colors.white,
  textColor: const Color(0xFF25478D),
  onPressed: () {
    if (isWorker) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WorkerSignupScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ClientSignupScreen(),
        ),
      );
    }
  },
),

                  const SizedBox(height: 14),

                  /// LOGIN TEXT
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an Account?",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
