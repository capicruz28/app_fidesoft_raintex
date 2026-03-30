// lib/data/models/trabajador_model.dart
class TrabajadorModel {
  final String codigoTrabajador;
  final String nombreCompleto;
  final String codigoArea;
  final String codigoSeccion;
  final String codigoCargo;
  final String descripcionArea;
  final String descripcionSeccion;
  final String descripcionCargo;
  final String dni;
  final String? correo;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final DateTime? fechaIngreso;
  final DateTime? fechaFinContrato;

  TrabajadorModel({
    required this.codigoTrabajador,
    required this.nombreCompleto,
    required this.codigoArea,
    required this.codigoSeccion,
    required this.codigoCargo,
    required this.descripcionArea,
    required this.descripcionSeccion,
    required this.descripcionCargo,
    required this.dni,
    this.correo,
    this.telefono,
    this.fechaNacimiento,
    this.fechaIngreso,
    this.fechaFinContrato,
  });

  factory TrabajadorModel.fromJson(Map<String, dynamic> json) {
    return TrabajadorModel(
      codigoTrabajador: json['codigo_trabajador'] ?? json['codigoTrabajador'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? json['nombreCompleto'] ?? '',
      codigoArea: json['codigo_area'] ?? json['codigoArea'] ?? '',
      codigoSeccion: json['codigo_seccion'] ?? json['codigoSeccion'] ?? '',
      codigoCargo: json['codigo_cargo'] ?? json['codigoCargo'] ?? '',
      descripcionArea: json['descripcion_area'] ?? json['descripcionArea'] ?? '',
      descripcionSeccion: json['descripcion_seccion'] ?? json['descripcionSeccion'] ?? '',
      descripcionCargo: json['descripcion_cargo'] ?? json['descripcionCargo'] ?? '',
      dni: json['dni'] ?? '',
      correo: json['correo']?.toString(),
      telefono: json['telefono']?.toString(),
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'])
          : null,
      fechaFinContrato: json['fecha_fin_contrato'] != null
          ? DateTime.parse(json['fecha_fin_contrato'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_trabajador': codigoTrabajador,
      'nombre_completo': nombreCompleto,
      'codigo_area': codigoArea,
      'codigo_seccion': codigoSeccion,
      'codigo_cargo': codigoCargo,
      'descripcion_area': descripcionArea,
      'descripcion_seccion': descripcionSeccion,
      'descripcion_cargo': descripcionCargo,
      'dni': dni,
       if (correo != null) 'correo': correo,
       if (telefono != null) 'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'fecha_ingreso': fechaIngreso?.toIso8601String().split('T')[0],
      'fecha_fin_contrato': fechaFinContrato?.toIso8601String().split('T')[0],
    };
  }

  // Calcular edad
  int? get edad {
    if (fechaNacimiento == null) return null;
    final now = DateTime.now();
    int edad = now.year - fechaNacimiento!.year;
    if (now.month < fechaNacimiento!.month ||
        (now.month == fechaNacimiento!.month && now.day < fechaNacimiento!.day)) {
      edad--;
    }
    return edad;
  }
}

// Modelo para respuesta paginada
class TrabajadoresResponse {
  final List<TrabajadorModel> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  TrabajadoresResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory TrabajadoresResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => TrabajadorModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    
    return TrabajadoresResponse(
      items: items,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      pages: json['pages'] ?? 0,
    );
  }
}
