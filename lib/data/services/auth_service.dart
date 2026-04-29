// lib/data/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';
import '../models/user_profile_model.dart';

class AuthService {
  // URL del servidor de producción
  // Nota: 10.0.2.2 es la IP especial del emulador Android para acceder al localhost del host
  // Para pruebas locales, usar: http://10.0.2.2:8000/api/v1
  final String baseUrlNuevo = 'http://20.157.65.103:8095/api/v1';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenTypeKey = 'token_type';
  static const _clientTypeHeader = 'X-Client-Type';
  static const _mobileClientType = 'mobile';
  static Completer<bool>? _refreshCompleter;
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _prefsFactory;
  final void Function(String) _logger;
  final VoidCallback? _onSessionExpired;

  AuthService({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? prefsFactory,
    void Function(String)? logger,
    VoidCallback? onSessionExpired,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefsFactory = prefsFactory ?? SharedPreferences.getInstance,
        _logger = logger ?? debugPrint,
        _onSessionExpired = onSessionExpired;

  void _debug(String message) {
    _logger('[AuthService] $message');
  }

  String _tokenPreview(String? token) {
    if (token == null || token.isEmpty) return 'empty';
    if (token.length <= 8) return 'len:${token.length}';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  Future<void> _saveTokens(AuthTokenModel tokenModel) async {
    final prefs = await _prefsFactory();
    await _secureStorage.write(key: _accessTokenKey, value: tokenModel.accessToken);
    await prefs.setString(_tokenTypeKey, tokenModel.tokenType);
    if (tokenModel.refreshToken.isNotEmpty) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: tokenModel.refreshToken,
      );
    }
    _debug(
      'Tokens actualizados (access:${_tokenPreview(tokenModel.accessToken)}, refresh:${_tokenPreview(tokenModel.refreshToken)})',
    );
  }

  Future<void> clearSessionTokens() async {
    final prefs = await _prefsFactory();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove('user_roles');
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    _debug('Sesión local limpiada');
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<bool> _refreshSession() async {
    if (_refreshCompleter != null) {
      _debug('Refresh ya en curso, esperando resultado compartido');
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _debug('Refresh omitido: no existe refresh_token');
        await clearSessionTokens();
        completer.complete(false);
        return false;
      }

      _debug('Intentando refresh de sesión');
      final response = await _httpClient.post(
        Uri.parse('$baseUrlNuevo/auth/refresh/'),
        headers: <String, String>{
          _clientTypeHeader: _mobileClientType,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final tokenModel = authTokenModelFromJson(response.body);
        await _saveTokens(tokenModel);
        _debug('Refresh exitoso');
        completer.complete(true);
        return true;
      }

      _debug('Refresh falló con código ${response.statusCode}');
      await clearSessionTokens();
      completer.complete(false);
      return false;
    } catch (e) {
      _debug('Refresh falló por excepción: $e');
      await clearSessionTokens();
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<http.Response> authenticatedGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    return _sendWithAutoRefresh((token) {
      final requestHeaders = <String, String>{
        ...?headers,
        'Authorization': 'Bearer $token',
      };
      return _httpClient.get(uri, headers: requestHeaders);
    });
  }

  Future<http.Response> authenticatedPost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _sendWithAutoRefresh((token) {
      final requestHeaders = <String, String>{
        ...?headers,
        'Authorization': 'Bearer $token',
      };
      return _httpClient.post(
        uri,
        headers: requestHeaders,
        body: body,
        encoding: encoding,
      );
    });
  }

  Future<http.Response> _sendWithAutoRefresh(
    Future<http.Response> Function(String accessToken) sender,
  ) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    final firstResponse = await sender(token);
    if (firstResponse.statusCode != 401) {
      return firstResponse;
    }

    _debug('Respuesta 401 detectada, iniciando flujo de refresh');
    final refreshed = await _refreshSession();
    if (!refreshed) {
      await _notifySessionExpired();
      throw Exception('SESSION_EXPIRED');
    }

    final newToken = await getAccessToken();
    if (newToken == null || newToken.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }
    return sender(newToken);
  }

  Future<void> _notifySessionExpired() async {
    await clearSessionTokens();
    _onSessionExpired?.call();
  }

  Future<bool> refreshToken() async {
    return _refreshSession();
  }

  /// Login - Usa el nuevo endpoint OAuth2
  Future<UserModel> login({
    String? ruc,
    String? cusuar,
    String? dclave,
    String? username,
    String? password,
  }) async {
    try {
      final resolvedUsername = username ?? cusuar;
      final resolvedPassword = password ?? dclave;
      if (resolvedUsername == null ||
          resolvedUsername.isEmpty ||
          resolvedPassword == null ||
          resolvedPassword.isEmpty) {
        throw Exception('Credenciales incompletas');
      }

      // El endpoint usa OAuth2PasswordRequestForm con form-urlencoded
      _debug('Iniciando login móvil para usuario ${resolvedUsername.trim()}');
      final response = await _httpClient.post(
        Uri.parse('$baseUrlNuevo/auth/login/'),
        headers: <String, String>{
          _clientTypeHeader: _mobileClientType,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'username': resolvedUsername, // Puede ser nombre de usuario o email
          'password': resolvedPassword,
        },
      );

      if (response.statusCode == 200) {
        final tokenModel = authTokenModelFromJson(response.body);
        await _saveTokens(tokenModel);
        final prefs = await SharedPreferences.getInstance();
        
        // Guardar los roles del usuario si están disponibles
        if (tokenModel.userData?.roles != null) {
          await prefs.setStringList('user_roles', tokenModel.userData!.roles!);
        }
        // Guardar correo del usuario si está disponible
        if (tokenModel.userData?.correo != null && tokenModel.userData!.correo!.isNotEmpty) {
          await prefs.setString('user_email', tokenModel.userData!.correo!);
        }
        
        // Convertir la respuesta del nuevo endpoint al formato UserModel
        // Si hay datos del usuario en la respuesta, usarlos
        if (tokenModel.userData != null) {
          return UserModel(
            strMensaje: '', // Sin mensaje = éxito
            strDato1: tokenModel.userData!.codigoTrabajadorExterno ?? tokenModel.userData!.nombreUsuario ?? resolvedUsername,
            strDato2: '${tokenModel.userData!.nombre ?? ''} ${tokenModel.userData!.apellido ?? ''}'.trim(),
            strDato3: tokenModel.userData!.usuarioId?.toString() ?? '0',
            intDato4: tokenModel.userData!.usuarioId ?? 0,
          );
        } else {
          // Si no vienen datos del usuario, hacer una llamada a /auth/me/ para obtenerlos
          return await _obtenerDatosUsuario(tokenModel.accessToken);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al autenticar. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener datos del usuario autenticado usando el token
  Future<UserModel> _obtenerDatosUsuario(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrlNuevo/auth/me/'),
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = UserData.fromJson(json.decode(response.body));
        
        // Guardar los roles del usuario si están disponibles
        final prefs = await SharedPreferences.getInstance();
        if (userData.roles != null) {
          await prefs.setStringList('user_roles', userData.roles!);
        }
        // Guardar correo del usuario
        if (userData.correo != null && userData.correo!.isNotEmpty) {
          await prefs.setString('user_email', userData.correo!);
        }
        
        return UserModel(
          strMensaje: '',
          strDato1: userData.codigoTrabajadorExterno ?? userData.nombreUsuario ?? '',
          strDato2: '${userData.nombre ?? ''} ${userData.apellido ?? ''}'.trim(),
          strDato3: userData.usuarioId?.toString() ?? '0',
          intDato4: userData.usuarioId ?? 0,
        );
      } else {
        throw Exception('Error al obtener datos del usuario');
      }
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  /// Obtener el token guardado
  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) return token;

    // Compatibilidad: migra token antiguo en SharedPreferences si existe
    final prefs = await _prefsFactory();
    final legacyToken = prefs.getString(_accessTokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _accessTokenKey, value: legacyToken);
      await prefs.remove(_accessTokenKey);
      _debug('Migrado access_token legado a secure storage');
    }
    return legacyToken;
  }

  /// Guardar credenciales para "Recordarme"
  Future<void> saveCredentials({
    required String ruc,
    required String usuario,
    required String clave,
  }) async {
    final prefs = await _prefsFactory();
    await prefs.setString('saved_ruc', ruc);
    await prefs.setString('saved_usuario', usuario);
    await prefs.setString('saved_clave', clave);
    await prefs.setBool('remember_me', true);
  }

  /// Obtener credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await _prefsFactory();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    if (!rememberMe) return null;
    
    final ruc = prefs.getString('saved_ruc');
    final usuario = prefs.getString('saved_usuario');
    final clave = prefs.getString('saved_clave');
    
    if (ruc != null && usuario != null && clave != null) {
      return {
        'ruc': ruc,
        'usuario': usuario,
        'clave': clave,
      };
    }
    
    return null;
  }

  /// Limpiar credenciales guardadas
  Future<void> clearSavedCredentials() async {
    final prefs = await _prefsFactory();
    await prefs.remove('saved_ruc');
    await prefs.remove('saved_usuario');
    await prefs.remove('saved_clave');
    await prefs.setBool('remember_me', false);
  }

  /// Verificar si hay un token válido y hacer auto-login
  Future<UserModel?> autoLogin() async {
    try {
      final token = await getAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Verificar si el token es válido haciendo una llamada a /auth/me/
      final response = await authenticatedGet(
        Uri.parse('$baseUrlNuevo/auth/me/'),
        headers: <String, String>{'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = UserData.fromJson(json.decode(response.body));
        
        // Guardar correo del usuario si está disponible
        final prefs = await SharedPreferences.getInstance();
        if (userData.correo != null && userData.correo!.isNotEmpty) {
          await prefs.setString('user_email', userData.correo!);
        }
        
        return UserModel(
          strMensaje: '',
          strDato1: userData.codigoTrabajadorExterno ?? userData.nombreUsuario ?? '',
          strDato2: '${userData.nombre ?? ''} ${userData.apellido ?? ''}'.trim(),
          strDato3: userData.usuarioId?.toString() ?? '0',
          intDato4: userData.usuarioId ?? 0,
        );
      } else {
        // Token inválido, limpiar
        await logout();
        return null;
      }
    } catch (e) {
      print('Error en auto-login: $e');
      // Si hay error, limpiar token y credenciales
      await logout();
      return null;
    }
  }

  /// Limpiar el token (logout)
  Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    try {
      final token = await getAccessToken();
      final headers = <String, String>{
        _clientTypeHeader: _mobileClientType,
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      await _httpClient.post(
        Uri.parse('$baseUrlNuevo/auth/logout/'),
        headers: headers,
        body: jsonEncode({
          if (refreshToken != null && refreshToken.isNotEmpty)
            'refresh_token': refreshToken,
        }),
      );
    } catch (_) {}
    await clearSessionTokens();
    // NO limpiar credenciales guardadas aquí, solo se limpian si el usuario desmarca "Recordarme"
  }
  
  /// Verificar si el usuario tiene un rol específico
  static Future<bool> tieneRol(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('user_roles') ?? [];
    return roles.contains(rol);
  }
  
  /// Obtener perfil completo del usuario autenticado
  Future<UserProfileModel> obtenerPerfilUsuario() async {
    try {
      final response = await authenticatedGet(
        Uri.parse('$baseUrlNuevo/auth/me/'),
        headers: <String, String>{'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al obtener perfil del usuario');
      }
    } catch (e) {
      throw Exception('Error al obtener perfil del usuario: $e');
    }
  }

  /// Cambiar contraseña del usuario
  Future<Map<String, dynamic>> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    try {
      final response = await authenticatedPost(
        Uri.parse('$baseUrlNuevo/auth/change-password/'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'contrasena_actual': contrasenaActual,
          'nueva_contrasena': nuevaContrasena,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('SESSION_EXPIRED');
      } else if (response.statusCode == 400) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'La contraseña actual es incorrecta');
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'La nueva contraseña no cumple con los requisitos');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  /// Validar formato de contraseña
  static String? validarContrasena(String contrasena) {
    if (contrasena.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!contrasena.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!contrasena.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una minúscula';
    }
    if (!contrasena.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  /// Verificar si el usuario es aprobador usando el endpoint específico
  static Future<bool> esAprobador() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      
      if (token == null) {
        print('No hay token de autenticación');
        return false;
      }
      
      // Usar el endpoint específico para verificar si es aprobador
      final response = await authService._httpClient.get(
        Uri.parse('${authService.baseUrlNuevo}/vacaciones/verificar-aprobador'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final esAprobador = decoded['es_aprobador'] ?? false;
        print('Usuario es aprobador: $esAprobador');
        return esAprobador as bool;
      } else {
        print('Error al verificar aprobador: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error al verificar aprobador por endpoint: $e');
      return false;
    }
  }
}