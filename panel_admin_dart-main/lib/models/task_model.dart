class TaskModel {
  final int id;
  final int proyectoId;
  final int? columnId;
  final int? sprintId;
  final String titulo;
  final String? descripcion;
  final String prioridad;
  final String estado;
  final DateTime? fechaVencimiento;
  final int orden;
  final List<dynamic> assignees;

  TaskModel({
    required this.id,
    required this.proyectoId,
    this.columnId,
    this.sprintId,
    required this.titulo,
    this.descripcion,
    required this.prioridad,
    required this.estado,
    this.fechaVencimiento,
    required this.orden,
    this.assignees = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      proyectoId: json['proyectoId'],
      columnId: json['columnId'],
      sprintId: json['sprintId'],
      titulo: json['titulo'] ?? 'Sin Título',
      descripcion: json['descripcion'],
      prioridad: json['prioridad'] ?? 'Media',
      estado: json['estado'] ?? 'Por hacer',
      fechaVencimiento: json['fechaVencimiento'] != null 
          ? DateTime.tryParse(json['fechaVencimiento']) 
          : null,
      orden: json['orden'] ?? 0,
      assignees: json['assignees'] is List ? json['assignees'] : [],
    );
  }
}
