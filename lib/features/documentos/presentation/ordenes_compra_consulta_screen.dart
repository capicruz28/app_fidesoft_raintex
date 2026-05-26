import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/models/orden_compra_consulta_model.dart';
import '../../../data/services/ordenes_compra_service.dart';

class OrdenesCompraConsultaScreen extends StatefulWidget {
  const OrdenesCompraConsultaScreen({super.key});

  @override
  State<OrdenesCompraConsultaScreen> createState() =>
      _OrdenesCompraConsultaScreenState();
}

class _OrdenesCompraConsultaScreenState extends State<OrdenesCompraConsultaScreen> {
  final OrdenesCompraService _service = OrdenesCompraService();

  bool _loading = false;
  String _error = '';
  List<OrdenCompraConsultaModel> _items = [];

  // filtros
  String? _fCtpdoc;
  String? _fNdocum;
  String? _fFemisi; // YYYY-MM-DD
  String? _fCliente;
  String? _fProveedor;
  int _fLimit = 200;

  String _query = '';

  final Map<String, bool> _groupExpanded = {};
  final Map<String, bool> _detailExpanded = {}; // key: orderKey

  late final TextEditingController _ctpdocCtrl = TextEditingController();
  late final TextEditingController _ndocumCtrl = TextEditingController();
  late final TextEditingController _femisiCtrl = TextEditingController();
  late final TextEditingController _clienteCtrl = TextEditingController();
  late final TextEditingController _proveedorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ctpdocCtrl.dispose();
    _ndocumCtrl.dispose();
    _femisiCtrl.dispose();
    _clienteCtrl.dispose();
    _proveedorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final list = await _service.consultar(
        ctpdoc: _fCtpdoc,
        ndocum: _fNdocum,
        femisi: _fFemisi,
        cliente: _fCliente,
        proveedor: _fProveedor,
        limit: _fLimit,
      );

      list.sort((a, b) {
        final ga = a.groupId.toLowerCase();
        final gb = b.groupId.toLowerCase();
        final c = ga.compareTo(gb);
        if (c != 0) return c;
        return b.ndocum.compareTo(a.ndocum);
      });

      setState(() {
        _items = list;
        for (final it in list) {
          _groupExpanded.putIfAbsent(it.groupId, () => true);
          _detailExpanded.putIfAbsent(it.key, () => false);
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    setState(() {
      _fCtpdoc = _ctpdocCtrl.text.trim().isEmpty ? null : _ctpdocCtrl.text.trim();
      _fNdocum = _ndocumCtrl.text.trim().isEmpty ? null : _ndocumCtrl.text.trim();
      _fFemisi = _femisiCtrl.text.trim().isEmpty ? null : _femisiCtrl.text.trim();
      _fCliente = _clienteCtrl.text.trim().isEmpty ? null : _clienteCtrl.text.trim();
      _fProveedor = _proveedorCtrl.text.trim().isEmpty ? null : _proveedorCtrl.text.trim();
      _fLimit = 200;
    });
    await _load();
  }

  List<OrdenCompraConsultaModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    bool c(String v) => v.toLowerCase().contains(q);
    return _items.where((it) {
      return c(it.ndocum) ||
          c(it.proveedor) ||
          c(it.cliente) ||
          c(it.tipoDocumento) ||
          c(it.ctpdoc);
    }).toList();
  }

  Map<String, List<OrdenCompraConsultaModel>> get _grouped {
    final map = <String, List<OrdenCompraConsultaModel>>{};
    for (final it in _filtered) {
      map.putIfAbsent(it.groupId, () => []).add(it);
    }
    return map;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  String _formatMoney(String symbol, double total) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    return '$symbol ${fmt.format(total)}';
  }

  String _formatTotalsByCurrency(Iterable<OrdenCompraConsultaModel> items) {
    final totals = <String, double>{};
    for (final it in items) {
      final sym = it.monedaLabel;
      totals[sym] = (totals[sym] ?? 0) + it.total;
    }
    if (totals.isEmpty) return '—';
    if (totals.length == 1) {
      final sym = totals.keys.first;
      return _formatMoney(sym, totals[sym] ?? 0);
    }
    return totals.entries.map((e) => _formatMoney(e.key, e.value)).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final primaryColor = args?['primaryColor'] as Color? ?? const Color(0xFF0D47A1);
    final title = args?['title'] as String? ?? 'Consulta';

    final grouped = _grouped;
    final groupKeys = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersBar(primaryColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _search,
              child: _loading
                  ? ListView(
                      children: [
                        SizedBox(height: 80),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error.isNotEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              'No se pudo cargar la consulta.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(_error),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _search,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        )
                      : _items.isEmpty && _query.trim().isEmpty && _fCtpdoc == null && _fNdocum == null && _fFemisi == null && _fCliente == null && _fProveedor == null
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: const [
                                SizedBox(height: 60),
                                Icon(Icons.manage_search, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Center(child: Text('Usa los filtros y toca “Buscar” para consultar.')),
                              ],
                            )
                          : groupKeys.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: const [
                                SizedBox(height: 60),
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Center(child: Text('No hay resultados con los filtros actuales.')),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: groupKeys.length,
                              itemBuilder: (context, i) {
                                final k = groupKeys[i];
                                final list = grouped[k]!;
                                return _buildGroup(primaryColor, k, list);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _field(
                      _femisiCtrl,
                      label: 'F.Emisión',
                      hint: 'YYYY-MM-DD',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _field(
                      _ctpdocCtrl,
                      label: 'Tipo Doc.',
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _field(
                      _ndocumCtrl,
                      label: 'N° OC',
                      keyboardType: TextInputType.number,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _clienteCtrl,
                      label: 'Cliente',
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      _proveedorCtrl,
                      label: 'Proveedor',
                      inputFormatters: [UpperCaseTextFormatter()],
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_loading ? 'Buscando...' : 'Buscar'),
                  style: FilledButton.styleFrom(backgroundColor: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c, {
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(fontSize: 12),
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildGroup(Color primaryColor, String groupId, List<OrdenCompraConsultaModel> list) {
    final groupTotalLabel = _formatTotalsByCurrency(list);
    final ctpdocSet = list.map((e) => e.ctpdoc.trim()).where((e) => e.isNotEmpty).toSet();
    final ctpdocSuffix = ctpdocSet.length == 1 ? ' (${ctpdocSet.first})' : '';

    final expanded = _groupExpanded[groupId] ?? true;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('oc_consulta_group_$groupId'),
          maintainState: true,
          initiallyExpanded: expanded,
          onExpansionChanged: (v) => setState(() => _groupExpanded[groupId] = v),
          backgroundColor: primaryColor.withOpacity(0.10),
          collapsedBackgroundColor: primaryColor.withOpacity(0.10),
          iconColor: primaryColor,
          collapsedIconColor: primaryColor,
          trailing: const SizedBox.shrink(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: _bullet(expanded, primaryColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: título (una sola línea, máxima prioridad de ancho)
              Text(
                '${groupId.trim()}${ctpdocSuffix.trim()}',
                style: const TextStyle(fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Fila 2: importes (siempre visibles, secundarios al título)
              Text(
                groupTotalLabel.trim(),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Fila 3: metadata + expand icon
              Row(
                children: [
                  _CountBadge(count: list.length),
                  const SizedBox(width: 6),
                  Text(
                    'registros',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
          children: [
            ...list.map((it) => _buildOrderTile(primaryColor, it)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(Color primaryColor, OrdenCompraConsultaModel it) {
    final emision = _formatDate(it.fechaEmision);
    final entrega = _formatDate(it.fechaEntrega);
    final total = _formatMoney(it.monedaLabel, it.total);
    final detailOpen = _detailExpanded[it.key] ?? false;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: N° OC + Importe
            Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(
                        decoration: TextDecoration.none,
                      ),
                      children: [
                        TextSpan(
                          text: 'N° OC: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black54,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        TextSpan(
                          text: it.ndocum.isEmpty ? '—' : it.ndocum,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE53935),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  total,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DetailField(
              label: 'Proveedor',
              value: it.proveedor,
              labelStyle: _detailLabelStyle(),
              valueStyle: _detailValueStyle(),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DetailField(
                    label: 'F.Emisión',
                    value: emision,
                    labelStyle: _detailLabelStyle(),
                    valueStyle: _detailValueStyle(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetailField(
                    label: 'F.Entrega',
                    value: entrega,
                    labelStyle: _detailLabelStyle(),
                    valueStyle: _detailValueStyle(),
                  ),
                ),
              ],
            ),
            if (it.cliente.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              DetailField(
                label: 'Cliente',
                value: it.cliente.trim(),
                labelStyle: _detailLabelStyle(),
                valueStyle: _detailValueStyle(),
              ),
            ],
            if (it.ordenTrabajo.trim().isNotEmpty || it.formaPago.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, c) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      DetailField(
                        maxWidth: c.maxWidth,
                        label: 'OT',
                        value: it.ordenTrabajo,
                        labelStyle: _detailLabelStyle(),
                        valueStyle: _detailValueStyle(),
                      ),
                      DetailField(
                        maxWidth: c.maxWidth,
                        label: 'Forma de Pago',
                        value: it.formaPago,
                        labelStyle: _detailLabelStyle(),
                        valueStyle: _detailValueStyle(),
                      ),
                    ],
                  );
                },
              ),
            ],
            if (it.usuarioCreacion.trim().isNotEmpty || it.tipoServicio.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, c) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      DetailField(
                        maxWidth: c.maxWidth,
                        label: 'Usuario Emi.',
                        value: it.usuarioCreacion,
                        labelStyle: _detailLabelStyle(),
                        valueStyle: _detailValueStyle(),
                      ),
                      DetailField(
                        maxWidth: c.maxWidth,
                        label: 'Tipo OC',
                        value: it.tipoServicio,
                        labelStyle: _detailLabelStyle(),
                        valueStyle: _detailValueStyle(),
                      ),
                    ],
                  );
                },
              ),
            ],

            // Acordeón del detalle
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: PageStorageKey('oc_consulta_detail_${it.key}'),
                maintainState: true,
                initiallyExpanded: detailOpen,
                onExpansionChanged: (v) => setState(() => _detailExpanded[it.key] = v),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 6),
                leading: _bullet(detailOpen, primaryColor),
                title: Text(
                  'Detalle (${it.items.length})',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  detailOpen ? 'Contraer' : 'Ver ítems',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                children: [
                  if (it.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Sin detalle disponible.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    )
                  else
                    ..._sortedDetailItems(it)
                        .map((d) => _buildDetailRow(primaryColor, d)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(Color primaryColor, dynamic d) {
    // d is OrdenCompraConsultaItemModel
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final qty = fmt.format((d.qsolic as double));
    final unit = fmt.format((d.ipruni as double));
    final total = fmt.format((d.qsolic as double) * (d.ipruni as double));
    final desc = (d.ditems as String).isEmpty ? '—' : (d.ditems as String);
    final code = (d.citems as String).isEmpty ? '' : (d.citems as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${d.norden}. $desc',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (code.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DetailField(
                  label: 'Cant.',
                  value: qty,
                  labelStyle: _detailLabelStyle(),
                  valueStyle: _detailValueStyle(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DetailField(
                  label: 'P. Unit',
                  value: unit,
                  labelStyle: _detailLabelStyle(),
                  valueStyle: _detailValueStyle(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DetailField(
                  label: 'Total',
                  value: total,
                  labelStyle: _detailLabelStyle(),
                  valueStyle: _detailValueStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<dynamic> _sortedDetailItems(OrdenCompraConsultaModel it) {
    final list = it.items.toList();
    list.sort((a, b) => a.norden.compareTo(b.norden));
    return list;
  }

  Widget _bullet(bool expanded, Color primaryColor) {
    // Viñeta: lleno si expandido, contorno si contraído
    return Icon(
      expanded ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      size: 18,
      color: primaryColor,
    );
  }

  TextStyle _detailLabelStyle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: null,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1.2,
      color: isDark ? Colors.white70 : Colors.grey.shade700,
      decoration: TextDecoration.none,
      textBaseline: TextBaseline.alphabetic,
    );
  }

  TextStyle _detailValueStyle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: null,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1.2,
      color: isDark ? Colors.white : Colors.black87,
      decoration: TextDecoration.none,
      textBaseline: TextBaseline.alphabetic,
    );
  }

}

class DetailField extends StatelessWidget {
  const DetailField({
    super.key,
    this.maxWidth = double.infinity,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.placeholder = '—',
    this.maxLines = 2,
  });

  final double maxWidth;
  final String label;
  final String? value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final l = label.trim();
    final v = (value ?? '').trim();
    final show = v.isEmpty ? placeholder : v;

    // Importante: en un Wrap, un Row con Flexible puede "estirarse" al ancho disponible
    // y provocar saltos prematuros. Usamos RichText intrínseco con un maxWidth real.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        text: TextSpan(
          children: [
            TextSpan(text: '$l: ', style: labelStyle),
            TextSpan(text: show, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Bottom-sheet filters removed in favor of inline filters.

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}


