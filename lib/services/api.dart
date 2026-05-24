import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8089/api',
  );

  final Dio _dio;

  ApiService._(this._dio);

  static Future<ApiService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    return ApiService._(dio);
  }

  Future<Map<String, dynamic>> login(String fgbCard, String pin) async {
    final response = await _dio.post('/referee/login', data: {
      'fgb_card': fgbCard,
      'pin': pin,
    });
    final token = response.data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', response.data['user'].toString());
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return response.data;
  }

  Future<List<dynamic>> queue() async {
    final r = await _dio.get('/referee/queue');
    return r.data as List;
  }

  Future<Map<String, dynamic>> match(int id) async {
    final r = await _dio.get('/referee/matches/$id');
    return r.data;
  }

  Future<Map<String, dynamic>> start(int id) async {
    final r = await _dio.post('/referee/matches/$id/start');
    return r.data;
  }

  Future<Map<String, dynamic>> frame(int id, String winner) async {
    final r = await _dio.post('/referee/matches/$id/frame', data: {'winner': winner});
    return r.data;
  }

  Future<Map<String, dynamic>> end(int id, String? note) async {
    final r = await _dio.post('/referee/matches/$id/end', data: {'referee_note': note});
    return r.data;
  }

  Future<Map<String, dynamic>> sign(int matchId, int playerId) async {
    final r = await _dio.post('/referee/matches/$matchId/sign', data: {
      'player_id': playerId,
      'signature_data': '✓',
    });
    return r.data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
}
