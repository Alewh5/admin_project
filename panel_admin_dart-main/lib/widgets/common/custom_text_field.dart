import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool filled;
  final Color? fillColor;
  final int minLines;
  final int maxLines;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.filled = true,
    this.fillColor,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        filled: filled,
        fillColor:
            fillColor ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                size: 20,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
