import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isRefreshing = false;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _tryRefresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        return true;
      }

      await _storage.deleteAll();
      _redirectToLogin();
      return false;
    } catch (_) {
      await _storage.deleteAll();
      _redirectToLogin();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _redirectToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<http.Response> _execute(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = await _authHeaders();
    final response = await request(headers);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (!refreshed) return response;

      final newHeaders = await _authHeaders();
      return await request(newHeaders);
    }

    return response;
  }

  Future<http.Response> get(Uri url) async {
    return _execute((headers) => http.get(url, headers: headers));
  }

  Future<http.Response> post(Uri url, {Object? body}) async {
    return _execute((headers) => http.post(url, headers: headers, body: body));
  }

  Future<http.Response> put(Uri url, {Object? body}) async {
    return _execute((headers) => http.put(url, headers: headers, body: body));
  }

  Future<http.Response> delete(Uri url) async {
    return _execute((headers) => http.delete(url, headers: headers));
  }

  Future<http.Response> patch(Uri url, {Object? body}) async {
    return _execute((headers) => http.patch(url, headers: headers, body: body));
  }

  Future<http.StreamedResponse?> sendMultipart(
    http.MultipartRequest request,
  ) async {
    final token = await _storage.read(key: 'accessToken');
    request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();

    if (response.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (!refreshed) return null;

      final newToken = await _storage.read(key: 'accessToken');
      final newRequest = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['Authorization'] = 'Bearer $newToken'
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);

      return await newRequest.send();
    }

    return response;
  }
}
