class OrdenCompraConsultaItemModel {
  final String citems;
  final String ditems;
  final double qsolic;
  final double ipruni;
  final int norden;

  const OrdenCompraConsultaItemModel({
    required this.citems,
    required this.ditems,
    required this.qsolic,
    required this.ipruni,
    required this.norden,
  });

  factory OrdenCompraConsultaItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      final s = v.toString().trim().replaceAll(',', '.');
      return double.tryParse(s) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      final s = v.toString().trim();
      return int.tryParse(s) ?? 0;
    }

    return OrdenCompraConsultaItemModel(
      // Compatibilidad: antes venía como citems/ditems/qsolic/ipruni/norden
      // Ahora viene como articulo/descripcion_articulo/cantidad_solicitada/precio_unitario/orden_detalle
      citems: (json['articulo'] ?? json['citems'] ?? '').toString().trim(),
      ditems: (json['descripcion_articulo'] ?? json['ditems'] ?? '')
          .toString()
          .trim(),
      qsolic: parseDouble(json['cantidad_solicitada'] ?? json['qsolic']),
      ipruni: parseDouble(json['precio_unitario'] ?? json['ipruni']),
      norden: parseInt(json['orden_detalle'] ?? json['norden']),
    );
  }
}

