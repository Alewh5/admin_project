import 'package:flutter/material.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? actionWidget;
  final EdgeInsetsGeometry padding;

  const ScreenHeader({
    super.key,
    required this.title,
    this.actionWidget,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (actionWidget != null) ...[
            const SizedBox(width: 16),
            actionWidget!,
          ],
        ],
      ),
    );
  }
}
