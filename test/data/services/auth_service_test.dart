import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_fidesoft/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStore = <String, String>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    secureStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return secureStore[call.arguments['key']];
        case 'write':
          secureStore[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'delete':
          secureStore.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('login exitoso con headers mobile y form-urlencoded', () async {
    late Uri capturedUri;
    late Map<String, String> capturedHeaders;
    late String capturedBody;

    final client = MockClient((request) async {
      capturedUri = request.url;
      capturedHeaders = request.headers;
      capturedBody = request.body;

      return http.Response(
        jsonEncode({
          'access_token': 'access_123456',
          'refresh_token': 'refresh_123456',
          'token_type': 'bearer',
          'user_data': {
            'usuario_id': 1,
            'nombre_usuario': 'usuario_demo',
            'nombre': 'Demo',
            'apellido': 'User',
          },
        }),
        200,
      );
    });

    final service = AuthService(httpClient: client, logger: (_) {});

    await service.login(username: 'usuario_demo', password: 'clave_demo');

    expect(capturedUri.path, '/api/v1/auth/login/');
    expect(capturedHeaders['X-Client-Type'], 'mobile');
    expect(
      capturedHeaders['Content-Type'],
      startsWith('application/x-www-form-urlencoded'),
    );
    expect(capturedBody, contains('username=usuario_demo'));
    expect(capturedBody, contains('password=clave_demo'));
    expect(await service.getAccessToken(), 'access_123456');
    expect(await service.getRefreshToken(), 'refresh_123456');
  });

  test('refresh exitoso actualiza tokens', () async {
    secureStore['refresh_token'] = 'refresh_old';
    secureStore['access_token'] = 'access_old';

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh/') {
        return http.Response(
          jsonEncode({
            'access_token': 'access_new_1234',
            'refresh_token': 'refresh_new_1234',
            'token_type': 'bearer',
            'user_data': null,
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final service = AuthService(httpClient: client, logger: (_) {});
    final refreshed = await service.refreshToken();

    expect(refreshed, isTrue);
    expect(await service.getAccessToken(), 'access_new_1234');
    expect(await service.getRefreshToken(), 'refresh_new_1234');
  });

  test('401 en request protegida ejecuta refresh y retry', () async {
    secureStore['access_token'] = 'access_old';
    secureStore['refresh_token'] = 'refresh_old';

    var protectedCalls = 0;
    var refreshCalls = 0;

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/protected/test') {
        protectedCalls += 1;
        final auth = request.headers['Authorization'];
        if (protectedCalls == 1 && auth == 'Bearer access_old') {
          return http.Response(
            jsonEncode({'detail': 'No se pudieron validar las credenciales'}),
            401,
          );
        }
        if (auth == 'Bearer access_new') {
          return http.Response(jsonEncode({'ok': true}), 200);
        }
      }

      if (request.url.path == '/api/v1/auth/refresh/') {
        refreshCalls += 1;
        return http.Response(
          jsonEncode({
            'access_token': 'access_new',
            'refresh_token': 'refresh_new',
            'token_type': 'bearer',
            'user_data': null,
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final service = AuthService(httpClient: client, logger: (_) {});
    final response = await service.authenticatedGet(
      Uri.parse('http://20.157.65.103:8095/api/v1/protected/test'),
    );

    expect(response.statusCode, 200);
    expect(protectedCalls, 2);
    expect(refreshCalls, 1);
  });

  test('refresh fallido limpia sesión y lanza SESSION_EXPIRED', () async {
    secureStore['access_token'] = 'access_old';
    secureStore['refresh_token'] = 'refresh_old';

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/protected/test') {
        return http.Response('unauthorized', 401);
      }
      if (request.url.path == '/api/v1/auth/refresh/') {
        return http.Response('unauthorized', 401);
      }
      return http.Response('not found', 404);
    });

    final service = AuthService(httpClient: client, logger: (_) {});

    await expectLater(
      () async => service.authenticatedGet(
        Uri.parse('http://20.157.65.103:8095/api/v1/protected/test'),
      ),
      throwsA(isA<Exception>()),
    );
    expect(await service.getAccessToken(), isNull);
    expect(await service.getRefreshToken(), isNull);
  });
}
