import 'dart:convert';
import 'auth_service.dart';
import '../models/aviso_pendiente_model.dart';

class AvisosService {
  final String _baseUrl = 'http://20.157.65.103:8095/api/v1';
  final AuthService _authService = AuthService();

  Map<String, String> _getHeaders() {
    return const <String, String>{
      'Content-Type': 'application/json',
    };
  }

  Future<AvisoPendienteResponse> obtenerAvisoPendiente() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$_baseUrl/avisos/ap/pendiente'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return AvisoPendienteResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }

      final body = json.decode(response.body);
      throw Exception(body is Map<String, dynamic> && body['detail'] != null
          ? body['detail']
          : 'Error al obtener aviso pendiente');
    } catch (e) {
      throw Exception('Error al obtener aviso pendiente: $e');
    }
  }

  Future<Map<String, dynamic>> marcarVisualizado() async {
    try {
      final response = await _authService.authenticatedPost(
        Uri.parse('$_baseUrl/avisos/ap/visualizado'),
        headers: _getHeaders(),
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }

      final body = json.decode(response.body);
      throw Exception(body is Map<String, dynamic> && body['detail'] != null
          ? body['detail']
          : 'Error al marcar visualizado');
    } catch (e) {
      throw Exception('Error al marcar visualizado: $e');
    }
  }

  Future<Map<String, dynamic>> aceptarConforme() async {
    try {
      final response = await _authService.authenticatedPost(
        Uri.parse('$_baseUrl/avisos/ap/aceptar'),
        headers: _getHeaders(),
        body: jsonEncode({'conforme': true}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }

      final body = json.decode(response.body);
      throw Exception(body is Map<String, dynamic> && body['detail'] != null
          ? body['detail']
          : 'Error al aceptar el aviso');
    } catch (e) {
      throw Exception('Error al aceptar el aviso: $e');
    }
  }
}

