import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Production par défaut. Override en dev avec :
  //   flutter run --dart-define=API_BASE=http://10.0.2.2:8089/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://club8pool.com/api',
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
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    // ─── Logging ───────────────────────────────────────────────────
    // Trace chaque requête/réponse/erreur dans la console (flutter logs,
    // Xcode/Android Studio, devtools). Le token est tronqué pour ne pas
    // polluer la sortie.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final auth = options.headers['Authorization']?.toString() ?? '';
        final shortAuth = auth.length > 30 ? '${auth.substring(0, 30)}…' : auth;
        _log('→ ${options.method} ${options.uri}\n'
            '  headers: { Authorization: $shortAuth }\n'
            '  body: ${options.data ?? '(none)'}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _log('← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}\n'
            '  data: ${_truncate(response.data)}');
        handler.next(response);
      },
      onError: (e, handler) {
        _log('! ${e.response?.statusCode ?? '?'} ${e.requestOptions.method} ${e.requestOptions.uri}\n'
            '  type: ${e.type}\n'
            '  message: ${e.message}\n'
            '  response: ${_truncate(e.response?.data)}');
        handler.next(e);
      },
    ));

    return ApiService._(dio);
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[API] $msg');
    developer.log(msg, name: 'club8pool.api');
  }

  static String _truncate(dynamic data, [int max = 400]) {
    if (data == null) return '(empty)';
    final s = data.toString();
    return s.length > max ? '${s.substring(0, max)}… (${s.length - max} chars cut)' : s;
  }

  Future<Map<String, dynamic>> login(String name, String pin) async {
    final response = await _dio.post('/referee/login', data: {
      'name': name,
      'pin': pin,
    });
    final token = response.data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', response.data['user'].toString());
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return response.data;
  }

  Future<Map<String, dynamic>> me() async {
    final r = await _dio.get('/referee/me');
    return r.data;
  }

  Future<List<dynamic>> queue() async {
    final r = await _dio.get('/referee/queue');
    return r.data as List;
  }

  Future<List<dynamic>> tables() async {
    final r = await _dio.get('/referee/tables');
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

  /// Mark a frame winner. [winner] must be 'A' or 'B' (or 'draw' for a tie).
  /// Optionally flag a warning given to one of the players.
  Future<Map<String, dynamic>> frame(int id, String winner, {bool? warningA, bool? warningB}) async {
    final r = await _dio.post('/referee/matches/$id/frame', data: {
      'winner': winner,
      if (warningA != null) 'warning_a': warningA,
      if (warningB != null) 'warning_b': warningB,
    });
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

  Future<List<dynamic>> available() async {
    final r = await _dio.get('/referee/available');
    return r.data as List;
  }

  Future<Map<String, dynamic>> claim(int id) async {
    final r = await _dio.post('/referee/matches/$id/claim');
    return r.data;
  }

  Future<Map<String, dynamic>> assignTable(int matchId, int tableId) async {
    final r = await _dio.post('/referee/matches/$matchId/table', data: {'table_id': tableId});
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

  /// Quick GET to verify the API is reachable + valid token (if any).
  /// Returns true on 2xx, false on any error.
  Future<bool> ping() async {
    try {
      await _dio.get('/referee/me');
      return true;
    } catch (_) {
      return false;
    }
  }
}
