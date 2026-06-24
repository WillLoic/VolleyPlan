import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static const _tokenKey = 'jwt_token';

  // ── Token ────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Headers ──────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Generic requests ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    final headers = await _headers();
    final res = await _runSafe(() => http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: headers,
    ));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    final res = await _runSafe(() => http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final res = await _runSafe(() => http.put(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
    return _parse(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _headers();
    final res = await _runSafe(() => http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: headers,
    ));
    return _parse(res);
  }

  // Téléchargement binaire (PDF)
  static Future<List<int>> getBytes(String path) async {
    final headers = await _headers();
    final res = await _runSafe(() => http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: headers,
    ));
    if (res.statusCode != 200) {
      throw _parseException(res);
    }
    return res.bodyBytes;
  }

  // ── Request Runner & Parsers ─────────────────────────────────────
  static Future<http.Response> _runSafe(Future<http.Response> Function() requestFn) async {
    try {
      return await requestFn().timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw NetworkException("Le serveur ne répond pas. Vérifiez votre connexion internet ou réessayez plus tard.");
    } catch (e) {
      throw NetworkException();
    }
  }

  static Map<String, dynamic> _parse(http.Response res) {
    if (res.statusCode >= 400) {
      throw _parseException(res);
    }
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is List) return {'data': body};
      return body as Map<String, dynamic>;
    } catch (e) {
      throw ApiException("Format de réponse invalide de la part du serveur.", res.statusCode);
    }
  }

  static ApiException _parseException(http.Response res) {
    String? message;
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map) {
        message = body['error'] ?? body['message'];
      }
    } catch (_) {
      // Si la réponse n'est pas un JSON valide (ex: HTML 500)
    }

    final code = res.statusCode;
    if (code == 400) {
      return BadRequestException(message ?? "Requête incorrecte.");
    } else if (code == 401) {
      return UnauthorizedException(message ?? "Session expirée ou non autorisée. Veuillez vous reconnecter.");
    } else if (code == 403) {
      return ForbiddenException(message ?? "Vous n'avez pas l'autorisation d'accéder à cette ressource.");
    } else if (code == 404) {
      return NotFoundException(message ?? "La ressource demandée est introuvable.");
    } else if (code >= 500) {
      return ServerException(message ?? "Erreur interne du serveur. Veuillez réessayer plus tard.", code);
    }
    return ApiException(message ?? "Une erreur inattendue est survenue (code $code).", code);
  }
}

// ── Custom Exception Hierarchy ──────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException([String message = "Impossible de se connecter au serveur. Vérifiez votre connexion internet ou réessayez plus tard."])
      : super(message, 0);
}

class BadRequestException extends ApiException {
  BadRequestException([String message = "Requête incorrecte."])
      : super(message, 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = "Session expirée ou non autorisée. Veuillez vous reconnecter."])
      : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = "Vous n'avez pas l'autorisation d'accéder à cette ressource."])
      : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = "La ressource demandée est introuvable."])
      : super(message, 404);
}

class ServerException extends ApiException {
  ServerException([super.message = "Erreur interne du serveur. Veuillez réessayer plus tard.", super.statusCode = 500]);
}