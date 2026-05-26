import 'dart:convert';
import 'auth_service.dart';
import '../../core/config/app_config.dart';

import '../models/orden_compra_pendiente_model.dart';
import '../models/orden_compra_consulta_model.dart';
import '../models/orden_compra_consulta_item_model.dart';

class OrdenesCompraService {
  // Ruta general del API (misma que auth)
  String get _baseUrl => AppConfig().baseUrl;

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    return <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Future<List<OrdenCompraPendienteModel>> obtenerPendientes() async {
    final uri = Uri.parse('$_baseUrl/ordenes-compra/pendientes');
    final response = await _authService.authenticatedGet(
      uri,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        // Compatibilidad con 2 formatos:
        // 1) Lista plana: cada elemento es una "fila" con cabecera + ítem
        // 2) Lista de cabeceras: cada elemento trae un array en `items`/`detalle`
        final first = decoded.isNotEmpty ? decoded.first : null;
        final looksLikeHeaderList = first is Map<String, dynamic> &&
            ((first['items'] ?? first['detalle'] ?? first['detalle_items'])
                    is List);

        if (looksLikeHeaderList) {
          final result = <OrdenCompraPendienteModel>[];
          for (final row in decoded) {
            if (row is! Map<String, dynamic>) continue;
            final header = OrdenCompraPendienteModel.fromJson(row);

            final rawItems = row['items'] ??
                row['detalle'] ??
                row['detalle_items'] ??
                const <dynamic>[];
            final items = <OrdenCompraConsultaItemModel>[];
            if (rawItems is List) {
              for (final it in rawItems) {
                if (it is Map<String, dynamic>) {
                  items.add(OrdenCompraConsultaItemModel.fromJson(it));
                }
              }
            }

            result.add(header.copyWithItems(items));
          }
          return result;
        }

        // Formato 1: lista plana (cabecera + ítem en el mismo objeto)
        final headers = <String, OrdenCompraPendienteModel>{};
        final itemsByKey = <String, List<OrdenCompraConsultaItemModel>>{};
        for (final row in decoded) {
          if (row is! Map<String, dynamic>) continue;

          final h = OrdenCompraPendienteModel.fromJson(row);
          headers.putIfAbsent(h.selectionKey, () => h);
          itemsByKey.putIfAbsent(h.selectionKey, () => []);

          final item = OrdenCompraConsultaItemModel.fromJson(row);
          // Evitar duplicados por orden_detalle (norden en el item)
          final list = itemsByKey[h.selectionKey]!;
          if (!list.any((x) => x.norden == item.norden)) {
            list.add(item);
          }
        }

        final result = <OrdenCompraPendienteModel>[];
        for (final e in headers.entries) {
          final k = e.key;
          final hdr = e.value;
          final its = itemsByKey[k] ?? const <OrdenCompraConsultaItemModel>[];
          result.add(hdr.copyWithItems(its));
        }
        return result;
      }
      throw Exception('Formato inesperado al listar pendientes');
    }

    if (response.statusCode == 401) throw Exception('SESSION_EXPIRED');
    throw Exception(
      'Error al listar pendientes (${response.statusCode}): ${response.body}',
    );
  }

  Future<void> aprobar({
    required String ctpdoc,
    required String ndocum,
    required int norden,
  }) async {
    final uri = Uri.parse('$_baseUrl/ordenes-compra/aprobar');
    final response = await _authService.authenticatedPost(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'ctpdoc': ctpdoc,
        'ndocum': ndocum,
        'norden': norden,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 401) throw Exception('SESSION_EXPIRED');

    // Si el backend devuelve JSON {detail: ...} lo mostramos, sino el body crudo.
    try {
      final body = json.decode(response.body);
      if (body is Map && body['detail'] != null) {
        throw Exception(body['detail'].toString());
      }
    } catch (_) {}

    throw Exception(
      'Error al aprobar (${response.statusCode}): ${response.body}',
    );
  }

  Future<List<OrdenCompraConsultaModel>> consultar({
    String? ctpdoc,
    String? ndocum,
    String? femisi, // YYYY-MM-DD
    String? cliente,
    String? proveedor,
    int? limit,
  }) async {
    final qp = <String, String>{};
    if (ctpdoc != null && ctpdoc.trim().isNotEmpty) qp['ctpdoc'] = ctpdoc.trim();
    if (ndocum != null && ndocum.trim().isNotEmpty) qp['ndocum'] = ndocum.trim();
    if (femisi != null && femisi.trim().isNotEmpty) qp['femisi'] = femisi.trim();
    if (cliente != null && cliente.trim().isNotEmpty) qp['cliente'] = cliente.trim();
    if (proveedor != null && proveedor.trim().isNotEmpty) qp['proveedor'] = proveedor.trim();
    if (limit != null) qp['limit'] = limit.toString();

    final uri = Uri.parse('$_baseUrl/ordenes-compra/consulta').replace(queryParameters: qp.isEmpty ? null : qp);
    final response = await _authService.authenticatedGet(
      uri,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        // El endpoint devuelve filas planas (una fila por item).
        // Agrupamos por (ctpdoc, ndocum) y acumulamos items.
        final headers = <String, OrdenCompraConsultaModel>{};
        final itemsByKey = <String, List<OrdenCompraConsultaItemModel>>{};

        for (final row in decoded) {
          if (row is! Map<String, dynamic>) continue;
          final header = OrdenCompraConsultaModel.headerFromFlatRow(row);
          final key = header.key;
          headers.putIfAbsent(key, () => header);
          itemsByKey.putIfAbsent(key, () => []);

          // Cada fila contiene un item.
          final item = OrdenCompraConsultaItemModel.fromJson(row);
          itemsByKey[key]!.add(item);
        }

        final result = <OrdenCompraConsultaModel>[];
        for (final e in headers.entries) {
          final k = e.key;
          final hdr = e.value;
          final its = itemsByKey[k] ?? const <OrdenCompraConsultaItemModel>[];
          result.add(hdr.copyWithItems(its));
        }

        return result;
      }
      throw Exception('Formato inesperado al consultar órdenes');
    }

    if (response.statusCode == 401) throw Exception('SESSION_EXPIRED');
    throw Exception(
      'Error al consultar órdenes (${response.statusCode}): ${response.body}',
    );
  }
}

