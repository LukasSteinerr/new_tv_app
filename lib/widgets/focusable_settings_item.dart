import 'package:flutter/material.dart';

class FocusableSettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const FocusableSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  _FocusableSettingsItemState createState() => _FocusableSettingsItemState();
}

class _FocusableSettingsItemState extends State<FocusableSettingsItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _isFocused ? Colors.grey.withOpacity(0.3) : Colors.transparent,
          child: ListTile(
            leading: Icon(widget.icon, color: Colors.white70),
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle:
                widget.subtitle != null
                    ? Text(
                      widget.subtitle!,
                      style: const TextStyle(color: Colors.white60),
                    )
                    : null,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
