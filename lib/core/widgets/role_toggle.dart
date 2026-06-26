import 'package:flutter/material.dart';

class RoleToggle extends StatelessWidget {
  final bool isWorker;
  final Function(bool) onChanged;

  const RoleToggle({
    super.key,
    required this.isWorker,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isWorker
                      ? const Color(0xFF25478D)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    "I'm a worker",
                    style: TextStyle(
                      color: isWorker
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: !isWorker
                      ? const Color(0xFF25478D)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    "I'm a client",
                    style: TextStyle(
                      color: !isWorker
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}