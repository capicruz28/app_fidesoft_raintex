import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../../data/services/avisos_service.dart';
import '../../../features/avisos/presentation/aviso_pendiente_screen.dart';

class PostLoginGateScreen extends StatefulWidget {
  const PostLoginGateScreen({super.key});

  @override
  State<PostLoginGateScreen> createState() => _PostLoginGateScreenState();
}

class _PostLoginGateScreenState extends State<PostLoginGateScreen> {
  final AvisosService _avisosService = AvisosService();
  bool _didRoute = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYAbrir();
    });
  }

  Future<void> _verificarYAbrir() async {
    if (_didRoute) return;
    setState(() => _error = '');

    try {
      final resp = await _avisosService.obtenerAvisoPendiente();

      if (!mounted) return;
      _didRoute = true;

      if (resp.pendiente == true && resp.aviso != null) {
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AvisoPendienteScreen(
              aviso: resp.aviso!,
              primaryColor: Theme.of(context).primaryColor,
            ),
          ),
        );

        if (!mounted) return;
        if (ok == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          // Si no aceptó, volver a intentar la verificación.
          _didRoute = false;
          await _verificarYAbrir();
        }
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Verificando avisos...'),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _verificarYAbrir,
                  child: const Text('Reintentar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Omitir por ahora'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

