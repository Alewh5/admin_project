import 'package:flutter/material.dart';

class ActionButtonsCell extends StatelessWidget {
  final bool showView;
  final bool showEdit;
  final bool showDelete;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String viewTooltip;
  final String editTooltip;
  final String deleteTooltip;

  const ActionButtonsCell({
    super.key,
    this.showView = false,
    this.showEdit = false,
    this.showDelete = false,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.viewTooltip = 'Ver Detalles',
    this.editTooltip = 'Editar',
    this.deleteTooltip = 'Eliminar',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showView)
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
            tooltip: viewTooltip,
            onPressed: onView,
          ),
        if (showEdit)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.orange),
            tooltip: editTooltip,
            onPressed: onEdit,
          ),
        if (showDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: deleteTooltip,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
