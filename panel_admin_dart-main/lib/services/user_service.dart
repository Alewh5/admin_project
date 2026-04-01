import 'dart:convert';
import '../config/constants.dart';
import 'api_client.dart';

class UserService {
  final String userApiUrl = '${Constants.baseUrl}/users';
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getUsers() async {
    final response = await _client.get(Uri.parse(userApiUrl));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<List<dynamic>> getInvitableUsers() async {
    final response = await _client.get(Uri.parse('$userApiUrl/invitable'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    final response = await _client.post(
      Uri.parse(userApiUrl),
      body: jsonEncode(userData),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    final response = await _client.put(
      Uri.parse('$userApiUrl/$id'),
      body: jsonEncode(userData),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int id) async {
    final response = await _client.delete(Uri.parse('$userApiUrl/$id'));
    return response.statusCode == 200;
  }

  Future<bool> toggleUserStatus(int id) async {
    final response = await _client.patch(Uri.parse('$userApiUrl/$id/status'));
    return response.statusCode == 200;
  }
}
