// lib/features/trabajadores/presentation/lista_trabajadores_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/services/vacaciones_permisos_service.dart';
import '../../../../data/models/trabajador_model.dart';
import 'detalle_trabajador_screen.dart';

class ListaTrabajadoresScreen extends StatefulWidget {
  const ListaTrabajadoresScreen({super.key});

  @override
  State<ListaTrabajadoresScreen> createState() => _ListaTrabajadoresScreenState();
}

class _ListaTrabajadoresScreenState extends State<ListaTrabajadoresScreen> {
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
    _cargarTrabajadores();
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
        _cargarTrabajadores(page: 1);
      } else {
        // Detectar si es código o nombre y usar el parámetro correcto
        _cargarTrabajadores(page: 1, search: query);
      }
    });
  }

  // Detectar si el texto parece un código de trabajador (ej: PR014793, TPE00088)
  bool _esCodigoTrabajador(String texto) {
    // Patrón: 2-3 letras seguidas de números (ej: PR014793, TPE00088)
    final codigoPattern = RegExp(r'^[A-Z]{2,3}\d+$', caseSensitive: false);
    return codigoPattern.hasMatch(texto.trim());
  }

  Future<void> _cargarTrabajadores({int page = 1, String? search}) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Determinar qué parámetro usar según el tipo de búsqueda
      String? codigo;
      String? nombre;
      
      if (search != null && search.isNotEmpty) {
        if (_esCodigoTrabajador(search)) {
          // Si parece un código, usar parámetro codigo
          codigo = search;
        } else {
          // Si no, usar parámetro nombre para búsqueda general
          nombre = search;
        }
      }

      final response = await _service.obtenerTrabajadores(
        page: page,
        limit: _limit,
        codigo: codigo,
        nombre: nombre,
      );
      
      setState(() {
        _trabajadores = response.items;
        _trabajadoresFiltrados = response.items;
        _currentPage = response.page;
        _totalPages = response.pages;
        _total = response.total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar trabajadores: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Trabajadores'),
        backgroundColor: const Color(0xFF4CCB9E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
                          _cargarTrabajadores(page: 1);
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
                    'Total: $_total trabajadores',
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
                                _cargarTrabajadores(
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
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No se encontraron trabajadores'
                                      : 'No hay trabajadores',
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
                              return _cargarTrabajadores(
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
                                      return _buildTrabajadorCard(trabajador);
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
                                                  _cargarTrabajadores(
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
                                                  _cargarTrabajadores(
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

  Widget _buildTrabajadorCard(TrabajadorModel trabajador) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4CCB9E).withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: const Color(0xFF4CCB9E),
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
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'DNI: ${trabajador.dni}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.contact_phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tel: ${((trabajador.telefono ?? '').trim().isEmpty ? '-' : (trabajador.telefono ?? '').trim())}'
                      '${((trabajador.correo ?? '').trim().isNotEmpty ? ' · ${(trabajador.correo ?? '').trim()}' : '')}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trabajador.descripcionArea.trim(),
                      style: TextStyle(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trabajador.descripcionSeccion.trim()} - ${trabajador.descripcionCargo.trim()}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
