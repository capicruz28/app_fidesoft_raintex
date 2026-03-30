class AvisoPendienteResponse {
  final bool pendiente;
  final AvisoPendiente? aviso;

  AvisoPendienteResponse({
    required this.pendiente,
    required this.aviso,
  });

  factory AvisoPendienteResponse.fromJson(Map<String, dynamic> json) {
    return AvisoPendienteResponse(
      pendiente: json['pendiente'] == true,
      aviso: json['aviso'] != null
          ? AvisoPendiente.fromJson(json['aviso'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AvisoPendiente {
  final String ctraba;
  final String saprob;
  final String? faprob;
  final String? fvisual;
  final String archivoPdfBase64;
  final String nombreArchivo;

  AvisoPendiente({
    required this.ctraba,
    required this.saprob,
    required this.faprob,
    required this.fvisual,
    required this.archivoPdfBase64,
    required this.nombreArchivo,
  });

  factory AvisoPendiente.fromJson(Map<String, dynamic> json) {
    return AvisoPendiente(
      ctraba: (json['ctraba'] ?? '').toString(),
      saprob: (json['saprob'] ?? '').toString(),
      faprob: json['faprob']?.toString(),
      fvisual: json['fvisual']?.toString(),
      archivoPdfBase64: (json['archivo_pdf_base64'] ?? '').toString(),
      nombreArchivo: (json['nombre_archivo'] ?? 'aviso.pdf').toString(),
    );
  }
}

