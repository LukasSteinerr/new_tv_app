import 'package:flutter/material.dart';

/// A Netflix-style loading indicator that uses a solid color background
/// without any spinning indicators - just like Netflix's skeleton screens
class NetflixStyleLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool
  showLogo; // Option to show logo (not used but kept for compatibility)

  const NetflixStyleLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 8.0,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark grey background like Netflix
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
