import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import 'status_badge.dart';

class KanbanTaskCard extends StatelessWidget {
  final TaskModel task;

  const KanbanTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(
                  text: task.prioridad, 
                  isWarning: task.prioridad == 'Alta' || task.prioridad == 'Urgente',
                  isPositive: task.prioridad == 'Baja',
                ),
              ],
            ),
            if (task.descripcion != null && task.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Theme.of(context).iconTheme.color),
                    const SizedBox(width: 4),
                    Text(
                      task.fechaVencimiento != null 
                          ? '${task.fechaVencimiento!.day}/${task.fechaVencimiento!.month}'
                          : 'Sin fecha',
                      style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
