// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- Importación para inicializar locale
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/theme_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/services/notification_service.dart'; 
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/perfil_usuario_screen.dart';
import 'features/auth/presentation/cambiar_contrasena_screen.dart';
import 'features/auth/presentation/post_login_gate_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/vacaciones/presentation/vacaciones_screen.dart';
import 'features/vacaciones/presentation/solicitar_vacaciones_screen.dart';
import 'features/vacaciones/presentation/mis_solicitudes_screen.dart';
import 'features/vacaciones/presentation/pendientes_aprobar_screen.dart';
import 'features/permisos/presentation/permisos_screen.dart';
import 'features/permisos/presentation/solicitar_permiso_screen.dart';
import 'features/documentos/presentation/documentos_screen.dart';
import 'features/documentos/presentation/documentos_empresa_screen.dart';
import 'features/documentos/presentation/boletas_screen.dart';
import 'features/documentos/presentation/certificados_screen.dart';
import 'features/documentos/presentation/otros_documentos_screen.dart';
import 'features/documentos/presentation/reglamentos_screen.dart';
import 'features/documentos/presentation/avisos_screen.dart';
import 'features/trabajadores/presentation/trabajadores_screen.dart';
import 'features/trabajadores/presentation/lista_trabajadores_screen.dart';
import 'features/trabajadores/presentation/lista_cumpleanos_screen.dart';
import 'features/trabajadores/presentation/mis_datos_screen.dart';
import 'core/navigation/app_navigator.dart';

void main() async { // <-- main ahora es ASÍNCRONA
  // Aseguramos que Flutter esté inicializado (buenas prácticas)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Inicializar servicio de notificaciones
  await NotificationService.initialize();
  
  // Inicializa los datos de localización para el idioma español ('es')
  // Esto resuelve el error LocaleDataException
  await initializeDateFormatting('es', null); 

  runApp(
    MultiProvider( 
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()), 
      ],
      child: const FidesoftApp(),
    ),
  );
}

class FidesoftApp extends StatelessWidget {
  const FidesoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Definición de temas
    const primaryColor = Color(0xFF0D47A1); 
    const accentColor = Color(0xFF1E88E5); 

    final lightTheme = ThemeData(
      primaryColor: primaryColor,
      hintColor: accentColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accentColor, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      hintColor: accentColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      navigatorKey: navigatorKey, // Para navegación desde notificaciones
      title: 'FIDESOFT HR',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      
      // Configuración de localización
      locale: const Locale('es', 'ES'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (fallback)
      ],
      
      // Rutas de Navegación
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/post-login': (context) => const PostLoginGateScreen(),
        '/perfil-usuario': (context) => const PerfilUsuarioScreen(),
        '/cambiar-contrasena': (context) => const CambiarContrasenaScreen(),
        
        // RUTAS DE MÓDULOS PRINCIPALES (NIVEL 1)
        '/vacaciones': (context) => const VacacionesScreen(),
        '/permisos': (context) => const PermisosScreen(), 
        '/documentos': (context) => const DocumentosScreen(), 
        '/documentos-empresa': (context) => const DocumentosEmpresaScreen(),
        '/mis-datos': (context) => const MisDatosScreen(),
        '/trabajadores': (context) => const TrabajadoresScreen(),
        '/evaluaciones': (context) => const Placeholder(child: Center(child: Text('Módulo Evaluaciones'))),

        // RUTAS DE SUB-MÓDULOS (NIVEL 2) - VACACIONES
        '/vacaciones/programacion': (context) => const SolicitarVacacionesScreen(),
        '/vacaciones/reporte': (context) => const MisSolicitudesScreen(tipo: 'V'),
        '/vacaciones/mis-solicitudes': (context) => const MisSolicitudesScreen(tipo: 'V'),
        '/vacaciones/pendientes-aprobar': (context) => const PendientesAprobarScreen(tipoFiltro: 'V'),

        // PERMISOS (NIVEL 2) 
        '/permisos/solicitar': (context) => const SolicitarPermisoScreen(),
        '/permisos/reporte': (context) => const MisSolicitudesScreen(tipo: 'P'),
        '/permisos/mis-solicitudes': (context) => const MisSolicitudesScreen(tipo: 'P'),
        '/permisos/pendientes-aprobar': (context) => const PendientesAprobarScreen(tipoFiltro: 'P'),

        // MIS DOCUMENTOS (NIVEL 2) 
        '/documentos/boletas': (context) => const PayslipsScreen(),
        '/documentos/certificados': (context) => const CertificadosScreen(),
        '/documentos/otros': (context) => const OtrosDocumentosScreen(),

        // DOCUMENTOS EMPRESA (NIVEL 2)
        '/documentos-empresa/reglamentos': (context) => const ReglamentosScreen(),
        '/documentos-empresa/avisos': (context) => const AvisosScreen(),

        // TRABAJADORES (NIVEL 2)
        '/trabajadores/lista': (context) => const ListaTrabajadoresScreen(),
        '/trabajadores/cumpleanos': (context) => const ListaCumpleanosScreen(),
      },
    );
  }
}