import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class PostLoginGateScreen extends StatefulWidget {
  const PostLoginGateScreen({super.key});

  @override
  State<PostLoginGateScreen> createState() => _PostLoginGateScreenState();
}

class _PostLoginGateScreenState extends State<PostLoginGateScreen> {
  bool _didRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _irADashboard();
    });
  }

  Future<void> _irADashboard() async {
    if (_didRoute) return;
    _didRoute = true;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
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
              const Text('Ingresando...'),
            ],
          ),
        ),
      ),
    );
  }
}

