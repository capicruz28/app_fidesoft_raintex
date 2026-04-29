// lib/data/services/vacaciones_permisos_service.dart
import 'dart:convert';
import '../models/solicitud_model.dart';
import '../models/saldo_vacaciones_model.dart';
import '../models/trabajador_model.dart';
import 'auth_service.dart';

class VacacionesPermisosService {
  // URL del servidor de producción
  // Nota: 10.0.2.2 es la IP especial del emulador Android para acceder al localhost del host
  // Para pruebas locales, usar: http://10.0.2.2:8000/api/v1
  final String baseUrl = 'http://20.157.65.103:8095/api/v1';
  final AuthService _authService = AuthService();

  // Método auxiliar para obtener el token de autenticación
  Future<String?> _getAuthToken() async {
    return _authService.getAccessToken();
  }

  // Método auxiliar para obtener el nombre de usuario del token
  Future<String?> _getUsuarioFromToken() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/auth/me/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return userData['nombre_usuario'] ?? userData['nombreUsuario'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (includeAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ============================================
  // VACACIONES
  // ============================================

  /// Solicitar vacaciones
  Future<SolicitudModel> solicitarVacaciones({
    required String codigoTrabajador,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double diasSolicitados,
    String? observacion,
    String?
    usuario, // Nombre de usuario (opcional, se obtiene del token si no se proporciona)
  }) async {
    try {
      // Si no se proporciona el usuario, intentar obtenerlo del token
      String? usuarioRegistro = usuario;
      if (usuarioRegistro == null || usuarioRegistro.isEmpty) {
        usuarioRegistro = await _getUsuarioFromToken();
      }

      final body = <String, dynamic>{
        'tipo_solicitud': 'V',
        'codigo_trabajador': codigoTrabajador,
        'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
        'fecha_fin': fechaFin.toIso8601String().split('T')[0],
        'dias_solicitados': diasSolicitados,
        if (observacion != null && observacion.isNotEmpty)
          'observacion': observacion,
        if (usuarioRegistro != null && usuarioRegistro.isNotEmpty)
          'usuario_registro': usuarioRegistro,
      };

      final response = await _authService.authenticatedPost(
        Uri.parse('$baseUrl/vacaciones/solicitar'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SolicitudModel.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al solicitar vacaciones');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  /// Obtener mis solicitudes de vacaciones
  /// [page] Número de página (por defecto 1)
  /// [limit] Cantidad de elementos por página (por defecto 20)
  Future<List<SolicitudModel>> misSolicitudesVacaciones({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/vacaciones/mis-solicitudes').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await _authService.authenticatedGet(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Debug: imprimir el tipo de respuesta
        print('Tipo de respuesta: ${decoded.runtimeType}');
        print('Respuesta completa: $decoded');

        // La respuesta es un objeto con paginación que contiene 'items'
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('items')) {
            final items = decoded['items'];
            if (items is List) {
              return items
                  .map(
                    (json) =>
                        SolicitudModel.fromJson(json as Map<String, dynamic>),
                  )
                  .toList();
            } else {
              print('Error: items no es una lista, es: ${items.runtimeType}');
              return [];
            }
          } else {
            print('Error: La respuesta no contiene la clave "items"');
            print('Claves disponibles: ${decoded.keys.toList()}');
            return [];
          }
        } else if (decoded is List) {
          // Por compatibilidad, si la respuesta es directamente un array
          return decoded
              .map(
                (json) => SolicitudModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else {
          print('Error: Tipo inesperado de respuesta: ${decoded.runtimeType}');
          return [];
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'Error al obtener solicitudes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en misSolicitudesVacaciones: $e');
      // Si el error es de tipo, intentar manejar mejor el mensaje
      if (e.toString().contains('is not a subtype')) {
        throw Exception(
          'Error: El servidor devolvió un formato de datos inesperado. Detalle: $e',
        );
      }
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener detalle de una solicitud
  Future<SolicitudModel> obtenerSolicitud(int idSolicitud) async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/solicitud/$idSolicitud'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return SolicitudModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener solicitud: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  /// Obtener el conteo de solicitudes pendientes de aprobar
  Future<int> obtenerConteoPendientesAprobar() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/pendientes-aprobar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Si es un array, retornar su longitud
        if (decoded is List) {
          return decoded.length;
        }
        // Si es un objeto con paginación, retornar el total
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('total')) {
            return decoded['total'] as int? ?? 0;
          }
          if (decoded.containsKey('items') && decoded['items'] is List) {
            return (decoded['items'] as List).length;
          }
        }
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error al obtener conteo de pendientes: $e');
      return 0;
    }
  }

  /// Obtener el conteo de solicitudes de permisos pendientes de aprobar (filtra por tipo_solicitud: "P")
  Future<int> obtenerConteoPendientesPermisos() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/pendientes-aprobar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Si es un array, filtrar por tipo_solicitud: "P" y retornar su longitud
        if (decoded is List) {
          final permisosPendientes = decoded.where((item) {
            final tipoSolicitud =
                item['tipo_solicitud'] ?? item['tipoSolicitud'];
            return tipoSolicitud == 'P';
          }).toList();
          return permisosPendientes.length;
        }
        // Si es un objeto con paginación, filtrar items
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('items') && decoded['items'] is List) {
            final items = decoded['items'] as List;
            final permisosPendientes = items.where((item) {
              final tipoSolicitud =
                  item['tipo_solicitud'] ?? item['tipoSolicitud'];
              return tipoSolicitud == 'P';
            }).toList();
            return permisosPendientes.length;
          }
        }
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error al obtener conteo de pendientes de permisos: $e');
      return 0;
    }
  }

  /// Obtener el conteo de solicitudes de vacaciones pendientes de aprobar (filtra por tipo_solicitud: "V")
  Future<int> obtenerConteoPendientesVacaciones() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/pendientes-aprobar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Si es un array, filtrar por tipo_solicitud: "V" y retornar su longitud
        if (decoded is List) {
          final vacacionesPendientes = decoded.where((item) {
            final tipoSolicitud =
                item['tipo_solicitud'] ?? item['tipoSolicitud'];
            return tipoSolicitud == 'V';
          }).toList();
          return vacacionesPendientes.length;
        }
        // Si es un objeto con paginación, filtrar items
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('items') && decoded['items'] is List) {
            final items = decoded['items'] as List;
            final vacacionesPendientes = items.where((item) {
              final tipoSolicitud =
                  item['tipo_solicitud'] ?? item['tipoSolicitud'];
              return tipoSolicitud == 'V';
            }).toList();
            return vacacionesPendientes.length;
          }
        }
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error al obtener conteo de pendientes de vacaciones: $e');
      return 0;
    }
  }

  /// Obtener solicitudes pendientes de aprobar
  /// El endpoint devuelve un array con información de aprobación y solicitud combinada
  Future<List<SolicitudModel>> pendientesAprobar() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/pendientes-aprobar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // La respuesta es un array directamente
        if (decoded is List) {
          // Mapear cada elemento del array a SolicitudModel
          // El endpoint devuelve objetos con aprobación + solicitud; incluye nombre_trabajador
          return decoded.map((item) {
            final map = item is Map ? item : <String, dynamic>{};
            final nombreTrab = map['nombre_trabajador'] ?? map['nombreTrabajador'];
            return SolicitudModel(
              idSolicitud: map['id_solicitud'] ?? map['idSolicitud'],
              tipoSolicitud:
                  map['tipo_solicitud'] ?? map['tipoSolicitud'] ?? 'V',
              codigoPermiso: map['codigo_permiso'] ?? map['codigoPermiso'],
              codigoTrabajador:
                  map['codigo_trabajador'] ?? map['codigoTrabajador'] ?? '',
              fechaInicio: map['fecha_inicio'] != null
                  ? DateTime.parse(map['fecha_inicio'].toString())
                  : DateTime.now(),
              fechaFin: map['fecha_fin'] != null
                  ? DateTime.parse(map['fecha_fin'].toString())
                  : DateTime.now(),
              diasSolicitados: map['dias_solicitados'] != null
                  ? double.tryParse(map['dias_solicitados'].toString()) ?? 0.0
                  : 0.0,
              observacion: map['observacion'],
              motivo: map['motivo'],
              estado:
                  'P', // Las solicitudes pendientes siempre están en estado 'P'
              nombreTrabajador: nombreTrab != null ? nombreTrab.toString().trim() : null,
              nombrePermiso: map['nombre_permiso'] ?? map['nombrePermiso'],
              aprobaciones: [
                AprobacionModel(
                  idAprobacion: map['id_aprobacion'] ?? map['idAprobacion'],
                  idSolicitud: map['id_solicitud'] ?? map['idSolicitud'] ?? 0,
                  nivel: map['nivel'] ?? 0,
                  codigoTrabajadorAprueba:
                      map['codigo_trabajador_aprueba'] ??
                      map['codigoTrabajadorAprueba'] ??
                      '',
                  estado: map['estado'] ?? 'P',
                  observacion: map['observacion'],
                  fecha: map['fecha'] != null
                      ? DateTime.parse(map['fecha'].toString())
                      : null,
                  usuario: map['usuario'],
                ),
              ],
            );
          }).toList();
        } else if (decoded is Map<String, dynamic>) {
          // Si es un objeto con paginación
          if (decoded.containsKey('items') && decoded['items'] is List) {
            final items = decoded['items'] as List;
            return items.map((item) {
              return SolicitudModel(
                idSolicitud: item['id_solicitud'] ?? item['idSolicitud'],
                tipoSolicitud:
                    item['tipo_solicitud'] ?? item['tipoSolicitud'] ?? 'V',
                codigoPermiso: item['codigo_permiso'] ?? item['codigoPermiso'],
                codigoTrabajador:
                    item['codigo_trabajador'] ?? item['codigoTrabajador'] ?? '',
                fechaInicio: item['fecha_inicio'] != null
                    ? DateTime.parse(item['fecha_inicio'])
                    : DateTime.now(),
                fechaFin: item['fecha_fin'] != null
                    ? DateTime.parse(item['fecha_fin'])
                    : DateTime.now(),
                diasSolicitados: item['dias_solicitados'] != null
                    ? double.tryParse(item['dias_solicitados'].toString()) ??
                          0.0
                    : 0.0,
                observacion: item['observacion'],
                motivo: item['motivo'],
                estado: 'P',
                nombreTrabajador: item['nombre_trabajador'] ?? item['nombreTrabajador'],
                nombrePermiso: item['nombre_permiso'] ?? item['nombrePermiso'],
                aprobaciones: [
                  AprobacionModel(
                    idAprobacion: item['id_aprobacion'] ?? item['idAprobacion'],
                    idSolicitud:
                        item['id_solicitud'] ?? item['idSolicitud'] ?? 0,
                    nivel: item['nivel'] ?? 0,
                    codigoTrabajadorAprueba:
                        item['codigo_trabajador_aprueba'] ??
                        item['codigoTrabajadorAprueba'] ??
                        '',
                    estado: item['estado'] ?? 'P',
                    observacion: item['observacion'],
                    fecha: item['fecha'] != null
                        ? DateTime.parse(item['fecha'])
                        : null,
                    usuario: item['usuario'],
                  ),
                ],
              );
            }).toList();
          } else {
            return [];
          }
        } else {
          return [];
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'Error al obtener solicitudes pendientes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en pendientesAprobar: $e');
      if (e.toString().contains('is not a subtype')) {
        throw Exception(
          'Error: El servidor devolvió un formato de datos inesperado',
        );
      }
      throw Exception('Error de conexión: $e');
    }
  }

  /// Aprobar una solicitud
  Future<SolicitudModel> aprobarSolicitud({
    required int idSolicitud,
    String? observacion,
    String? ipDispositivo,
  }) async {
    try {
      final response = await _authService.authenticatedPost(
        Uri.parse('$baseUrl/vacaciones/aprobar/$idSolicitud'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'observacion': observacion ?? '',
          'ip_dispositivo': ipDispositivo ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return SolicitudModel.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al aprobar solicitud');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  /// Rechazar una solicitud
  Future<SolicitudModel> rechazarSolicitud({
    required int idSolicitud,
    required String observacion,
    String? ipDispositivo,
  }) async {
    try {
      final response = await _authService.authenticatedPost(
        Uri.parse('$baseUrl/vacaciones/rechazar/$idSolicitud'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'observacion': observacion,
          'ip_dispositivo': ipDispositivo ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return SolicitudModel.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al rechazar solicitud');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  /// Obtener aprobaciones de una solicitud
  Future<List<AprobacionModel>> obtenerAprobaciones(int idSolicitud) async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/aprobaciones/$idSolicitud'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      }
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Verificar si la respuesta es un array o un objeto
        if (decoded is List) {
          return decoded.map((json) => AprobacionModel.fromJson(json)).toList();
        } else if (decoded is Map<String, dynamic>) {
          // Si es un objeto, verificar si tiene una clave que indique que es un array de aprobaciones
          if (decoded.containsKey('aprobaciones') &&
              decoded['aprobaciones'] is List) {
            final List<dynamic> jsonList = decoded['aprobaciones'];
            return jsonList
                .map((json) => AprobacionModel.fromJson(json))
                .toList();
          } else if (decoded.containsKey('data') && decoded['data'] is List) {
            final List<dynamic> jsonList = decoded['data'];
            return jsonList
                .map((json) => AprobacionModel.fromJson(json))
                .toList();
          } else {
            // Si no hay aprobaciones o es un objeto vacío, retornar lista vacía
            return [];
          }
        } else {
          // Tipo inesperado, retornar lista vacía
          return [];
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'Error al obtener aprobaciones: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Si el error es de tipo, intentar manejar mejor el mensaje
      if (e.toString().contains('is not a subtype')) {
        throw Exception(
          'Error: El servidor devolvió un formato de datos inesperado',
        );
      }
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener saldo de vacaciones
  Future<SaldoVacacionesModel> obtenerMiSaldo() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/mi-saldo'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return SaldoVacacionesModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener saldo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  /// Obtener cat?logos (tipos de permiso, etc.)
  Future<Map<String, dynamic>> obtenerCatalogos() async {
    try {
      final response = await _authService.authenticatedGet(
        Uri.parse('$baseUrl/vacaciones/catalogos'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener cat?logos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  // ============================================
  // PERMISOS
  // ============================================

  /// Solicitar permiso
  Future<SolicitudModel> solicitarPermiso({
    required String codigoTrabajador,
    required String codigoPermiso,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double diasSolicitados,
    String? observacion,
    String? motivo,
    String?
    usuario, // Nombre de usuario (opcional, se obtiene del token si no se proporciona)
  }) async {
    try {
      // Si no se proporciona el usuario, intentar obtenerlo del token
      String? usuarioRegistro = usuario;
      if (usuarioRegistro == null || usuarioRegistro.isEmpty) {
        usuarioRegistro = await _getUsuarioFromToken();
      }

      final body = <String, dynamic>{
        'tipo_solicitud': 'P',
        'codigo_permiso': codigoPermiso,
        'codigo_trabajador': codigoTrabajador,
        'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
        'fecha_fin': fechaFin.toIso8601String().split('T')[0],
        'dias_solicitados': diasSolicitados,
        if (observacion != null && observacion.isNotEmpty)
          'observacion': observacion,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        if (usuarioRegistro != null && usuarioRegistro.isNotEmpty)
          'usuario_registro': usuarioRegistro,
      };

      final response = await _authService.authenticatedPost(
        Uri.parse(
          '$baseUrl/vacaciones/solicitar',
        ), // Mismo endpoint, diferente tipo
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SolicitudModel.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al solicitar permiso');
      }
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  /// Obtener mis solicitudes de permisos
  Future<List<SolicitudModel>> misSolicitudesPermisos() async {
    try {
      // Filtrar solo permisos de mis solicitudes
      final todas = await misSolicitudesVacaciones();
      return todas.where((s) => s.tipoSolicitud == 'P').toList();
    } catch (e) {
      throw Exception('Error de conexi?n: $e');
    }
  }

  // ============================================
  // TRABAJADORES
  // ============================================

  /// Obtener lista de trabajadores (paginada)
  Future<TrabajadoresResponse> obtenerTrabajadores({
    int page = 1,
    int limit = 20,
    String? search, // Texto de búsqueda general
    String? codigo, // Buscar por código de trabajador
    String? nombre, // Buscar por nombre completo
    String? codigoArea, // Filtrar por código de área
    String? codigoSeccion, // Filtrar por código de sección
    String? codigoCargo, // Filtrar por código de cargo
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Agregar parámetros de búsqueda si se proporcionan
      if (codigo != null && codigo.trim().isNotEmpty) {
        queryParams['codigo'] = codigo.trim();
      }
      if (nombre != null && nombre.trim().isNotEmpty) {
        queryParams['nombre'] = nombre.trim();
      }
      // Si se proporciona search pero no nombre, usar search como nombre
      if (search != null && search.trim().isNotEmpty && nombre == null) {
        queryParams['nombre'] = search.trim();
      }
      if (codigoArea != null && codigoArea.trim().isNotEmpty) {
        queryParams['codigo_area'] = codigoArea.trim();
      }
      if (codigoSeccion != null && codigoSeccion.trim().isNotEmpty) {
        queryParams['codigo_seccion'] = codigoSeccion.trim();
      }
      if (codigoCargo != null && codigoCargo.trim().isNotEmpty) {
        queryParams['codigo_cargo'] = codigoCargo.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/vacaciones/trabajadores',
      ).replace(queryParameters: queryParams);

      final response = await _authService.authenticatedGet(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return TrabajadoresResponse.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'Error al obtener trabajadores: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener lista de cumpleaños del día (paginada)
  Future<TrabajadoresResponse> obtenerCumpleanosHoy({
    int page = 1,
    int limit = 20,
    String? search, // Texto de búsqueda general
    String? codigo, // Buscar por código de trabajador
    String? nombre, // Buscar por nombre completo
    String? codigoArea, // Filtrar por código de área
    String? codigoSeccion, // Filtrar por código de sección
    String? codigoCargo, // Filtrar por código de cargo
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Agregar parámetros de búsqueda si se proporcionan
      if (codigo != null && codigo.trim().isNotEmpty) {
        queryParams['codigo'] = codigo.trim();
      }
      if (nombre != null && nombre.trim().isNotEmpty) {
        queryParams['nombre'] = nombre.trim();
      }
      // Si se proporciona search pero no nombre, usar search como nombre
      if (search != null && search.trim().isNotEmpty && nombre == null) {
        queryParams['nombre'] = search.trim();
      }
      if (codigoArea != null && codigoArea.trim().isNotEmpty) {
        queryParams['codigo_area'] = codigoArea.trim();
      }
      if (codigoSeccion != null && codigoSeccion.trim().isNotEmpty) {
        queryParams['codigo_seccion'] = codigoSeccion.trim();
      }
      if (codigoCargo != null && codigoCargo.trim().isNotEmpty) {
        queryParams['codigo_cargo'] = codigoCargo.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/vacaciones/cumpleanos-hoy',
      ).replace(queryParameters: queryParams);

      final response = await _authService.authenticatedGet(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return TrabajadoresResponse.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ??
              'Error al obtener cumpleaños: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Registrar token FCM del dispositivo en el backend
  Future<void> registrarTokenDispositivo({
    required String tokenFcm,
    required String codigoTrabajador,
    required String plataforma,
    String? modeloDispositivo,
    String? versionApp,
    String? versionSo,
  }) async {
    try {
      final body = <String, dynamic>{
        'token_fcm': tokenFcm,
        'codigo_trabajador': codigoTrabajador,
        'plataforma': plataforma, // 'A' para Android, 'I' para iOS
        if (modeloDispositivo != null) 'modelo_dispositivo': modeloDispositivo,
        if (versionApp != null) 'version_app': versionApp,
        if (versionSo != null) 'version_so': versionSo,
      };

      final response = await _authService.authenticatedPost(
        Uri.parse('$baseUrl/notificaciones/registrar-token'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Token FCM registrado exitosamente para $codigoTrabajador');
      } else {
        final errorBody = json.decode(response.body);
        print('Error al registrar token: ${errorBody['detail'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Error al registrar token FCM: $e');
      // No lanzar excepción para que no afecte el flujo normal de la app
    }
  }
}
