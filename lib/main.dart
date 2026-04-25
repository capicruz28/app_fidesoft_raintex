// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- Importación para inicializar locale
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/theme_provider.dart';
import 'core/providers/user_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/perfil_usuario_screen.dart';
import 'features/auth/presentation/cambiar_contrasena_screen.dart';
import 'features/auth/presentation/post_login_gate_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/documentos/presentation/documentos_screen.dart';
import 'features/documentos/presentation/ordenes_compra_aprobacion_screen.dart';
import 'features/documentos/presentation/ordenes_compra_consulta_screen.dart';
import 'features/trabajadores/presentation/mis_datos_screen.dart';
import 'core/navigation/app_navigator.dart';

void main() async { // <-- main ahora es ASÍNCRONA
  // Aseguramos que Flutter esté inicializado (buenas prácticas)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
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
        '/documentos': (context) => const DocumentosScreen(), 
        '/mis-datos': (context) => const MisDatosScreen(),
        '/evaluaciones': (context) => const Placeholder(child: Center(child: Text('Módulo Evaluaciones'))),

        // ORDENES DE COMPRA (NIVEL 2)
        '/documentos/aprobacion': (context) => const OrdenesCompraAprobacionScreen(),
        '/documentos/consulta': (context) => const OrdenesCompraConsultaScreen(),
      },
    );
  }
}