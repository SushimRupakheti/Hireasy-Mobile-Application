import 'package:flutter/material.dart';

class GoogleAuthSection extends StatelessWidget {
  final VoidCallback onGooglePressed;

  const GoogleAuthSection({super.key, required this.onGooglePressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// GOOGLE BUTTON
        SizedBox(
          width: 200,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onGooglePressed,
            icon: Image.asset("assets/icons/google.png", width: 20),
            label: const Text(
              "Sign in with Google",
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 25),

        /// OR DIVIDER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
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
        ),
      ],
    );
  }
}
