import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'api_client.dart';
import '../models/ticket_model.dart';

class TicketService {
  final ApiClient _client = ApiClient();
  final String _baseUrl = Constants.baseUrl;

  Future<Map<String, dynamic>> getTickets(
    String roomId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tickets/room/$roomId?page=$page&limit=$limit'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'tickets': (data['tickets'] as List)
            .map((t) => Ticket.fromJson(t))
            .toList(),
        'totalPages': data['totalPages'],
        'currentPage': data['currentPage'],
      };
    }
    return {'tickets': <Ticket>[], 'totalPages': 1, 'currentPage': 1};
  }

  Future<Map<String, dynamic>> getAllTickets({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final queryParams =
        'page=$page&limit=$limit${search.isNotEmpty ? '&search=${Uri.encodeComponent(search)}' : ''}';
    final response = await _client.get(
      Uri.parse('$_baseUrl/tickets/all?$queryParams'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'tickets': (data['tickets'] as List)
            .map((t) => Ticket.fromJson(t))
            .toList(),
        'totalPages': data['totalPages'],
        'currentPage': data['currentPage'],
      };
    }
    return {'tickets': <Ticket>[], 'totalPages': 1, 'currentPage': 1};
  }

  Future<bool> createTicket(
    String roomId,
    String title,
    String description,
    int status, {
    List<String> images = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/tickets'),
      body: jsonEncode({
        'roomId': roomId,
        'title': title,
        'description': description,
        'status': status,
        'images': images,
      }),
    );

    if (response.statusCode == 201) return true;

    print('ERROR DEL BACKEND AL CREAR TICKET: ${response.body}');
    return false;
  }

  Future<String?> uploadTicketImageBytes(
    List<int> bytes,
    String fileName,
  ) async {
    final uri = Uri.parse('$_baseUrl/chat/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final streamedResponse = await _client.sendMultipart(request);
    if (streamedResponse == null) return null;

    if (streamedResponse.statusCode == 200) {
      final responseData = await streamedResponse.stream.bytesToString();
      final decodedData = jsonDecode(responseData);
      return decodedData['fileUrl'];
    }
    return null;
  }

  Future<bool> updateTicketStatus(int ticketId, int status) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/tickets/$ticketId/status'),
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<Ticket?> addReplyToTicket(
    int ticketId,
    String message,
    String agentName, {
    int? newStatus,
  }) async {
    final body = <String, dynamic>{'message': message, 'agentName': agentName};
    if (newStatus != null) body['newStatus'] = newStatus;

    final response = await _client.post(
      Uri.parse('$_baseUrl/tickets/$ticketId/reply'),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200)
      return Ticket.fromJson(jsonDecode(response.body));
    return null;
  }
}
