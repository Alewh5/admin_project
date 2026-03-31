class ProjectDocumentModel {
  final int id;
  final int proyectoId;
  final int? taskId;
  final String nombre;
  final String ruta;
  final String? tipo;
  final String createdAt;
  final Map<String, dynamic>? task;

  ProjectDocumentModel({
    required this.id,
    required this.proyectoId,
    this.taskId,
    required this.nombre,
    required this.ruta,
    this.tipo,
    required this.createdAt,
    this.task,
  });

  factory ProjectDocumentModel.fromJson(Map<String, dynamic> json) {
    return ProjectDocumentModel(
      id: json['id'],
      proyectoId: json['proyectoId'],
      taskId: json['taskId'],
      nombre: json['nombre'],
      ruta: json['ruta'],
      tipo: json['tipo'],
      createdAt: json['createdAt'],
      task: json['task'],
    );
  }
}
