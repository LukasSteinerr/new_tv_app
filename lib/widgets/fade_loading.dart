import 'package:flutter/material.dart';

class FadeLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const FadeLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}
