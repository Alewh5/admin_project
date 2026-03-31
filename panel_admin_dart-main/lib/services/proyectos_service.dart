import 'dart:convert';
import '../config/constants.dart';
import 'api_client.dart';
import '../models/proyecto_model.dart';

class ProyectosService {
  final ApiClient _client = ApiClient();
  final String _apiUrl = '${Constants.baseUrl}/proyectos';

  Future<List<Proyecto>> getProyectos() async {
    final response = await _client.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((p) => Proyecto.fromJson(p)).toList();
    }
    throw Exception('Error al cargar proyectos');
  }

  Future<bool> createProyecto(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse(_apiUrl),
      body: json.encode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> updateProyecto(int id, Map<String, dynamic> payload) async {
    final response = await _client.put(
      Uri.parse('$_apiUrl/$id'),
      body: json.encode(payload),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteProyecto(int id) async {
    final response = await _client.delete(Uri.parse('$_apiUrl/$id'));
    return response.statusCode == 200;
  }

  // === EQUIPO / TEAM METHODS ===

  Future<List<Map<String, dynamic>>> getProjectTeam(int proyectoId) async {
    final response = await _client.get(Uri.parse('$_apiUrl/$proyectoId/equipo'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<bool> addTeamMember(int proyectoId, int userId, String rolEnProyecto) async {
    final response = await _client.post(
      Uri.parse('$_apiUrl/$proyectoId/equipo'),
      body: jsonEncode({
        'userId': userId,
        'rolEnProyecto': rolEnProyecto,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> removeTeamMember(int proyectoId, int userId) async {
    final response = await _client.delete(Uri.parse('$_apiUrl/$proyectoId/equipo/$userId'));
    return response.statusCode == 200;
  }
}
