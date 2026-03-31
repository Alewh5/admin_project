import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final bool isPositive;
  final bool isWarning;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    this.isPositive = true,
    this.isWarning = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning 
        ? Colors.orange 
        : (isPositive ? Colors.green : Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.circle,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
