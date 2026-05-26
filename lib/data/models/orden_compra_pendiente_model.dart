import 'orden_compra_consulta_item_model.dart';

class OrdenCompraPendienteModel {
  final String ctpdoc;
  final String ndocum;
  final String proveedor;
  final DateTime? fechaEmision;
  final DateTime? fechaEntrega;
  final double total;
  final String monedaCodigo; // "1" => "$", "0" => "S/."
  final int norden;
  final String observacion;
  final String cliente;
  final String tipoDocumento;
  final String ordenTrabajo;
  final String formaPago;
  final String usuarioCreacion;
  final String tipoServicio;
  final List<OrdenCompraConsultaItemModel> items;

  const OrdenCompraPendienteModel({
    required this.ctpdoc,
    required this.ndocum,
    required this.proveedor,
    required this.fechaEmision,
    required this.fechaEntrega,
    required this.total,
    required this.monedaCodigo,
    required this.norden,
    required this.observacion,
    required this.cliente,
    required this.tipoDocumento,
    required this.ordenTrabajo,
    required this.formaPago,
    required this.usuarioCreacion,
    required this.tipoServicio,
    this.items = const [],
  });

  factory OrdenCompraPendienteModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return OrdenCompraPendienteModel(
      ctpdoc: (json['ctpdoc'] ?? '').toString(),
      ndocum: (json['ndocum'] ?? '').toString().trim(),
      proveedor: (json['proveedor'] ?? '').toString(),
      fechaEmision: parseDate(json['femisi']),
      fechaEntrega: parseDate(json['fentre']),
      total: parseDouble(json['itotal']),
      monedaCodigo: (json['cmoned'] ?? '').toString(),
      norden: parseInt(json['norden']),
      observacion: (json['observacion'] ?? '').toString(),
      cliente: (json['cliente'] ?? '').toString(),
      tipoDocumento: (json['tipo_documento'] ?? '').toString(),
      ordenTrabajo: (json['orden_trabajo'] ?? '').toString().trim(),
      formaPago: (json['forma_pago'] ?? '').toString().trim(),
      usuarioCreacion: (json['usuario_creacion'] ?? '').toString().trim(),
      tipoServicio: (json['tipo_servicio'] ?? '').toString().trim(),
      items: const [],
    );
  }

  String get monedaLabel {
    // Requisito: "$" si 1 y "S/." si 0
    if (monedaCodigo == '1') return r'$';
    if (monedaCodigo == '0') return 'S/.';
    return monedaCodigo;
  }

  Map<String, dynamic> toAprobarPayload() => {
        'ctpdoc': ctpdoc,
        'ndocum': ndocum,
        'norden': norden,
      };

  String get selectionKey => '$ctpdoc|$ndocum|$norden';

  OrdenCompraPendienteModel copyWithItems(List<OrdenCompraConsultaItemModel> newItems) {
    return OrdenCompraPendienteModel(
      ctpdoc: ctpdoc,
      ndocum: ndocum,
      proveedor: proveedor,
      fechaEmision: fechaEmision,
      fechaEntrega: fechaEntrega,
      total: total,
      monedaCodigo: monedaCodigo,
      norden: norden,
      observacion: observacion,
      cliente: cliente,
      tipoDocumento: tipoDocumento,
      ordenTrabajo: ordenTrabajo,
      formaPago: formaPago,
      usuarioCreacion: usuarioCreacion,
      tipoServicio: tipoServicio,
      items: newItems,
    );
  }
}

