import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../servicios/ruta_servicio.dart';

enum VistaMapa { todos, seleccionado, ninguno }

class SeleccionarDestinoPedidoPantalla extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SeleccionarDestinoPedidoPantalla({super.key, this.ubicacionInicial});

  @override
  State<SeleccionarDestinoPedidoPantalla> createState() =>
      _SeleccionarDestinoPedidoPantallaState();
}

class _SeleccionarDestinoPedidoPantallaState
    extends State<SeleccionarDestinoPedidoPantalla> {
  LatLng? _destinoSeleccionado;
  Map<String, dynamic>? _marcaSeleccionada;
  String _busqueda = '';
  LatLng? _miUbicacion;
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _marcasFiltradas = [];
  VistaMapa _vistaMapa = VistaMapa.todos; // Ojo abierto por defecto

  @override
  void initState() {
    super.initState();
    _destinoSeleccionado = widget.ubicacionInicial;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debes activar la ubicación en Ajustes')),
        );
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _miUbicacion = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  Future<void> _guardarNuevaMarca(LatLng punto) async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => _DialogoNombreMarca(),
    );
    if (nombre != null && nombre.isNotEmpty) {
      await RutaServicio().guardarRuta(nombre, punto.latitude, punto.longitude);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ubicación "$nombre" guardada')));
      setState(() {
        _marcaSeleccionada = {
          'nombre': nombre,
          'latitud': punto.latitude,
          'longitud': punto.longitude,
        };
        _destinoSeleccionado = punto;
      });
    }
  }

  void _onMapaTap(LatLng punto, List<Map<String, dynamic>> marcasGuardadas) {
    Map<String, dynamic>? marcaExistente;
    try {
      marcaExistente = marcasGuardadas.firstWhere(
        (m) =>
            ((m['latitud'] as double) - punto.latitude).abs() < 0.0001 &&
            ((m['longitud'] as double) - punto.longitude).abs() < 0.0001,
      );
    } catch (_) {
      marcaExistente = null;
    }

    if (_vistaMapa == VistaMapa.ninguno) {
      setState(() {
        _vistaMapa = VistaMapa.todos; // cambia al modo mostrar todos
      });
    }

    if (marcaExistente != null) {
      setState(() {
        _marcaSeleccionada = marcaExistente;
        _destinoSeleccionado = LatLng(
          marcaExistente!['latitud'] as double,
          marcaExistente['longitud'] as double,
        );
      });
    } else {
      setState(() {
        _destinoSeleccionado = punto;
        _marcaSeleccionada = null;
        // si estaba tachado, se cambia a todos
        if (_vistaMapa == VistaMapa.ninguno) _vistaMapa = VistaMapa.todos;
      });
    }
  }

  bool _esPuntoGuardado(LatLng punto, List<Map<String, dynamic>> marcas) {
    try {
      marcas.firstWhere(
        (m) =>
            ((m['latitud'] as double) - punto.latitude).abs() < 0.0001 &&
            ((m['longitud'] as double) - punto.longitude).abs() < 0.0001,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _getMarcaSeleccionadaEnLista(
    List<Map<String, dynamic>> marcas,
  ) {
    if (_marcaSeleccionada == null) return null;
    try {
      return marcas.firstWhere(
        (m) =>
            m['latitud'] == _marcaSeleccionada!['latitud'] &&
            m['longitud'] == _marcaSeleccionada!['longitud'],
      );
    } catch (_) {
      return null;
    }
  }

  void _cambiarVistaMapa() {
    setState(() {
      if (_vistaMapa == VistaMapa.todos) {
        _vistaMapa = VistaMapa.seleccionado;
      } else if (_vistaMapa == VistaMapa.seleccionado) {
        _vistaMapa = VistaMapa.ninguno;
      } else {
        _vistaMapa = VistaMapa.todos;
      }
    });
  }

  IconData get _iconoVista {
    switch (_vistaMapa) {
      case VistaMapa.todos:
        return Icons.remove_red_eye; // Ojo bien abierto
      case VistaMapa.seleccionado:
        return Icons.center_focus_strong; // Diferente, modo punto único
      case VistaMapa.ninguno:
        return Icons.visibility_off; // Tachado
    }
  }

  String get _tooltipVista {
    switch (_vistaMapa) {
      case VistaMapa.todos:
        return "Mostrar solo el punto seleccionado";
      case VistaMapa.seleccionado:
        return "Ocultar todos los puntos";
      case VistaMapa.ninguno:
        return "Mostrar todos los puntos";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar destino'),
        actions: [
          IconButton(
            icon: Icon(_iconoVista),
            tooltip: _tooltipVista,
            onPressed: _cambiarVistaMapa,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: RutaServicio().obtenerRutasGuardadas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var marcas = snapshot.data!;
          var marcasParaMapa = marcas;
          if (_busqueda.isNotEmpty) {
            marcasParaMapa = marcas
                .where(
                  (m) => (m['nombre'] ?? '').toLowerCase().contains(_busqueda),
                )
                .toList();
          }

          final List<Marker> markers = [];

          if (_vistaMapa == VistaMapa.todos) {
            // Mostrar todas las marcas guardadas
            markers.addAll(
              marcasParaMapa.map(
                (m) => Marker(
                  point: LatLng(m['latitud'], m['longitud']),
                  width: 120,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _marcaSeleccionada = m;
                        _destinoSeleccionado = LatLng(
                          m['latitud'],
                          m['longitud'],
                        );
                      });
                      _mapController.move(
                        LatLng(m['latitud'], m['longitud']),
                        16,
                      );
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.place,
                          color:
                              (_marcaSeleccionada != null &&
                                  _marcaSeleccionada!['latitud'] ==
                                      m['latitud'] &&
                                  _marcaSeleccionada!['longitud'] ==
                                      m['longitud'])
                              ? Colors.deepOrange
                              : Colors.blue,
                          size: 36,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                          child: Text(
                            m['nombre'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                              fontWeight:
                                  (_marcaSeleccionada != null &&
                                      _marcaSeleccionada!['latitud'] ==
                                          m['latitud'] &&
                                      _marcaSeleccionada!['longitud'] ==
                                          m['longitud'])
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            // Además, si hay un punto temporal (no guardado), muéstralo
            if (_destinoSeleccionado != null && _marcaSeleccionada == null) {
              markers.add(
                Marker(
                  point: _destinoSeleccionado!,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.location_on, color: Colors.red, size: 38),
                ),
              );
            }
          } else if (_vistaMapa == VistaMapa.seleccionado &&
              _destinoSeleccionado != null) {
            if (_marcaSeleccionada != null) {
              final marcaSeleccionadaEnLista = _getMarcaSeleccionadaEnLista(
                marcas,
              );
              if (marcaSeleccionadaEnLista != null) {
                markers.add(
                  Marker(
                    point: LatLng(
                      marcaSeleccionadaEnLista['latitud'],
                      marcaSeleccionadaEnLista['longitud'],
                    ),
                    width: 120,
                    height: 60,
                    child: Column(
                      children: [
                        Icon(Icons.place, color: Colors.deepOrange, size: 36),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                          child: Text(
                            marcaSeleccionadaEnLista['nombre'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else if (_destinoSeleccionado != null) {
              // Marca temporal (no guardada)
              markers.add(
                Marker(
                  point: _destinoSeleccionado!,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.location_on, color: Colors.red, size: 38),
                ),
              );
            }
          }
          // Vista ninguno: no muestra ningún punto (excepto mi ubicación)
          if (_miUbicacion != null) {
            markers.add(
              Marker(
                point: _miUbicacion!,
                width: 34,
                height: 34,
                child: Icon(Icons.my_location, color: Colors.green, size: 28),
              ),
            );
          }

          return Column(
            children: [
              // Buscador arriba
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Buscar ubicaciones",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (valor) {
                    // Si el ojo está tachado, cambia automáticamente al modo mostrar todos
                    if (_vistaMapa == VistaMapa.ninguno) {
                      setState(() => _vistaMapa = VistaMapa.todos);
                    }
                    setState(() {
                      _busqueda = valor.toLowerCase();
                      _marcasFiltradas = valor.trim().isEmpty
                          ? []
                          : marcas
                                .where(
                                  (m) => (m['nombre'] ?? '')
                                      .toLowerCase()
                                      .contains(_busqueda),
                                )
                                .toList();
                    });
                  },
                ),
              ),
              // Lista de coincidencias bajo el buscador
              if (_marcasFiltradas.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _marcasFiltradas.length,
                    itemBuilder: (context, i) {
                      final marca = _marcasFiltradas[i];
                      return ListTile(
                        leading: Icon(
                          Icons.place,
                          color:
                              (_marcaSeleccionada != null &&
                                  _marcaSeleccionada!['latitud'] ==
                                      marca['latitud'] &&
                                  _marcaSeleccionada!['longitud'] ==
                                      marca['longitud'])
                              ? Colors.deepOrange
                              : Colors.blue,
                        ),
                        title: Text(
                          marca['nombre'] ?? '',
                          style: TextStyle(
                            fontWeight:
                                (_marcaSeleccionada != null &&
                                    _marcaSeleccionada!['latitud'] ==
                                        marca['latitud'] &&
                                    _marcaSeleccionada!['longitud'] ==
                                        marca['longitud'])
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _marcaSeleccionada = Map<String, dynamic>.from(
                              marca,
                            );
                            _destinoSeleccionado = LatLng(
                              marca['latitud'],
                              marca['longitud'],
                            );
                            _busqueda = '';
                            _marcasFiltradas = [];
                            _vistaMapa = VistaMapa.seleccionado;
                          });

                          _mapController.move(
                            LatLng(marca['latitud'], marca['longitud']),
                            16,
                          );
                        },
                      );
                    },
                  ),
                ),
              // Mapa ocupa el resto del espacio
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _miUbicacion ??
                            _destinoSeleccionado ??
                            (marcas.isNotEmpty
                                ? LatLng(
                                    marcas.first['latitud'],
                                    marcas.first['longitud'],
                                  )
                                : LatLng(-1.0572, -79.0069)),
                        initialZoom: 14,
                        onTap: (tapPosition, latlng) =>
                            _onMapaTap(latlng, marcas),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.tu.app',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                    // Botón "mi ubicación" flotante
                    Positioned(
                      right: 15,
                      bottom: 130,
                      child: FloatingActionButton(
                        mini: true,
                        heroTag: "gps",
                        onPressed: () {
                          if (_miUbicacion != null) {
                            _mapController.move(_miUbicacion!, 16);
                          } else {
                            _getCurrentLocation();
                          }
                        },
                        child: Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Builder(
          builder: (context) => ElevatedButton.icon(
            icon: Icon(Icons.check),
            label: Text(
              _marcaSeleccionada != null
                  ? 'Usar "${_marcaSeleccionada!['nombre']}" como destino'
                  : 'Confirmar selección de destino',
            ),
            onPressed: _destinoSeleccionado == null
                ? null
                : () async {
                    final marcasGuardadas = await RutaServicio()
                        .obtenerRutasGuardadas()
                        .first;
                    final esGuardada = _esPuntoGuardado(
                      _destinoSeleccionado!,
                      marcasGuardadas,
                    );
                    String? nombreMarca;
                    if (!esGuardada) {
                      final guardar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("¿Guardar ubicación?"),
                          content: Text(
                            "¿Quieres guardar este punto como una marca para futuros pedidos?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("No"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("Sí"),
                            ),
                          ],
                        ),
                      );
                      if (guardar == true) {
                        nombreMarca = await showDialog<String>(
                          context: context,
                          builder: (context) => _DialogoNombreMarca(),
                        );
                        if (nombreMarca != null && nombreMarca.isNotEmpty) {
                          await RutaServicio().guardarRuta(
                            nombreMarca,
                            _destinoSeleccionado!.latitude,
                            _destinoSeleccionado!.longitude,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ubicación "$nombreMarca" guardada',
                              ),
                            ),
                          );
                        }
                      }
                    }
                    if (_marcaSeleccionada != null &&
                        _marcaSeleccionada!['id'] != null) {
                      await RutaServicio().incrementarUsoMarca(
                        _marcaSeleccionada!['id'],
                      );
                    }
                    Navigator.pop(context, {
                      'latitud': _destinoSeleccionado!.latitude,
                      'longitud': _destinoSeleccionado!.longitude,
                      'nombre': _marcaSeleccionada?['nombre'] ?? nombreMarca,
                      'id': _marcaSeleccionada?['id'], // <--- esto es CLAVE
                    });
                  },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 18),
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogoNombreMarca extends StatefulWidget {
  @override
  State<_DialogoNombreMarca> createState() => _DialogoNombreMarcaState();
}

class _DialogoNombreMarcaState extends State<_DialogoNombreMarca> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Nombre para esta ubicación"),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "Ej: Domicilio cliente, Bodega...",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text("Guardar"),
        ),
      ],
    );
  }
}
