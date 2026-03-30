// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/auth_service.dart';
import '../../../core/providers/user_provider.dart'; // Importamos el provider
import '../../../core/services/notification_service.dart'; // Para registrar token FCM

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // RUC fijo por defecto
  final _rucController = TextEditingController(text: '20206228815'); 
  final _usuarioController = TextEditingController();
  final _claveController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedCredentials = await _authService.getSavedCredentials();
      if (savedCredentials != null && mounted) {
        // Si hay credenciales guardadas, usarlas
        setState(() {
          _rucController.text = savedCredentials['ruc'] ?? '20206228815';
          _usuarioController.text = savedCredentials['usuario'] ?? '';
          _claveController.text = savedCredentials['clave'] ?? '';
          _rememberMe = true;
        });
      }
      // Si no hay credenciales guardadas, solo el RUC tiene valor por defecto
    } catch (e) {
      // Error al cargar credenciales guardadas, continuar con valores por defecto
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String ruc = _rucController.text;
    final String usuario = _usuarioController.text;
    final String clave = _claveController.text;
    
    // Obtenemos la instancia del UserProvider para guardar los datos
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final userModel = await _authService.login(
        ruc: ruc, 
        cusuar: usuario, 
        dclave: clave,
      );

       // 🔹 Antes de usar context, verifica si el widget sigue montado
    if (!mounted) return;

      if (userModel.strMensaje.isEmpty) {
        // Login exitoso
        
        // Guardar o limpiar credenciales según "Recordarme"
        if (_rememberMe) {
          await _authService.saveCredentials(
            ruc: ruc,
            usuario: usuario,
            clave: clave,
          );
        } else {
          await _authService.clearSavedCredentials();
        }
        
        // Obtener correo del usuario desde SharedPreferences (ya se guardó en el login)
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email');
        
        // 1. Guardar los datos del usuario, RUC y correo en el Provider
        userProvider.setUser(userModel, ruc, email: userEmail);

        // 2. Registrar token FCM después del login exitoso
        final codigoTrabajador = userModel.strDato1;
        if (codigoTrabajador.isNotEmpty) {
          await NotificationService.registerTokenAfterLogin(codigoTrabajador);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenido, ${userModel.strDato2}!'),
            backgroundColor: Colors.green,
          ),
        );
        // Gate post-login: muestra aviso pendiente antes del dashboard (si aplica)
        Navigator.pushNamedAndRemoveUntil(context, '/post-login', (route) => false);
      } else {
        // Login fallido por mensaje de la API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de acceso: ${userModel.strMensaje}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
          if (!mounted) return; // 👈 evita usar context si ya no está montado
        //print("🧩 ERROR DE LOGIN ---> $e"); // 👈 mostrará el error completo en flutter logs

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), // 👈 muestra todo el texto del error
            backgroundColor: Colors.red,
          ),
        );
      } finally {
            if (mounted){ 
              setState(() {
                _isLoading = false;
              });
            }
        }
  }

  @override
  void dispose() {
    _rucController.dispose();
    _usuarioController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Título de FIDESOFT
                Text(
                  'FIDESOFT',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sistema de Planillas y RR.HH.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 60),

                // Campo Empresa (RUC)
                TextFormField(
                  controller: _rucController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'RUC de la Empresa',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingrese RUC' : null,
                ),
                const SizedBox(height: 20),

                // Campo Usuario
                TextFormField(
                  controller: _usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingrese usuario' : null,
                ),
                const SizedBox(height: 20),

                // Campo Clave
                TextFormField(
                  controller: _claveController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Clave',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingrese clave' : null,
                ),
                const SizedBox(height: 20),

                // Checkbox "Recordarme"
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Recordarme',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Botón de Login (con indicador de carga)
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'INGRESAR',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}