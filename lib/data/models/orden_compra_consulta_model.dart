import 'orden_compra_consulta_item_model.dart';

class OrdenCompraConsultaModel {
  final String ctpdoc;
  final String ndocum;
  final String proveedor;
  final DateTime? fechaEmision;
  final DateTime? fechaEntrega;
  final double total;
  final String monedaCodigo;
  final String cliente;
  final String tipoDocumento;

  final List<OrdenCompraConsultaItemModel> items;

  const OrdenCompraConsultaModel({
    required this.ctpdoc,
    required this.ndocum,
    required this.proveedor,
    required this.fechaEmision,
    required this.fechaEntrega,
    required this.total,
    required this.monedaCodigo,
    required this.cliente,
    required this.tipoDocumento,
    required this.items,
  });

  factory OrdenCompraConsultaModel.fromJson(Map<String, dynamic> json) {
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

    final rawItems = json['items'] ?? json['detalle'] ?? json['detalle_items'];
    final items = <OrdenCompraConsultaItemModel>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          items.add(OrdenCompraConsultaItemModel.fromJson(it));
        }
      }
    }

    return OrdenCompraConsultaModel(
      ctpdoc: (json['ctpdoc'] ?? '').toString(),
      ndocum: (json['ndocum'] ?? '').toString().trim(),
      proveedor: (json['proveedor'] ?? '').toString(),
      fechaEmision: parseDate(json['femisi']),
      fechaEntrega: parseDate(json['fentre']),
      total: parseDouble(json['itotal']),
      monedaCodigo: (json['cmoned'] ?? '').toString(),
      cliente: (json['cliente'] ?? '').toString(),
      tipoDocumento: (json['tipo_documento'] ?? '').toString(),
      items: items,
    );
  }

  factory OrdenCompraConsultaModel.headerFromFlatRow(
    Map<String, dynamic> json, {
    List<OrdenCompraConsultaItemModel> items = const [],
  }) {
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

    return OrdenCompraConsultaModel(
      ctpdoc: (json['ctpdoc'] ?? '').toString(),
      ndocum: (json['ndocum'] ?? '').toString().trim(),
      proveedor: (json['proveedor'] ?? '').toString(),
      fechaEmision: parseDate(json['femisi']),
      fechaEntrega: parseDate(json['fentre']),
      total: parseDouble(json['itotal']),
      monedaCodigo: (json['cmoned'] ?? '').toString(),
      cliente: (json['cliente'] ?? '').toString(),
      tipoDocumento: (json['tipo_documento'] ?? '').toString(),
      items: items,
    );
  }

  OrdenCompraConsultaModel copyWithItems(List<OrdenCompraConsultaItemModel> newItems) {
    return OrdenCompraConsultaModel(
      ctpdoc: ctpdoc,
      ndocum: ndocum,
      proveedor: proveedor,
      fechaEmision: fechaEmision,
      fechaEntrega: fechaEntrega,
      total: total,
      monedaCodigo: monedaCodigo,
      cliente: cliente,
      tipoDocumento: tipoDocumento,
      items: newItems,
    );
  }

  String get monedaLabel {
    if (monedaCodigo == '1') return r'$';
    if (monedaCodigo == '0') return 'S/.';
    return monedaCodigo;
  }

  String get groupId => tipoDocumento.trim().isEmpty ? 'Sin tipo' : tipoDocumento.trim();
  String get key => '$ctpdoc|$ndocum';
}

