// lib/features/trabajadores/presentation/mis_datos_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/trabajador_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/vacaciones_permisos_service.dart';

class MisDatosScreen extends StatefulWidget {
  const MisDatosScreen({super.key});

  @override
  State<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends State<MisDatosScreen> {
  final AuthService _authService = AuthService();
  final VacacionesPermisosService _vacacionesService = VacacionesPermisosService();

  UserProfileModel? _perfil;
  TrabajadorModel? _trabajador;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final perfil = await _authService.obtenerPerfilUsuario();
      TrabajadorModel? trabajador;
      final codigo = perfil.codigoTrabajadorExterno?.trim();
      if (codigo != null && codigo.isNotEmpty) {
        final response = await _vacacionesService.obtenerTrabajadores(
          codigo: codigo,
          limit: 1,
        );
        if (response.items.isNotEmpty) {
          trabajador = response.items.first;
        }
      }

      if (mounted) {
        setState(() {
          _perfil = perfil;
          _trabajador = trabajador;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Color primaryColor = args?['primaryColor'] as Color? ?? const Color(0xFF5A8D8B);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Datos'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _perfil == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Datos'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _error.isNotEmpty ? _error : 'No se pudo cargar el perfil.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final perfil = _perfil!;
    final trabajador = _trabajador;
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

    final String nombreCompleto = trabajador?.nombreCompleto ?? perfil.nombreCompleto;
    final String codigo = trabajador?.codigoTrabajador ?? (perfil.codigoTrabajadorExterno ?? '').trim();
    final String dni = trabajador?.dni ?? '';
    final String correo = (trabajador?.correo ?? perfil.correo).trim();
    final String telefono = (trabajador?.telefono ?? perfil.telefono ?? '').trim();
    final DateTime? fechaNacimiento = trabajador?.fechaNacimiento;
    final String area = (trabajador?.descripcionArea ?? perfil.area ?? '').trim();
    final String seccion = trabajador?.descripcionSeccion ?? '';
    final String cargo = (trabajador?.descripcionCargo ?? perfil.cargo ?? '').trim();
    final DateTime? fechaIngreso = trabajador?.fechaIngreso;
    final DateTime? fechaFinContrato = trabajador?.fechaFinContrato;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Datos'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal con información básica (mismo formato que Detalle Trabajador)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      nombreCompleto,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (codigo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          codigo,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Información personal (incluye DNI; fecha nacimiento dd/MM/yyyy)
            _buildSectionTitle('Información Personal', primaryColor),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'DNI',
                    value: dni.isEmpty ? 'No disponible' : dni,
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Correo',
                    value: correo.isEmpty ? '-' : correo,
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: telefono.isEmpty ? '-' : telefono,
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'Fecha de Nacimiento',
                    value: fechaNacimiento != null
                        ? dateFormat.format(fechaNacimiento)
                        : 'No disponible',
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Información laboral (incluye Fecha de Ingreso y Fecha Fin de Contrato)
            _buildSectionTitle('Información Laboral', primaryColor),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.business,
                    label: 'Área',
                    value: area.isEmpty ? 'No disponible' : area,
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.domain,
                    label: 'Sección',
                    value: seccion.isEmpty ? 'No disponible' : seccion,
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.work,
                    label: 'Cargo',
                    value: cargo.isEmpty ? 'No disponible' : cargo,
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de Ingreso',
                    value: fechaIngreso != null
                        ? dateFormat.format(fechaIngreso)
                        : 'No disponible',
                    primaryColor: primaryColor,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    icon: Icons.event_busy,
                    label: 'Fecha Fin de Contrato',
                    value: fechaFinContrato != null
                        ? dateFormat.format(fechaFinContrato)
                        : 'No disponible',
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
