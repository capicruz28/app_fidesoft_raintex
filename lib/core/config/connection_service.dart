import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

class ConnectionService {
  final http.Client _httpClient;

  ConnectionService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<String> obtenerBaseUrl(String ruc) async {
    final rucTrim = ruc.trim();
    if (rucTrim.isEmpty) {
      throw Exception('RUC inválido');
    }

    // Paso A — Login silencioso en la URL central
    late final String tokenCentral;
    try {
      final loginResp = await _httpClient.post(
        Uri.parse('${AppConfig.urlCentral}/auth/login/'),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Client-Type': 'mobile',
        },
        body: <String, String>{
          'username': 'admin',
          'password': 'password123',
        },
      );

      if (loginResp.statusCode != 200) {
        throw Exception('No se pudo conectar al servidor central');
      }

      final decoded = json.decode(loginResp.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['access_token'] == null ||
          decoded['access_token'].toString().isEmpty) {
        throw Exception('No se pudo conectar al servidor central');
      }

      tokenCentral = decoded['access_token'].toString();
    } catch (_) {
      throw Exception('No se pudo conectar al servidor central');
    }

    // Paso B — Obtener conexión con el JWT del paso A
    final uri = Uri.parse('${AppConfig.urlCentral}/conexion/buscar').replace(
      queryParameters: <String, String>{
        'ruc': rucTrim,
        'app': 'mobile',
      },
    );

    final resp = await _httpClient.get(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $tokenCentral',
      },
    );

    if (resp.statusCode == 404) {
      throw Exception('Cliente con RUC $rucTrim no encontrado');
    }
    if (resp.statusCode == 403) {
      throw Exception('Cliente inactivo, contacte al administrador');
    }
    if (resp.statusCode != 200) {
      throw Exception('Error al obtener configuración del cliente');
    }

    final decoded = json.decode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Error al obtener configuración del cliente');
    }

    final conexiones = decoded['conexiones'];
    if (conexiones is! List || conexiones.isEmpty) {
      throw Exception('Error al obtener configuración del cliente');
    }

    Map<String, dynamic>? principal;
    Map<String, dynamic>? primera;

    for (final c in conexiones) {
      if (c is! Map<String, dynamic>) continue;
      primera ??= c;
      final esPrincipal = c['es_principal'];
      if (esPrincipal == true) {
        principal = c;
        break;
      }
    }

    final seleccion = principal ?? primera;
    final baseUrl = seleccion?['base_url']?.toString().trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Error al obtener configuración del cliente');
    }

    return baseUrl;
  }
}

