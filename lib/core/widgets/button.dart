import 'package:flutter/material.dart';

enum ButtonType {
  elevated,
  text,
  plain,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;

  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.elevated,
    this.backgroundColor = const Color(0xFF1E3A8A),
    this.textColor = Colors.white,
    this.height = 50,
    this.borderRadius = 30,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: textStyle ??
          TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );

    switch (type) {
      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          child: textWidget,
        );

      case ButtonType.plain:
        return SizedBox(
          width: double.infinity,
          height: height,
          child: Center(child: textWidget),
        );

      case ButtonType.elevated:
        return SizedBox(
          width: double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: textWidget,
          ),
        );
    }
  }
}