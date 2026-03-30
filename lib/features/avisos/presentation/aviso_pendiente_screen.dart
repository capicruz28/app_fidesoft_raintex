import 'package:flutter/material.dart';
import '../../../data/models/aviso_pendiente_model.dart';
import '../../../data/services/avisos_service.dart';
import '../../documentos/presentation/pdf_viewer_screen.dart';

class AvisoPendienteScreen extends StatefulWidget {
  final AvisoPendiente aviso;
  final Color primaryColor;

  const AvisoPendienteScreen({
    super.key,
    required this.aviso,
    required this.primaryColor,
  });

  @override
  State<AvisoPendienteScreen> createState() => _AvisoPendienteScreenState();
}

class _AvisoPendienteScreenState extends State<AvisoPendienteScreen> {
  final AvisosService _service = AvisosService();
  bool _conforme = false;
  bool _isSaving = false;
  bool _marcadoVisualizado = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirPdfYMarcarVisualizado();
    });
  }

  Future<void> _abrirPdfYMarcarVisualizado() async {
    if (_marcadoVisualizado) {
      await _abrirPdf();
      return;
    }

    setState(() {
      _error = '';
    });

    try {
      await _service.marcarVisualizado();
      _marcadoVisualizado = true;
    } catch (e) {
      // No bloquear por esto; el usuario igual puede ver/aceptar.
      _error = e.toString();
    }

    if (!mounted) return;
    await _abrirPdf();
  }

  Future<void> _abrirPdf() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          base64Pdf: widget.aviso.archivoPdfBase64,
          title: 'Aviso',
          primaryColor: widget.primaryColor,
        ),
      ),
    );
  }

  Future<void> _grabar() async {
    if (!_conforme) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _error = '';
    });

    try {
      await _service.aceptarConforme();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aviso Pendiente'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tienes un aviso pendiente de lectura y conformidad.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Archivo: ${widget.aviso.nombreArchivo}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _abrirPdfYMarcarVisualizado,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Ver aviso (PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
                      value: _conforme,
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _conforme = v ?? false),
                      activeColor: widget.primaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'Conforme',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (!_conforme || _isSaving) ? null : _grabar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Grabar'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Debes aceptar el aviso para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

