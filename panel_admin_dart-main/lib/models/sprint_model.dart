class SprintModel {
  final int id;
  final int proyectoId;
  final String nombre;
  final String? descripcion;
  final int estado;

  SprintModel({
    required this.id,
    required this.proyectoId,
    required this.nombre,
    this.descripcion,
    required this.estado,
  });

  factory SprintModel.fromJson(Map<String, dynamic> json) {
    return SprintModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      proyectoId: json['proyectoId'] is int 
          ? json['proyectoId'] 
          : int.tryParse(json['proyectoId'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'],
      estado: json['estado'] is int 
          ? json['estado'] 
          : int.tryParse(json['estado']?.toString() ?? '0') ?? 0,
    );
  }
}
