import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class AuthService {
  final String authUrl = '${Constants.baseUrl}/auth';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$authUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(data);
        
        if (loginResponse.user != null) {
          await _storage.write(key: 'accessToken', value: loginResponse.accessToken);
          await _storage.write(key: 'refreshToken', value: loginResponse.refreshToken);
          await _storage.write(key: 'role', value: loginResponse.user!.role);
          await _storage.write(key: 'userId', value: loginResponse.user!.id.toString());
          await _storage.write(key: 'firstName', value: loginResponse.user!.firstName);
        }

        return loginResponse;
      } else {
        return LoginResponse(
          success: false,
          message: data['message'] ?? 'Credenciales inválidas',
        );
      }
    } catch (e) {
      return LoginResponse(success: false, message: 'Error de conexión');
    }
  }

  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$authUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final userId = await _storage.read(key: 'userId');
    if (userId != null) {
      await http.post(
        Uri.parse('$authUrl/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
    }
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }
}
