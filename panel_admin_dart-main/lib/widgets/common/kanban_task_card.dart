import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import 'status_badge.dart';

import '../../config/constants.dart';

class KanbanTaskCard extends StatelessWidget {
  final TaskModel task;

  const KanbanTaskCard({super.key, required this.task});

  String _getPrioridadLabel(String val) {
    switch (val) {
      case '1': return '1 - Muy Baja';
      case '2': return '2 - Baja';
      case '3': return '3 - Media';
      case '4': return '4 - Alta';
      case '5': return '5 - Urgente';
      default: return val.length == 1 ? '$val - Media' : val;
    }
  }

  Color _getPrioridadColor(String val) {
    switch (val) {
      case '1': return Colors.grey;
      case '2': return Colors.lightBlue;
      case '3': return Colors.green;
      case '4': return Colors.orange;
      case '5': return Colors.red;
      default: return Colors.green;
    }
  }

  Color _getDificultadColor(int val) {
    if (val <= 2) return Colors.green;
    if (val == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Obtener primer asignado para el avatar si existe
    Map<String, dynamic>? firstAssignee;
    if (task.assignees.isNotEmpty) {
      firstAssignee = task.assignees.first as Map<String, dynamic>;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPrioridadColor(task.prioridad).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getPrioridadColor(task.prioridad).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 10, color: _getPrioridadColor(task.prioridad)),
                      const SizedBox(width: 4),
                      Text(
                         _getPrioridadLabel(task.prioridad),
                         style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPrioridadColor(task.prioridad)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (task.descripcion != null && task.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, size: 12, color: _getDificultadColor(task.dificultad)),
                          const SizedBox(width: 4),
                          Text(
                            'Dif: ${task.dificultad}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getDificultadColor(task.dificultad)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (firstAssignee != null)
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    backgroundImage: firstAssignee['avatar'] != null 
                        ? NetworkImage('${Constants.baseUrl.replaceAll('/api', '')}${firstAssignee['avatar']}') 
                        : null,
                    child: firstAssignee['avatar'] == null 
                        ? Text(
                            firstAssignee['firstName'].substring(0, 1).toUpperCase(),
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
