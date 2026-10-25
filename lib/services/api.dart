import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Matches RN: API_BASE = 'http://192.168.0.104:8000'
const String _baseUrl = 'http://192.168.0.104:8000';

// ── Token / session helpers ───────────────────────────────────────────────────

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<void> saveUser(Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user', jsonEncode(user));
}

Future<Map<String, dynamic>?> getUser() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('user');
  if (raw == null) return null;
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('user');
}

// ── Core fetch with 10-second timeout (mirrors RN AbortController) ────────────

Future<Map<String, dynamic>> apiFetch(
  String path, {
  String method = 'GET',
  Map<String, dynamic>? body,
}) async {
  final token = await getToken();

  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  final uri = Uri.parse('$_baseUrl$path');
  http.Response response;

  try {
    if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    }
  } on TimeoutException {
    // Matches RN: 'Cannot reach server. Make sure you are on the same WiFi network.'
    throw Exception(
        'Cannot reach server. Make sure you are on the same WiFi network.');
  }

  final data = jsonDecode(response.body);
  if (response.statusCode >= 400) {
    // RN reads errBody.detail first, then falls back
    final msg = (data is Map)
        ? (data['detail'] ?? data['message'] ?? 'Request failed')
        : 'Request failed';
    throw Exception(msg);
  }
  return data as Map<String, dynamic>;
}
