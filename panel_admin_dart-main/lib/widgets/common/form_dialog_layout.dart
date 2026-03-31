import 'package:flutter/material.dart';
import 'custom_button.dart';

class FormDialogLayout extends StatefulWidget {
  final String title;
  final Widget content;
  final Future<bool> Function() onSave;
  final VoidCallback onSuccess;
  final String saveText;
  final String errorMessage;

  const FormDialogLayout({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    required this.onSuccess,
    this.saveText = 'Guardar',
    this.errorMessage = 'Error al procesar solicitud',
  });

  @override
  State<FormDialogLayout> createState() => _FormDialogLayoutState();
}

class _FormDialogLayoutState extends State<FormDialogLayout> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: widget.content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        _isSaving
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : CustomButton(
                onPressed: () async {
                  setState(() => _isSaving = true);
                  bool success = false;
                  try {
                    success = await widget.onSave();
                  } catch (e) {
                    success = false;
                  }
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    widget.onSuccess();
                  } else if (mounted) {
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.errorMessage)));
                  }
                },
                text: widget.saveText,
              ),
      ],
    );
  }
}
