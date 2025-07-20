import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../servicios/ruta_servicio.dart';

class GestionarMarcasMapaPantalla extends StatefulWidget {
  const GestionarMarcasMapaPantalla({super.key});

  @override
  State<GestionarMarcasMapaPantalla> createState() =>
      _GestionarMarcasMapaPantallaState();
}

class _GestionarMarcasMapaPantallaState
    extends State<GestionarMarcasMapaPantalla> {
  String _busqueda = '';
  List<Map<String, dynamic>> _marcasFiltradas = [];

  void _filtrar(List<Map<String, dynamic>> marcas, String valor) {
    setState(() {
      _busqueda = valor.toLowerCase();
      _marcasFiltradas = valor.trim().isEmpty
          ? []
          : marcas
                .where(
                  (m) => (m['nombre'] ?? '').toLowerCase().contains(_busqueda),
                )
                .toList();
    });
  }

  Future<void> _editarNombreMarca(Map<String, dynamic> marca) async {
    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (context) =>
          _DialogoEditarNombre(nombreInicial: marca['nombre']),
    );
    if (nuevoNombre != null &&
        nuevoNombre.isNotEmpty &&
        nuevoNombre != marca['nombre']) {
      await RutaServicio().editarNombreMarca(marca['id'], nuevoNombre);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nombre actualizado')));
      setState(() {});
    }
  }

  Future<void> _moverUbicacionMarca(Map<String, dynamic> marca) async {
    final LatLng? nuevaUbicacion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SeleccionarNuevaUbicacionMapa(
          ubicacionInicial: LatLng(marca['latitud'], marca['longitud']),
        ),
      ),
    );
    if (nuevaUbicacion != null) {
      await RutaServicio().editarUbicacionMarca(
        marca['id'],
        nuevaUbicacion.latitude,
        nuevaUbicacion.longitude,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ubicación actualizada')));
      setState(() {});
    }
  }

  Future<void> _eliminarMarca(Map<String, dynamic> marca) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿Eliminar ubicación?"),
        content: Text('¿Seguro que quieres eliminar "${marca['nombre']}"?'),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("Eliminar"),
          ),
        ],
      ),
    );
    if (seguro == true) {
      await RutaServicio().eliminarMarca(marca['id']);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ubicación eliminada')));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestionar Ubicaciones Guardadas")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: RutaServicio().obtenerRutasGuardadas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final marcas = snapshot.data!;
          final marcasLista = _busqueda.isEmpty ? marcas : _marcasFiltradas;
          return Column(
            children: [
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
                  onChanged: (valor) => _filtrar(marcas, valor),
                ),
              ),
              Expanded(
                child: marcasLista.isEmpty
                    ? Center(child: Text("No hay ubicaciones guardadas."))
                    : ListView.separated(
                        itemCount: marcasLista.length,
                        separatorBuilder: (_, __) => Divider(height: 0),
                        itemBuilder: (context, i) {
                          final marca = marcasLista[i];
                          return ListTile(
                            leading: Icon(Icons.place, color: Colors.blue),
                            title: Text(marca['nombre'] ?? ''),
                            subtitle: Text(
                              "Lat: ${marca['latitud'].toStringAsFixed(6)}, Lng: ${marca['longitud'].toStringAsFixed(6)}",
                              style: TextStyle(fontSize: 13),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Editar nombre',
                                  onPressed: () => _editarNombreMarca(marca),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: Colors.teal,
                                  ),
                                  tooltip: 'Mover ubicación',
                                  onPressed: () => _moverUbicacionMarca(marca),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _eliminarMarca(marca),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogoEditarNombre extends StatefulWidget {
  final String nombreInicial;
  const _DialogoEditarNombre({required this.nombreInicial});
  @override
  State<_DialogoEditarNombre> createState() => _DialogoEditarNombreState();
}

class _DialogoEditarNombreState extends State<_DialogoEditarNombre> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.nombreInicial);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Editar nombre"),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: "Nuevo nombre"),
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

// Mapa para editar la ubicación de una marca
class _SeleccionarNuevaUbicacionMapa extends StatefulWidget {
  final LatLng ubicacionInicial;
  const _SeleccionarNuevaUbicacionMapa({required this.ubicacionInicial});
  @override
  State<_SeleccionarNuevaUbicacionMapa> createState() =>
      _SeleccionarNuevaUbicacionMapaState();
}

class _SeleccionarNuevaUbicacionMapaState
    extends State<_SeleccionarNuevaUbicacionMapa> {
  late LatLng _punto;
  final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    _punto = widget.ubicacionInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Seleccionar nueva ubicación")),
      body: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: _punto,
          initialZoom: 16,
          onTap: (tapPos, latlng) {
            setState(() => _punto = latlng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.tu.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _punto,
                width: 40,
                height: 40,
                child: Icon(Icons.location_on, color: Colors.red, size: 38),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ElevatedButton.icon(
          icon: Icon(Icons.check),
          label: Text("Guardar nueva ubicación"),
          onPressed: () => Navigator.pop(context, _punto),
        ),
      ),
    );
  }
}
