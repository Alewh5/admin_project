import 'dart:convert';
import '../config/constants.dart';
import 'api_client.dart';
import '../models/task_column_model.dart';
import '../models/task_model.dart';
import '../models/task_comment_model.dart';
import '../models/project_document_model.dart';
import '../models/sprint_model.dart';

class KanbanService {
  final ApiClient _apiClient = ApiClient();
  final String _baseUrl = Constants.baseUrl;

  // === COLUMNS & TASKS ===
  Future<List<TaskColumnModel>> getProjectColumns(int proyectoId, {int? sprintId}) async {
    final baseApiUrl = '$_baseUrl/kanban/proyectos/$proyectoId/columns';
    final url = sprintId != null ? '$baseApiUrl?sprintId=$sprintId' : baseApiUrl;
    
    final response = await _apiClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TaskColumnModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load columns');
    }
  }

  Future<TaskModel?> createTask(int proyectoId, int sprintId, int columnId, String titulo, String descripcion) async {
    final response = await _apiClient.post(
      Uri.parse('$_baseUrl/kanban/tasks'),
      body: jsonEncode({
        'proyectoId': proyectoId,
        'sprintId': sprintId,
        'columnId': columnId,
        'titulo': titulo,
        'descripcion': descripcion,
        'prioridad': 'Media',
      }),
    );
    if (response.statusCode == 201) return TaskModel.fromJson(jsonDecode(response.body));
    return null;
  }

  Future<bool> moveTask(int taskId, int newColumnId) async {
    final response = await _apiClient.put(
      Uri.parse('$_baseUrl/kanban/tasks/$taskId'),
      body: jsonEncode({'columnId': newColumnId}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateTaskDetails(int taskId, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      Uri.parse('$_baseUrl/kanban/tasks/$taskId'),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // === COMMENTS ===
  Future<Map<String, dynamic>> getTaskComments(int taskId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      Uri.parse('$_baseUrl/kanban/tasks/$taskId/comments?page=$page&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'items': (data['items'] as List).map((t) => TaskCommentModel.fromJson(t)).toList(),
        'totalPages': data['totalPages'],
        'currentPage': data['currentPage'],
      };
    }
    return {'items': <TaskCommentModel>[], 'totalPages': 1, 'currentPage': 1};
  }

  // === DOCUMENTS ===
  Future<Map<String, dynamic>> getProjectDocuments(int proyectoId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/documents?page=$page&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'items': (data['items'] as List).map((t) => ProjectDocumentModel.fromJson(t)).toList(),
        'totalPages': data['totalPages'],
        'currentPage': data['currentPage'],
      };
    }
    return {'items': <ProjectDocumentModel>[], 'totalPages': 1, 'currentPage': 1};
  }

  // === METRICS ===
  Future<Map<String, dynamic>> getProjectMetrics(int proyectoId) async {
    final response = await _apiClient.get(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/rendimiento'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load metrics');
  }

  // === PROJECT CHAT ===
  Future<Map<String, dynamic>> getProjectChat(int proyectoId, {int page = 1, int limit = 30}) async {
    final response = await _apiClient.get(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/chat?page=$page&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'items': (data['items'] as List).map((t) => TaskCommentModel.fromJson(t)).toList(),
        'totalPages': data['totalPages'],
        'currentPage': data['currentPage'],
      };
    }
    return {'items': <TaskCommentModel>[], 'totalPages': 1, 'currentPage': 1};
  }

  Future<TaskCommentModel?> addProjectChat(int proyectoId, int userId, String contenido) async {
    final response = await _apiClient.post(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/chat'),
      body: jsonEncode({
        'userId': userId,
        'contenido': contenido,
      }),
    );
    if (response.statusCode == 201) return TaskCommentModel.fromJson(jsonDecode(response.body));
    return null;
  }

  // === INITIALIZATION & COLUMN MGMT ===
  Future<bool> createColumn(int proyectoId, String nombre, String color, int orden) async {
    final response = await _apiClient.post(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/columns'),
      body: jsonEncode({'nombre': nombre, 'color': color, 'orden': orden}),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateColumn(int columnId, String nombre, String color) async {
    final response = await _apiClient.put(
      Uri.parse('$_baseUrl/kanban/columns/$columnId'),
      body: jsonEncode({'nombre': nombre, 'color': color}),
    );
    return response.statusCode == 200;
  }

  Future<void> initializeDefaultColumns(int proyectoId) async {
    await createColumn(proyectoId, 'Por Hacer', '#e0e0e0', 1);
    await createColumn(proyectoId, 'En Progreso', '#42a5f5', 2);
    await createColumn(proyectoId, 'Completado', '#66bb6a', 3);
  }

  // === SPRINTS ===
  Future<List<SprintModel>> getSprints(int proyectoId) async {
    final response = await _apiClient.get(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/sprints')
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => SprintModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<SprintModel?> createSprint(int proyectoId, String nombre, String descripcion) async {
    final response = await _apiClient.post(
      Uri.parse('$_baseUrl/kanban/proyectos/$proyectoId/sprints'),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': 0,
      }),
    );
    if (response.statusCode == 201) return SprintModel.fromJson(jsonDecode(response.body));
    return null;
  }
}

