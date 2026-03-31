import 'task_model.dart';

class TaskColumnModel {
  final int id;
  final int proyectoId;
  final String nombre;
  final String color;
  final int orden;
  final List<TaskModel> tasks;

  TaskColumnModel({
    required this.id,
    required this.proyectoId,
    required this.nombre,
    required this.color,
    required this.orden,
    this.tasks = const [],
  });

  factory TaskColumnModel.fromJson(Map<String, dynamic> json) {
    return TaskColumnModel(
      id: json['id'],
      proyectoId: json['proyectoId'],
      nombre: json['nombre'],
      color: json['color'] ?? '#000000',
      orden: json['orden'] ?? 0,
      tasks: json['tasks'] != null 
          ? (json['tasks'] as List).map((t) => TaskModel.fromJson(t)).toList()
          : [],
    );
  }
}
