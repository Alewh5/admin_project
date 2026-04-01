import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showStatus;
  final bool isActive;

  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.showStatus = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final defaultBg = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.1);
    final defaultText = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? defaultBg,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: textColor ?? defaultText,
            ),
          ),
        ),
        if (showStatus)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
