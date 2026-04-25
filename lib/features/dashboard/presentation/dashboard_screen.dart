import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/user_provider.dart'; // <-- Importado
import '../../../data/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Lista de módulos reorganizados
  final List<Map<String, dynamic>> modules = const [
    // 1. Ordenes de compra
    {
      'title': 'Ordenes de compra',
      'subtitle': 'Aprobación y consulta',
      'icon': FontAwesomeIcons.fileSignature,
      'metric': '',
      'unit': '',
      'route': '/documentos',
      'color1': Color(0xFF8B80C1),
      'color2': Color(0xFFA69EDB),
    },
    // 2. Mis Datos
    {
      'title': 'Mis Datos',
      'subtitle': 'Detalle del usuario',
      'icon': Icons.person,
      'metric': '',
      'unit': '',
      'route': '/mis-datos',
      'color1': Color(0xFF5A8D8B),
      'color2': Color(0xFF7CA7A5),
    },
    /*
    // GRUPO 2: 10 COLORES SEMI-INTENSOS ANTERIORES
    {
      'title': 'Logística', 'subtitle': 'Rutas y Envíos', 'icon': Icons.local_shipping,
      'metric': '10', 'unit': 'rutas pendientes', 'route': '/logistica',
      'color1': Color(0xFF6D9886), 'color2': Color(0xFF86AE9B),
    },
    {
      'title': 'Ventas', 'subtitle': 'Objetivo del mes', 'icon': Icons.trending_up,
      'metric': '+15%', 'unit': 'crecimiento', 'route': '/ventas',
      'color1': Color(0xFFE47C7C), 'color2': Color(0xFFF09A9A),
    },
    {
      'title': 'Compras', 'subtitle': 'Órdenes pendientes', 'icon': Icons.shopping_cart,
      'metric': '4', 'unit': 'órdenes', 'route': '/compras',
      'color1': Color(0xFF4C7AA8), 'color2': Color(0xFF759BC0),
    },
    {
      'title': 'Calidad', 'subtitle': 'Auditoría en curso', 'icon': Icons.verified,
      'metric': '99.5%', 'unit': 'satisfacción', 'route': '/calidad',
      'color1': Color(0xFF8B80C1), 'color2': Color(0xFFA69EDB),
    },
    {
      'title': 'Seguridad', 'subtitle': 'Checklist diario', 'icon': Icons.security,
      'metric': 'OK', 'unit': 'sin incidentes', 'route': '/seguridad',
      'color1': Color(0xFFF7941D), 'color2': Color(0xFFFFB25B),
    },
    {
      'title': 'Marketing', 'subtitle': 'Campaña activa', 'icon': Icons.ads_click,
      'metric': 'CTR 4%', 'unit': 'visitas', 'route': '/marketing',
      'color1': Color(0xFFF0AF39), 'color2': Color(0xFFFFC96B),
    },
    {
      'title': 'Proveedores', 'subtitle': 'Facturas a pagar', 'icon': Icons.handshake,
      'metric': '6', 'unit': 'facturas', 'route': '/proveedores',
      'color1': Color(0xFF8F634A), 'color2': Color(0xFFAC8875),
    },
    {
      'title': 'Legal', 'subtitle': 'Contratos en revisión', 'icon': Icons.gavel,
      'metric': '3', 'unit': 'en espera', 'route': '/legal',
      'color1': Color(0xFF4D6C80), 'color2': Color(0xFF7D92A2),
    },
    {
      'title': 'Viajes', 'subtitle': 'Próximo vuelo', 'icon': Icons.flight,
      'metric': 'Miami', 'unit': '05/Nov', 'route': '/viajes',
      'color1': Color(0xFF4FA095), 'color2': Color(0xFF6DC1B6),
    },
    {
      'title': 'Inversiones', 'subtitle': 'Rendimiento anual', 'icon': Icons.trending_up_outlined,
      'metric': '+8%', 'unit': 'de ROI', 'route': '/inversiones',
      'color1': Color(0xFFD63447), 'color2': Color(0xFFE55869),
    },

    // GRUPO 3: 10 NUEVOS COLORES SEMI-INTENSOS
    {
      'title': 'Recursos', 'subtitle': 'Equipos y Activos', 'icon': Icons.devices_other,
      'metric': '45', 'unit': 'activos asignados', 'route': '/recursos',
      'color1': Color(0xFF5A8D8B), 'color2': Color(0xFF7CA7A5),
    },
    {
      'title': 'Integración', 'subtitle': 'Nuevos ingresos', 'icon': Icons.people_alt_sharp,
      'metric': '2', 'unit': 'en Onboarding', 'route': '/integracion',
      'color1': Color(0xFFB17D23), 'color2': Color(0xFFC79854),
    },
    {
      'title': 'Reportes', 'subtitle': 'Reporte mensual', 'icon': Icons.analytics,
      'metric': 'Listo', 'unit': 'para revisión', 'route': '/reportes',
      'color1': Color(0xFF8A53A8), 'color2': Color(0xFFA175BF),
    },
    {
      'title': 'Sostenibilidad', 'subtitle': 'Meta ambiental', 'icon': Icons.park,
      'metric': '70%', 'unit': 'progreso', 'route': '/sostenibilidad',
      'color1': Color(0xFF6B9356), 'color2': Color(0xFF8AB571),
    },
    {
      'title': 'Beneficios', 'subtitle': 'Consulta médica', 'icon': Icons.health_and_safety,
      'metric': 'Plan A', 'unit': 'activo', 'route': '/beneficios',
      'color1': Color(0xFF5A99B8), 'color2': Color(0xFF7DB3CB),
    },
    {
      'title': 'Desafíos', 'subtitle': 'Torneo interno', 'icon': Icons.emoji_events,
      'metric': 'Activo', 'unit': 'inscripción abierta', 'route': '/desafios',
      'color1': Color(0xFFDD6B5B), 'color2': Color(0xFFE88D80),
    },
    {
      'title': 'Formularios', 'subtitle': 'Encuesta de clima', 'icon': Icons.description,
      'metric': '10', 'unit': 'pendientes', 'route': '/formularios',
      'color1': Color(0xFF7A89A6), 'color2': Color(0xFF9CA9BD),
    },
    {
      'title': 'Herramientas', 'subtitle': 'Acceso a apps', 'icon': Icons.construction,
      'metric': 'Link', 'unit': 'directo', 'route': '/herramientas',
      'color1': Color(0xFFE0C45C), 'color2': Color(0xFFEAD585),
    },
    {
      'title': 'Archivos', 'subtitle': 'Documentos generales', 'icon': Icons.folder_zip,
      'metric': '50GB', 'unit': 'ocupados', 'route': '/archivos',
      'color1': Color(0xFF907163), 'color2': Color(0xFFA68D81),
    },
    {
      'title': 'Reuniones', 'subtitle': 'Agenda de hoy', 'icon': Icons.meeting_room,
      'metric': '10:00', 'unit': 'standup', 'route': '/reuniones',
      'color1': Color(0xFF47A467), 'color2': Color(0xFF6DC38A),
    },*/
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIDESOFT'),
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      drawer: _buildDrawer(context),
      body: _buildModuleGrid(context),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
    );
  }

  // --- Grid de Módulos OPTIMIZADO ---
  Widget _buildModuleGrid(BuildContext context) {
    // Todos los módulos están disponibles para todos los usuarios
    final modulesFiltrados = modules;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0,
      ),
      itemCount: modulesFiltrados.length,
      itemBuilder: (context, index) {
        final module = modulesFiltrados[index];
        return _buildModuleCard(
          context,
          module['title'] as String,
          module['subtitle'] as String,
          module['icon'] as IconData,
          module['metric'] as String,
          module['unit'] as String,
          module['route'] as String,
          module['color1'] as Color,
          module['color2'] as Color,
        );
      },
    );
  }

  // --- Tarjeta Modular RESPONSIVE ---
  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String metric,
    String unit,
    String route,
    Color color1,
    Color color2,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cardColor1 = isDarkMode
        ? Color.lerp(color1, Colors.white, 0.2)!
        : color1;
    final cardColor2 = isDarkMode
        ? Color.lerp(color2, Colors.white, 0.15)!
        : color2;

    return InkWell(
      onTap: () async {
        Navigator.pushNamed(
          context,
          route,
          arguments: {
            'title': title,
            'primaryColor': cardColor1,
            'iconColor': Colors.white,
          },
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(isDarkMode ? 0.3 : 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fondo con gradiente diagonal
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cardColor1, cardColor2],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // Elementos decorativos (círculos blancos)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 15,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Contenido principal
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: SizedBox(
                  height: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Parte superior: ícono con badge
                      Align(
                        alignment: Alignment.topRight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 20, color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // Parte central: Título y Subtítulo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.2,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Parte inferior: Métrica
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            metric,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // --- Drawer Mejorado (Ahora usa UserProvider) ---
  // -------------------------------------------------------------------------
  Drawer _buildDrawer(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // <-- Usando UserProvider

    final String userName = userProvider.userName;

    final isDarkMode = themeProvider.isDarkMode;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header del Usuario mejorado con gradiente y clickeable
          InkWell(
            onTap: () {
              Navigator.pop(context); // Cerrar drawer
              Navigator.pushNamed(context, '/perfil-usuario');
            },
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  // Avatar clickeable
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/perfil-usuario');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información del usuario
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre completo con manejo de overflow
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Correo electrónico
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userProvider.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icono de flecha para indicar que es clickeable
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Secciones del Drawer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                // Dashboard
                _buildDrawerTile(
                  context,
                  'Módulos Principales',
                  Icons.dashboard,
                  '/dashboard',
                  isDarkMode,
                  userProvider, // Pasamos el provider
                ),
                const SizedBox(height: 8),
                Divider(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  height: 16,
                ),
                const SizedBox(height: 8),

                // Tema Oscuro
                _buildThemeToggleTile(context, isDarkMode, themeProvider),
                const SizedBox(height: 8),

                // Cerrar Sesión
                Divider(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  height: 16,
                ),
                const SizedBox(height: 8),
                _buildDrawerTile(
                  context,
                  'Cerrar Sesión',
                  Icons.logout,
                  '/login', // La ruta ahora apunta directamente al login
                  isDarkMode,
                  userProvider, // Pasamos el provider
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tile del Drawer (Actualizado para Logout) ---
  Widget _buildDrawerTile(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    bool isDarkMode,
    UserProvider userProvider, { // Nuevo parámetro
    bool isLogout = false,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red.shade400 : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      leading: Icon(
        icon,
        color: isLogout ? Colors.red.shade400 : const Color(0xFF0D47A1),
      ),
      onTap: () async {
        Navigator.pop(context); // Cierra el Drawer

        if (isLogout) {
          // 1. Limpia la información del usuario en el provider
          userProvider.logout();
          // 2. Limpia el token de autenticación
          final authService = AuthService();
          await authService.logout();
          // 3. Limpiar credenciales guardadas al hacer logout explícito
          await authService.clearSavedCredentials();
          // 4. Navega al login y limpia todas las rutas anteriores
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } else if (route == '/dashboard') {
          // Si hace clic en Módulos Principales, simplemente cierra el drawer o navega sin animación
          // (Se usa pushNamedAndRemoveUntil para asegurar que no haya nada encima)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        } else {
          // Navegación a otras pantallas con argumentos
          final arguments = {
            'title': title,
            'primaryColor': const Color(0xFF0D47A1),
            'iconColor': Colors.white,
          };
          Navigator.pushNamed(context, route, arguments: arguments);
        }
      },
    );
  }

  // --- Toggle del Tema ---
  Widget _buildThemeToggleTile(
    BuildContext context,
    bool isDarkMode,
    ThemeProvider themeProvider,
  ) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Tema Oscuro',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.grey.shade900,
        ),
      ),
      leading: Icon(
        isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: const Color(0xFF0D47A1),
      ),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (value) => themeProvider.toggleTheme(value),
        activeColor: const Color(0xFF1565C0),
        activeTrackColor: const Color(0xFF1565C0).withOpacity(0.3),
      ),
    );
  }
}
