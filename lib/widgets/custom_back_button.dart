import 'package:flutter/material.dart';

/// Custom back button widget that navigates to the previous page
/// Uses Navigator.pop() to go back in navigation stack
class CustomBackButton extends StatelessWidget {
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  const CustomBackButton({
    super.key,
    this.color = Colors.white,
    this.size = 24,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          // Default behavior: pop the current route
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      icon: Icon(
        Icons.arrow_back,
        color: color,
        size: size,
      ),
      tooltip: 'Back',
    );
  }
}
