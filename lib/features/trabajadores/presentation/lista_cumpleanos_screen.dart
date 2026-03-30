// lib/features/trabajadores/presentation/lista_cumpleanos_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/models/trabajador_model.dart';
import 'detalle_trabajador_screen.dart';

class ListaCumpleanosScreen extends StatefulWidget {
  const ListaCumpleanosScreen({super.key});

  @override
  State<ListaCumpleanosScreen> createState() => _ListaCumpleanosScreenState();
}

class _ListaCumpleanosScreenState extends State<ListaCumpleanosScreen> {
  final VacacionesPermisosService _service = VacacionesPermisosService();
  final TextEditingController _searchController = TextEditingController();
  
  List<TrabajadorModel> _trabajadores = [];
  List<TrabajadorModel> _trabajadoresFiltrados = [];
  bool _isLoading = true;
  String _error = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _limit = 20;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _cargarCumpleanos();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Cuando hay búsqueda, recargar desde el backend con el parámetro de búsqueda
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        // Si se limpia la búsqueda, volver a cargar sin filtro
        _cargarCumpleanos(page: 1);
      } else {
        // Detectar si es código o nombre y usar el parámetro correcto
        _cargarCumpleanos(page: 1, search: query);
      }
    });
  }

  // Detectar si el texto parece un código de trabajador (ej: PR014793, TPE00088)
  bool _esCodigoTrabajador(String texto) {
    // Patrón: 2-3 letras seguidas de números (ej: PR014793, TPE00088)
    final codigoPattern = RegExp(r'^[A-Z]{2,3}\d+$', caseSensitive: false);
    return codigoPattern.hasMatch(texto.trim());
  }

  /// Filtra la lista por texto de búsqueda: nombre, apellido, código, DNI, área, etc.
  /// Si el usuario escribe varias palabras, todas deben aparecer en el nombre completo.
  List<TrabajadorModel> _filtrarPorBusqueda(
    List<TrabajadorModel> lista,
    String query,
  ) {
    if (query.trim().isEmpty) return lista;
    final q = query.trim().toLowerCase();
    final palabras = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    return lista.where((t) {
      final nombreCompleto = (t.nombreCompleto).toLowerCase();
      final codigo = (t.codigoTrabajador).toLowerCase();
      final dni = (t.dni).toLowerCase();
      final area = (t.descripcionArea).toLowerCase();
      final seccion = (t.descripcionSeccion).toLowerCase();
      final cargo = (t.descripcionCargo).toLowerCase();

      // Si hay varias palabras, todas deben estar en el nombre completo (nombre o apellido)
      if (palabras.length > 1) {
        return palabras.every((palabra) => nombreCompleto.contains(palabra));
      }

      // Una sola palabra: buscar en cualquier campo
      return nombreCompleto.contains(q) ||
          codigo.contains(q) ||
          dni.contains(q) ||
          area.contains(q) ||
          seccion.contains(q) ||
          cargo.contains(q);
    }).toList();
  }

  Future<void> _cargarCumpleanos({int page = 1, String? search}) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Determinar qué parámetro usar según el tipo de búsqueda (igual que en trabajadores)
      String? codigo;
      String? nombre;

      if (search != null && search.isNotEmpty) {
        if (_esCodigoTrabajador(search)) {
          codigo = search;
        } else {
          nombre = search;
        }
      }

      final response = await _service.obtenerCumpleanosHoy(
        page: page,
        limit: _limit,
        codigo: codigo,
        nombre: nombre,
      );

      final queryActual = _searchController.text.trim();
      final itemsFiltrados = _filtrarPorBusqueda(response.items, queryActual);

      setState(() {
        _trabajadores = response.items;
        _trabajadoresFiltrados = itemsFiltrados;
        _currentPage = response.page;
        _totalPages = response.pages;
        _total = response.total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cumpleaños: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd/MM').format(DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cumpleaños de Hoy'),
        backgroundColor: const Color(0xFF4CCB9E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner de cumpleaños
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CCB9E).withOpacity(0.8),
                  const Color(0xFF99EECC).withOpacity(0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Feliz Cumpleaños!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hoy $today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Buscador
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código, DNI, área, sección o cargo...',
                prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _cargarCumpleanos(page: 1);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Información de paginación
          if (!_isLoading && _error.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: $_total cumpleañeros',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Página $_currentPage de $_totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              _error,
                              style: TextStyle(color: Colors.red[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final query = _searchController.text.trim();
                                _cargarCumpleanos(
                                  search: query.isEmpty ? null : query,
                                );
                              },
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _trabajadoresFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cake_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No se encontraron cumpleañeros'
                                      : 'No hay cumpleaños hoy',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () {
                              final query = _searchController.text.trim();
                              return _cargarCumpleanos(
                                page: _currentPage,
                                search: query.isEmpty ? null : query,
                              );
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _trabajadoresFiltrados.length,
                                    itemBuilder: (context, index) {
                                      final trabajador = _trabajadoresFiltrados[index];
                                      return _buildCumpleaneroCard(trabajador);
                                    },
                                  ),
                                ),
                                // Controles de paginación
                                if (_totalPages > 1)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      border: Border(
                                        top: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 1
                                              ? () {
                                                  final query = _searchController.text.trim();
                                                  _cargarCumpleanos(
                                                    page: _currentPage - 1,
                                                    search: query.isEmpty ? null : query,
                                                  );
                                                }
                                              : null,
                                        ),
                                        Text(
                                          'Página $_currentPage de $_totalPages',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < _totalPages
                                              ? () {
                                                  final query = _searchController.text.trim();
                                                  _cargarCumpleanos(
                                                    page: _currentPage + 1,
                                                    search: query.isEmpty ? null : query,
                                                  );
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCumpleaneroCard(TrabajadorModel trabajador) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF4CCB9E).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleTrabajadorScreen(trabajador: trabajador),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CCB9E),
                      const Color(0xFF99EECC),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.cake,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trabajador.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${trabajador.codigoTrabajador}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trabajador.descripcionArea.trim(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trabajador.descripcionSeccion.trim(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
