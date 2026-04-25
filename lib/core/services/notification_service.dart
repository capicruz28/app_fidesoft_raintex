// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../../core/navigation/app_navigator.dart';
import 'dart:convert';

// Handler top-level para notificaciones en segundo plano (requerido por Firebase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Notificación recibida en segundo plano: ${message.notification?.title}');
  // Aquí puedes procesar la notificación aunque la app esté cerrada
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Handler para cuando la app está en primer plano
  static Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
    print('Notificación recibida en primer plano: ${message.notification?.title}');
    print('Datos de la notificación: ${message.data}');
    
    // Construir payload con los datos importantes
    final payload = jsonEncode({
      'tipo_solicitud': message.data['tipo_solicitud'] ?? message.data['tipo'] ?? 'V',
      'id_solicitud': message.data['id_solicitud'] ?? '',
    });
    
    // Mostrar notificación local
    await _showLocalNotification(
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      payload: payload,
    );
  }


  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fidesoft_channel',
      'Fidesoft Notificaciones',
      description: 'Notificaciones de la aplicación',
      importance: Importance.high,
    );

    // Configurar notificaciones locales: Android + iOS
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Los permisos se piden con Firebase
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear el canal de notificaciones en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Solicitar permisos de notificaciones
    await _requestPermissions();

    // Configurar handlers de Firebase Messaging
    FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Obtener y registrar el token FCM
    await _registerFCMToken();
  }

  // Solicitar permisos de notificaciones
  static Future<void> _requestPermissions() async {
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Permisos de notificaciones: ${settings.authorizationStatus}');
  }

  // Obtener información del dispositivo
  static Future<Map<String, String?>> _getDeviceInfo() async {
    final Map<String, String?> deviceInfo = {};
    
    try {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      
      deviceInfo['version_app'] = packageInfo.version;
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo['modelo_dispositivo'] = '${androidInfo.brand} ${androidInfo.model}';
        deviceInfo['version_so'] = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo['modelo_dispositivo'] = '${iosInfo.name} ${iosInfo.model}';
        deviceInfo['version_so'] = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      print('Error al obtener información del dispositivo: $e');
    }
    
    return deviceInfo;
  }

  // Obtener y registrar el token FCM en el backend
  static Future<void> _registerFCMToken({String? codigoTrabajador}) async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        print('Token FCM obtenido: $token');
        
        // Guardar token localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      print('Error al obtener token FCM: $e');
    }

    // Escuchar cambios en el token
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('Token FCM actualizado: $newToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });
  }

  // Mostrar notificación local (Android e iOS)
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fidesoft_channel',
      'Fidesoft Notificaciones',
      channelDescription: 'Notificaciones de la aplicación',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'fidesoft_solicitudes',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Manejar cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notificación tocada: ${response.payload}');
    // La navegación se manejará desde el contexto de la app
    _navigateFromNotification(response.payload);
  }

  // Manejar cuando se abre la app desde una notificación
  static void _onNotificationOpenedApp(RemoteMessage message) {
    print('App abierta desde notificación: ${message.notification?.title}');
    print('Datos de la notificación: ${message.data}');

    // Pequeño delay para asegurar que la app esté lista
    Future.delayed(const Duration(milliseconds: 500), () {
      // Módulos de Vacaciones/Permisos fueron retirados; por seguridad llevamos al dashboard.
      navigatorKey.currentState?.pushNamed('/dashboard');
    });
  }

  // Navegar a la pantalla correspondiente según el tipo de notificación
  static void _navigateFromNotification(String? payload) {
    // Módulos de Vacaciones/Permisos fueron retirados; por seguridad llevamos al dashboard.
    navigatorKey.currentState?.pushNamed('/dashboard');
  }

  // Registrar token después del login
  static Future<void> registerTokenAfterLogin(String codigoTrabajador) async {
    // Guardar código de trabajador para uso futuro
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codigo_trabajador', codigoTrabajador);
    
    await _registerFCMToken(codigoTrabajador: codigoTrabajador);
  }

  // Obtener el token FCM actual
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
