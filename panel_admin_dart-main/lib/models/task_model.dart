class TaskModel {
  final int id;
  final int proyectoId;
  final int? columnId;
  final int? sprintId;
  final String titulo;
  final String? descripcion;
  final String prioridad;
  final int dificultad;
  final double? estimacion;
  final String estado;
  final DateTime? fechaVencimiento;
  final DateTime? fechaInicioT;
  final DateTime? fechaFinT;
  final DateTime? fechaRealInicio;
  final DateTime? fechaRealFin;
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
    this.dificultad = 3,
    this.estimacion,
    required this.estado,
    this.fechaVencimiento,
    this.fechaInicioT,
    this.fechaFinT,
    this.fechaRealInicio,
    this.fechaRealFin,
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
      prioridad: json['prioridad']?.toString() ?? '3',
      dificultad: json['dificultad'] != null
          ? int.tryParse(json['dificultad'].toString()) ?? 3
          : 3,
      estimacion: json['estimacion'] != null
          ? double.tryParse(json['estimacion'].toString())
          : null,
      estado: json['estado'] ?? 'Por hacer',
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.tryParse(json['fechaVencimiento'])
          : null,
      fechaInicioT: json['fechaInicioT'] != null
          ? DateTime.tryParse(json['fechaInicioT'])
          : null,
      fechaFinT: json['fechaFinT'] != null
          ? DateTime.tryParse(json['fechaFinT'])
          : null,
      fechaRealInicio: json['fechaRealInicio'] != null
          ? DateTime.tryParse(json['fechaRealInicio'])
          : null,
      fechaRealFin: json['fechaRealFin'] != null
          ? DateTime.tryParse(json['fechaRealFin'])
          : null,
      orden: json['orden'] ?? 0,
      assignees: json['assignees'] is List ? json['assignees'] : [],
    );
  }
}
