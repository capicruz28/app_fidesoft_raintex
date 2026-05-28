import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/orden_compra_pendiente_model.dart';
import '../../../data/services/ordenes_compra_service.dart';

class OrdenesCompraAprobacionScreen extends StatefulWidget {
  const OrdenesCompraAprobacionScreen({super.key});

  @override
  State<OrdenesCompraAprobacionScreen> createState() =>
      _OrdenesCompraAprobacionScreenState();
}

class _OrdenesCompraAprobacionScreenState
    extends State<OrdenesCompraAprobacionScreen> {
  final OrdenesCompraService _service = OrdenesCompraService();

  bool _loading = true;
  String _error = '';
  List<OrdenCompraPendienteModel> _items = [];
  String _query = '';
  final Set<String> _selectedKeys = {};
  final Map<String, bool> _groupExpanded = {};
  final Map<String, bool> _detailExpanded = {}; // key: selectionKey
  final Set<String> _detailLoading = {};
  bool _approving = false;
  bool _isGroupedView = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final list = await _service.obtenerPendientes();
      list.sort((a, b) {
        final ta = a.tipoDocumento.toLowerCase().trim();
        final tb = b.tipoDocumento.toLowerCase().trim();
        final c = ta.compareTo(tb);
        if (c != 0) return c;
        final pa = a.proveedor.toLowerCase().trim();
        final pb = b.proveedor.toLowerCase().trim();
        final c2 = pa.compareTo(pb);
        if (c2 != 0) return c2;
        return a.ndocum.compareTo(b.ndocum);
      });
      setState(() {
        _items = list;
        _selectedKeys.removeWhere((k) => !list.any((x) => x.selectionKey == k));
        for (final it in list) {
          final groupId = it.tipoDocumento.trim().isEmpty
              ? 'Sin tipo'
              : it.tipoDocumento.trim();
          _groupExpanded.putIfAbsent(groupId, () => true);
          _detailExpanded.putIfAbsent(it.selectionKey, () => false);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, List<OrdenCompraPendienteModel>> get _grouped {
    final map = <String, List<OrdenCompraPendienteModel>>{};
    for (final it in _filteredItems) {
      final key = it.tipoDocumento.trim().isEmpty
          ? 'Sin tipo'
          : it.tipoDocumento.trim();
      map.putIfAbsent(key, () => []).add(it);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.ndocum.compareTo(b.ndocum));
    }
    return map;
  }

  List<OrdenCompraPendienteModel> get _linearDisplayItems {
    final items = List<OrdenCompraPendienteModel>.from(_filteredItems);
    items.sort((a, b) => a.ndocum.compareTo(b.ndocum));
    return items;
  }

  String _ocIdentification(String ctpdoc, String ndocum) {
    final c = ctpdoc.trim();
    final n = ndocum.trim();
    if (c.isEmpty && n.isEmpty) return '—';
    return '$c-$n';
  }

  List<OrdenCompraPendienteModel> get _filteredItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;

    bool contains(String v) => v.toLowerCase().contains(q);

    return _items.where((it) {
      return contains(it.ndocum) ||
          contains(it.cliente) ||
          contains(it.proveedor) ||
          contains(it.observacion) ||
          contains(it.tipoDocumento) ||
          contains(it.ctpdoc);
    }).toList();
  }

  bool _isSelected(OrdenCompraPendienteModel it) =>
      _selectedKeys.contains(it.selectionKey);

  void _toggleSelected(OrdenCompraPendienteModel it, bool value) {
    setState(() {
      if (value) {
        _selectedKeys.add(it.selectionKey);
      } else {
        _selectedKeys.remove(it.selectionKey);
      }
    });
  }

  int get _selectedCount => _selectedKeys.length;

  double get _selectedTotal {
    double sum = 0;
    for (final it in _items) {
      if (_selectedKeys.contains(it.selectionKey)) sum += it.total;
    }
    return sum;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  String _formatMoney(OrdenCompraPendienteModel it) {
    final symbol = it.monedaLabel;
    // Requisito: miles con "," y decimales con "."
    // Esto NO coincide con el formato típico de "es_PE", así que fijamos el patrón.
    final fmt = NumberFormat('#,##0.00', 'en_US');
    return '$symbol ${fmt.format(it.total)}';
  }

  String _formatTotalsByCurrency(Iterable<OrdenCompraPendienteModel> items) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final totals = <String, double>{};
    for (final it in items) {
      final sym = it.monedaLabel;
      totals[sym] = (totals[sym] ?? 0) + it.total;
    }
    if (totals.isEmpty) return '—';
    if (totals.length == 1) {
      final sym = totals.keys.first;
      return '$sym ${fmt.format(totals[sym] ?? 0)}';
    }
    // Si hubiera más de una moneda en el mismo grupo, mostramos ambas.
    return totals.entries
        .map((e) => '${e.key} ${fmt.format(e.value)}')
        .join(' · ');
  }

  Future<void> _approveSelected() async {
    if (_selectedKeys.isEmpty || _approving) return;

    final selected = _items
        .where((it) => _selectedKeys.contains(it.selectionKey))
        .toList();
    final byMoneda = <String, int>{};
    for (final it in selected) {
      final key = it.monedaLabel;
      byMoneda[key] = (byMoneda[key] ?? 0) + 1;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar aprobación'),
        content: Text(
          'Vas a aprobar ${selected.length} orden(es).\n\n'
          'Total seleccionado: ${selected.isEmpty ? '—' : selected.first.monedaLabel} ${_selectedTotal.toStringAsFixed(2)}\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _approving = true);
    final failures = <String>[];

    try {
      for (final it in selected) {
        try {
          await _service.aprobar(
            ctpdoc: it.ctpdoc,
            ndocum: it.ndocum,
            norden: it.norden,
          );
        } catch (e) {
          final msg = e.toString().replaceAll('Exception: ', '');
          failures.add('${it.ndocum} (${it.tipoDocumento}): $msg');
        }
      }

      if (!mounted) return;

      if (failures.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aprobación completada.')));
        _selectedKeys.clear();
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Algunas aprobaciones fallaron (${failures.length}).',
            ),
          ),
        );
        await _load();
      }
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  bool _hasMeaningfulDetails(OrdenCompraPendienteModel it) {
    if (it.items.isEmpty) return false;
    return it.items.any(
      (d) =>
          d.citems.trim().isNotEmpty ||
          d.ditems.trim().isNotEmpty ||
          d.qsolic != 0 ||
          d.ipruni != 0,
    );
  }

  Future<void> _ensureDetailLoaded(OrdenCompraPendienteModel it) async {
    if (_detailLoading.contains(it.selectionKey) || _hasMeaningfulDetails(it)) {
      return;
    }

    _detailLoading.add(it.selectionKey);
    try {
      final result = await _service.consultar(
        ctpdoc: it.ctpdoc.trim(),
        ndocum: it.ndocum.trim(),
        limit: 50,
      );

      final match = result
          .where(
            (x) =>
                x.ctpdoc.trim() == it.ctpdoc.trim() &&
                x.ndocum.trim() == it.ndocum.trim(),
          )
          .toList();
      if (!mounted) return;

      if (match.isNotEmpty) {
        setState(() {
          final idx = _items.indexWhere(
            (x) => x.selectionKey == it.selectionKey,
          );
          if (idx >= 0) {
            _items[idx] = _items[idx].copyWithItems(match.first.items);
          }
        });
      }
    } catch (_) {
      // Si falla, dejamos el detalle como está para no romper la pantalla.
    } finally {
      _detailLoading.remove(it.selectionKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final primaryColor =
        args?['primaryColor'] as Color? ?? const Color(0xFF0D47A1);
    final title = args?['title'] as String? ?? 'Aprobación';

    final grouped = _grouped;
    final groupKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(primaryColor),
          _buildSearchBar(primaryColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
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
                          'No se pudo cargar las órdenes pendientes.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_error),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    )
                  : groupKeys.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 60),
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text('No hay órdenes pendientes por aprobar.'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _isGroupedView
                          ? groupKeys.length
                          : _linearDisplayItems.length,
                      itemBuilder: (context, i) {
                        if (_isGroupedView) {
                          final k = groupKeys[i];
                          final list = grouped[k]!;
                          return _buildGroup(k, k, list, primaryColor);
                        }
                        return _buildItemTile(
                          _linearDisplayItems[i],
                          primaryColor,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );
  }

  Widget _buildViewModeButtons(Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildViewModeButton(
          primaryColor: primaryColor,
          icon: Icons.view_list,
          tooltip: 'Vista lista',
          selected: !_isGroupedView,
          onTap: () {
            if (_isGroupedView) setState(() => _isGroupedView = false);
          },
        ),
        const SizedBox(width: 6),
        _buildViewModeButton(
          primaryColor: primaryColor,
          icon: Icons.layers_outlined,
          tooltip: 'Vista agrupada',
          selected: _isGroupedView,
          onTap: () {
            if (!_isGroupedView) setState(() => _isGroupedView = true);
          },
        ),
      ],
    );
  }

  Widget _buildViewModeButton({
    required Color primaryColor,
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: selected
              ? primaryColor.withOpacity(0.18)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          child: Icon(
            icon,
            size: 20,
            color: selected ? primaryColor : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(Color primaryColor) {
    final totalPendientes = _items.length;
    final selected = _selectedCount;
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(Icons.pending_actions, color: primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendientes: $totalPendientes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    selected == 0
                        ? 'Selecciona una o más para aprobar'
                        : 'Seleccionadas: $selected',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected > 0) ...[
              TextButton.icon(
                onPressed: _approving
                    ? null
                    : () => setState(() => _selectedKeys.clear()),
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
              ),
              const SizedBox(width: 4),
            ],
            _buildViewModeButtons(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(
    String groupId,
    String title,
    List<OrdenCompraPendienteModel> list,
    Color primaryColor,
  ) {
    final selectedInGroup = list.where((x) => _isSelected(x)).length;
    final allSelected = selectedInGroup == list.length && list.isNotEmpty;
    final someSelected = selectedInGroup > 0 && !allSelected;

    final groupTotalLabel = _formatTotalsByCurrency(list);
    final ctpdocSet = list
        .map((e) => e.ctpdoc.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final ctpdocSuffix = ctpdocSet.length == 1 ? ' (${ctpdocSet.first})' : '';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('oc_group_$groupId'),
          maintainState: true,
          initiallyExpanded: _groupExpanded[groupId] ?? true,
          onExpansionChanged: (expanded) {
            setState(() {
              _groupExpanded[groupId] = expanded;
            });
          },
          backgroundColor: primaryColor.withOpacity(0.10),
          collapsedBackgroundColor: primaryColor.withOpacity(0.10),
          iconColor: primaryColor,
          collapsedIconColor: primaryColor,
          trailing: const SizedBox.shrink(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textColor: Colors.black87,
          collapsedTextColor: Colors.black87,
          leading: _bullet(_groupExpanded[groupId] ?? true, primaryColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: título (una sola línea, máxima prioridad de ancho)
              Text(
                '${title.trim()}${ctpdocSuffix.trim()}',
                style: const TextStyle(fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Fila 2: importes
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
              // Fila 3: metadata + checkbox + expand icon
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
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: allSelected
                            ? true
                            : (someSelected ? null : false),
                        tristate: true,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: _approving
                            ? null
                            : (v) {
                                final target = v == true;
                                setState(() {
                                  for (final it in list) {
                                    if (target) {
                                      _selectedKeys.add(it.selectionKey);
                                    } else {
                                      _selectedKeys.remove(it.selectionKey);
                                    }
                                  }
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    (_groupExpanded[groupId] ?? true)
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
          children: [
            ...list.map((it) => _buildItemTile(it, primaryColor)),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(OrdenCompraPendienteModel it, Color primaryColor) {
    final checked = _isSelected(it);
    final emision = _formatDate(it.fechaEmision);
    final entrega = _formatDate(it.fechaEntrega);
    final total = _formatMoney(it);
    final detailOpen = _detailExpanded[it.selectionKey] ?? false;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _approving ? null : () => _toggleSelected(it, !checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Stack(
            children: [
              // Contenido (sin reservar ancho en filas 2/3/...)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: reserva espacio a la derecha solo aquí
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: DefaultTextStyle.of(
                              context,
                            ).style.copyWith(decoration: TextDecoration.none),
                            children: [
                              TextSpan(
                                text: 'N° OC: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              TextSpan(
                                text: _ocIdentification(it.ctpdoc, it.ndocum),
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
                      const SizedBox(
                        width: 28,
                      ), // espacio para checkbox flotante
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
                  if (it.ordenTrabajo.trim().isNotEmpty ||
                      it.formaPago.trim().isNotEmpty) ...[
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
                  if (it.usuarioCreacion.trim().isNotEmpty ||
                      it.tipoServicio.trim().isNotEmpty) ...[
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
                              label: 'Servicio',
                              value: it.tipoServicio,
                              labelStyle: _detailLabelStyle(),
                              valueStyle: _detailValueStyle(),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  // Acordeón del detalle (contador estable desde el inicio)
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey('oc_aprob_detail_${it.selectionKey}'),
                      maintainState: true,
                      initiallyExpanded: detailOpen,
                      onExpansionChanged: (v) async {
                        setState(() {
                          _detailExpanded[it.selectionKey] = v;
                        });
                        // Solo fallback si realmente no vino detalle utilizable
                        if (v &&
                            (it.items.isEmpty || !_hasMeaningfulDetails(it))) {
                          await _ensureDetailLoaded(it);
                        }
                      },
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 6),
                      leading: _bullet(detailOpen, primaryColor),
                      title: Text(
                        'Detalle (${it.items.length})',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        detailOpen ? 'Contraer' : 'Ver ítems',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        if (_detailLoading.contains(it.selectionKey))
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (it.items.isEmpty || !_hasMeaningfulDetails(it))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Sin detalle disponible.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          )
                        else
                          ..._sortedDetailItems(
                            it,
                          ).map((d) => _buildDetailRow(primaryColor, d)),
                      ],
                    ),
                  ),
                ],
              ),

              // Checkbox flotante (no quita ancho al contenido)
              Positioned(
                top: -2,
                right: -2,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: checked,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: _approving
                          ? null
                          : (v) => _toggleSelected(it, v == true),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

  List<dynamic> _sortedDetailItems(OrdenCompraPendienteModel it) {
    final list = it.items.toList();
    list.sort((a, b) => a.norden.compareTo(b.norden));
    return list;
  }

  Widget _bullet(bool expanded, Color primaryColor) {
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
      color: isDark ? Colors.white70 : Colors.black54,
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

  // Detail field row: label + value with reserved space for empty values.

  // _chip removed (unused)

  Widget _buildBottomBar(Color primaryColor) {
    final canApprove = _selectedKeys.isNotEmpty && !_approving;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCount == 0
                          ? 'Nada seleccionado'
                          : 'Seleccionadas: $_selectedCount',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _selectedCount == 0
                          ? '—'
                          : 'Total: ${_selectedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: canApprove ? _approveSelected : null,
                  style: FilledButton.styleFrom(backgroundColor: primaryColor),
                  icon: _approving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_approving ? 'Aprobando...' : 'Aprobar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    final hasQuery = _query.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar por documento, proveedor, cliente, observación...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'Limpiar',
                  onPressed: () => setState(() => _query = ''),
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          isDense: true,
        ),
      ),
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
