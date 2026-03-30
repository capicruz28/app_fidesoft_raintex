// lib/features/auth/presentation/perfil_usuario_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../core/providers/user_provider.dart';
import 'cambiar_contrasena_screen.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final AuthService _authService = AuthService();
  UserProfileModel? _perfil;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final perfil = await _authService.obtenerPerfilUsuario();
      if (mounted) {
        setState(() {
          _perfil = perfil;
          _isLoading = false;
        });
        // Actualizar correo en UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.setUserEmail(perfil.correo);
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString();
        if (errMsg.contains('SESSION_EXPIRED') || errMsg.contains('credenciales')) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.logout();
          await _authService.logout();
          await _authService.clearSavedCredentials();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          return;
        }
        setState(() {
          _error = 'Error al cargar perfil: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarPerfil,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _perfil == null
                  ? const Center(child: Text('No se pudo cargar el perfil'))
                  : RefreshIndicator(
                      onRefresh: _cargarPerfil,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Header con avatar y nombre
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  // Avatar grande
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Nombre completo
                                  Text(
                                    _perfil!.nombreCompleto,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Correo
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _perfil!.correo,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Teléfono
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          (_perfil!.telefono ?? '').trim(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),

                            // Información del usuario
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título de sección
                                  Text(
                                    'Información Personal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Código de Trabajador
                                  if (_perfil!.codigoTrabajadorExterno != null &&
                                      _perfil!.codigoTrabajadorExterno!.isNotEmpty)
                                    _buildInfoCard(
                                      icon: Icons.badge_outlined,
                                      label: 'Código de Trabajador',
                                      value: _perfil!.codigoTrabajadorExterno!,
                                      isDarkMode: isDarkMode,
                                    ),

                                  // Teléfono
                                  _buildInfoCard(
                                    icon: Icons.phone_outlined,
                                    label: 'Teléfono',
                                    value: (_perfil!.telefono ?? '').trim(),
                                    isDarkMode: isDarkMode,
                                  ),

                                  // Nombre de Usuario
                                  _buildInfoCard(
                                    icon: Icons.account_circle_outlined,
                                    label: 'Nombre de Usuario',
                                    value: _perfil!.nombreUsuario,
                                    isDarkMode: isDarkMode,
                                  ),

                                  // Tipo de Trabajador
                                  if (_perfil!.tipoTrabajador != null &&
                                      _perfil!.tipoTrabajador!.isNotEmpty)
                                    _buildInfoCard(
                                      icon: Icons.work_outline,
                                      label: 'Tipo de Trabajador',
                                      value: _perfil!.tipoTrabajador!,
                                      isDarkMode: isDarkMode,
                                    ),

                                  // Área
                                  if (_perfil!.area != null && _perfil!.area!.isNotEmpty)
                                    _buildInfoCard(
                                      icon: Icons.business_outlined,
                                      label: 'Área',
                                      value: _perfil!.area!,
                                      isDarkMode: isDarkMode,
                                    ),

                                  // Cargo
                                  if (_perfil!.cargo != null && _perfil!.cargo!.isNotEmpty)
                                    _buildInfoCard(
                                      icon: Icons.work_outline,
                                      label: 'Cargo',
                                      value: _perfil!.cargo!,
                                      isDarkMode: isDarkMode,
                                    ),

                                  // Descripción
                                  if (_perfil!.descripcionUsuario != null &&
                                      _perfil!.descripcionUsuario!.isNotEmpty)
                                    _buildInfoCard(
                                      icon: Icons.description_outlined,
                                      label: 'Descripción',
                                      value: _perfil!.descripcionUsuario!,
                                      isDarkMode: isDarkMode,
                                    ),

                                  // Estado
                                  _buildInfoCard(
                                    icon: _perfil!.esActivo
                                        ? Icons.check_circle_outline
                                        : Icons.cancel_outlined,
                                    label: 'Estado',
                                    value: _perfil!.esActivo ? 'Activo' : 'Inactivo',
                                    isDarkMode: isDarkMode,
                                    valueColor: _perfil!.esActivo ? Colors.green : Colors.red,
                                  ),

                                  const SizedBox(height: 24),

                                  // Botón para cambiar contraseña
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final resultado = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CambiarContrasenaScreen(),
                                          ),
                                        );
                                        if (resultado == true && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Contraseña cambiada exitosamente'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.lock_outline),
                                      label: const Text('Cambiar Contraseña'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ??
                        (isDarkMode ? Colors.white : Colors.grey[900]),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
