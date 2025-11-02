import 'package:flutter/material.dart';

class IPhoneSimulator extends StatelessWidget {
  final Widget child;
  final bool showFrame;

  const IPhoneSimulator({
    super.key,
    required this.child,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    // iPhone 15 dimensions: 393×852 logical pixels
    const double iPhoneWidth = 393.0;
    const double iPhoneHeight = 852.0;

    if (!showFrame) {
      // Return child with constraints but no visual frame
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: iPhoneWidth,
            maxHeight: iPhoneHeight,
          ),
          child: child,
        ),
      );
    }

    // Return child with iPhone-like frame - optimized for fixed window size
    return Scaffold(
      backgroundColor:
          Colors.grey.shade900, // Dark background that matches window
      body: Center(
        child: Container(
          width: iPhoneWidth,
          height: iPhoneHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              40,
            ), // Rounded corners like iPhone
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
