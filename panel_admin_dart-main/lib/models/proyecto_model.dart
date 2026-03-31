class Proyecto {
  final int id;
  final String nombre;
  final String? descripcion;
  final String estado;
  final int? encargadoProyecto;
  final DateTime? estimacionInicio;
  final DateTime? estimacionFin;
  final String? assignedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Proyecto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.estado,
    this.encargadoProyecto,
    this.estimacionInicio,
    this.estimacionFin,
    this.assignedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'Inactivo',
      encargadoProyecto: json['encargadoProyecto'],
      estimacionInicio: json['estimacionInicio'] != null
          ? DateTime.parse(json['estimacionInicio'])
          : null,
      estimacionFin: json['estimacionFin'] != null
          ? DateTime.parse(json['estimacionFin'])
          : null,
      assignedBy: json['assignedBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'encargadoProyecto': encargadoProyecto,
      'estimacionInicio': estimacionInicio?.toIso8601String(),
      'estimacionFin': estimacionFin?.toIso8601String(),
      'assignedBy': assignedBy,
    };
  }
}
