// lib/features/auth/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/notification_service.dart';
import 'login_screen.dart';
import 'post_login_gate_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      final authService = AuthService();
      final userModel = await authService.autoLogin();

      if (!mounted) return;

      if (userModel != null) {
        // Auto-login exitoso
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Obtener RUC guardado
        final savedCredentials = await authService.getSavedCredentials();
        final ruc = savedCredentials?['ruc'] ?? '';
        
        // Obtener correo guardado
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email');
        
        // Establecer usuario en el provider
        userProvider.setUser(userModel, ruc, email: userEmail);

        // Registrar token FCM
        final codigoTrabajador = userModel.strDato1;
        if (codigoTrabajador.isNotEmpty) {
          await NotificationService.registerTokenAfterLogin(codigoTrabajador);
        }

        // Gate post-login: muestra aviso pendiente antes del dashboard (si aplica)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PostLoginGateScreen()),
        );
      } else {
        // No hay token válido, ir a login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // En caso de error, ir a login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FIDESOFT',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Cargando...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
