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
  bool _approving = false;

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
        _selectedKeys.removeWhere(
          (k) => !list.any((x) => x.selectionKey == k),
        );
        for (final it in list) {
          final groupId =
              it.tipoDocumento.trim().isEmpty ? 'Sin tipo' : it.tipoDocumento.trim();
          _groupExpanded.putIfAbsent(groupId, () => true);
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
      final key = it.tipoDocumento.trim().isEmpty ? 'Sin tipo' : it.tipoDocumento.trim();
      map.putIfAbsent(key, () => []).add(it);
    }
    return map;
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

    final selected = _items.where((it) => _selectedKeys.contains(it.selectionKey)).toList();
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
          await _service.aprobar(ctpdoc: it.ctpdoc, ndocum: it.ndocum, norden: it.norden);
        } catch (e) {
          final msg = e.toString().replaceAll('Exception: ', '');
          failures.add('${it.ndocum} (${it.tipoDocumento}): $msg');
        }
      }

      if (!mounted) return;

      if (failures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aprobación completada.')),
        );
        _selectedKeys.clear();
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algunas aprobaciones fallaron (${failures.length}).')),
        );
        await _load();
      }
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final primaryColor = args?['primaryColor'] as Color? ?? const Color(0xFF0D47A1);
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
                                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Center(child: Text('No hay órdenes pendientes por aprobar.')),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: groupKeys.length,
                              itemBuilder: (context, i) {
                                final k = groupKeys[i];
                                final list = grouped[k]!;
                                return _buildGroup(k, k, list, primaryColor);
                              },
                            ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
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
            if (selected > 0)
              TextButton.icon(
                onPressed: _approving
                    ? null
                    : () => setState(() => _selectedKeys.clear()),
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
              ),
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
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
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
          textColor: Colors.black87,
          collapsedTextColor: Colors.black87,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '$title$ctpdocSuffix',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${list.length}',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            selectedInGroup == 0
                ? 'Total: $groupTotalLabel'
                : '$selectedInGroup seleccionada(s) · Total: $groupTotalLabel',
            style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
          ),
          trailing: Checkbox(
            value: allSelected ? true : (someSelected ? null : false),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: N° OC (izq) + Importe (der)
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: 'N° OC: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                TextSpan(
                                  text: it.ndocum.isEmpty ? '—' : it.ndocum,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
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
                    // Fila 2: Proveedor (usar TODO el ancho disponible)
                    _kvLine(label: 'Proveedor', value: it.proveedor),
                    const SizedBox(height: 4),
                    // Fila 3: Fechas en 2 columnas
                    Row(
                      children: [
                        Expanded(child: _kvLine(label: 'F.Emisión', value: emision)),
                        const SizedBox(width: 10),
                        Expanded(child: _kvLine(label: 'F.Entrega', value: entrega)),
                      ],
                    ),
                    if (it.cliente.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      // Fila 4: Cliente (usar TODO el ancho disponible)
                      _kvLine(label: 'Cliente', value: it.cliente.trim()),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: checked,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged:
                    _approving ? null : (v) => _toggleSelected(it, v == true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kvLine({required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black54;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: labelColor),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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
                      _selectedCount == 0 ? '—' : 'Total: ${_selectedTotal.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

