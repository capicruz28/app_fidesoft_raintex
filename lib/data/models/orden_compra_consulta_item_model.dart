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
      return double.tryParse(v.toString()) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return OrdenCompraConsultaItemModel(
      citems: (json['citems'] ?? '').toString().trim(),
      ditems: (json['ditems'] ?? '').toString().trim(),
      qsolic: parseDouble(json['qsolic']),
      ipruni: parseDouble(json['ipruni']),
      norden: parseInt(json['norden']),
    );
  }
}

