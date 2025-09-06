import 'package:flutter/material.dart';

class FocusableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Icon? icon;

  const FocusableButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  @override
  _FocusableButtonState createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _isFocused
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: _isFocused ? Colors.black : Colors.white,
                  ),
                  child: widget.icon!,
                ),
                const SizedBox(width: 8),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: _isFocused ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
