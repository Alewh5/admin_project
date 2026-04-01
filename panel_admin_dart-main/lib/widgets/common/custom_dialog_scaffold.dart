import 'package:flutter/material.dart';
import 'custom_button.dart';

class CustomDialogScaffold extends StatelessWidget {
  final String title;
  final Widget content;
  final String submitText;
  final VoidCallback onSubmit;
  final double width;

  const CustomDialogScaffold({
    super.key,
    required this.title,
    required this.content,
    required this.submitText,
    required this.onSubmit,
    this.width = 400,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: SingleChildScrollView(
        child: SizedBox(width: width, child: content),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        CustomButton(
          text: submitText,
          width: 120,
          height: 40,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
