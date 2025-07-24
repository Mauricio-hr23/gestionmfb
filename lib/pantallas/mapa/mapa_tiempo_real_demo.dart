import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// --- Servicio de Localización (solo mientras la app está en uso)
class LocalizacionServicio {
  StreamSubscription<Position>? _subs;
  void iniciarActualizacionContinua(String userId) {
    _subs?.cancel();
    _subs =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Mínimo movimiento para actualizar (en metros)
          ),
        ).listen((pos) {
          FirebaseFirestore.instance.collection('usuarios').doc(userId).update({
            'ubicacion': {'latitude': pos.latitude, 'longitude': pos.longitude},
          });
        });
  }

  void detenerActualizacion() {
    _subs?.cancel();
  }
}

// --- Servicio para obtener choferes activos con ubicación
class ChoferesServicio {
  final _usuarios = FirebaseFirestore.instance.collection('usuarios');

  Stream<List<Map<String, dynamic>>> obtenerChoferesConUbicacion() {
    return _usuarios
        .where('rol', isEqualTo: 'chofer')
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data().containsKey('ubicacion'))
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'nombre': data['nombre'],
                  'ubicacion': data['ubicacion'],
                  'foto_url': data.containsKey('foto_url')
                      ? data['foto_url']
                      : null,
                  'telefono': data.containsKey('telefono')
                      ? data['telefono']
                      : null,
                };
              })
              .toList(),
        );
  }
}

// --- Widget marcador con efecto pulse/glow si es el usuario actual
class MarcadorChoferWidget extends StatefulWidget {
  final String nombre;
  final String? fotoUrl;
  final bool esActivo;
  final VoidCallback onTap;

  const MarcadorChoferWidget({
    required this.nombre,
    this.fotoUrl,
    required this.onTap,
    this.esActivo = false,
    super.key,
  });

  @override
  State<MarcadorChoferWidget> createState() => _MarcadorChoferWidgetState();
}

class _MarcadorChoferWidgetState extends State<MarcadorChoferWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1300),
    )..repeat(reverse: false);
    _anim = Tween<double>(
      begin: 1,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (widget.esActivo)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 54 * _anim.value,
                height: 54 * _anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(
                    0.25 * (2 - _anim.value),
                  ),
                ),
              );
            },
          ),
        GestureDetector(
          onTap: widget.onTap,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.esActivo
                        ? Colors.blueAccent
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: widget.fotoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(widget.fotoUrl!),
                        radius: 22,
                      )
                    : CircleAvatar(
                        radius: 22,
                        child: Icon(Icons.person, size: 24),
                      ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Text(
                  widget.nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Pantalla principal del mapa en tiempo real
class MapaTiempoRealDemo extends StatefulWidget {
  final String userId; // Pasa el id del usuario actual

  const MapaTiempoRealDemo({super.key, required this.userId});

  @override
  State<MapaTiempoRealDemo> createState() => _MapaTiempoRealDemoState();
}

class _MapaTiempoRealDemoState extends State<MapaTiempoRealDemo> {
  final ChoferesServicio _choferesServicio = ChoferesServicio();
  final LocalizacionServicio _localizacionServicio = LocalizacionServicio();

  @override
  void initState() {
    super.initState();
    // Inicia la actualización automática de ubicación
    _localizacionServicio.iniciarActualizacionContinua(widget.userId);
  }

  @override
  void dispose() {
    _localizacionServicio.detenerActualizacion();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Choferes'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _choferesServicio.obtenerChoferesConUbicacion(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final choferes = snapshot.data!;
          if (choferes.isEmpty) {
            return Center(child: Text('No hay choferes activos en el mapa.'));
          }

          final String choferId =
              ModalRoute.of(context)!.settings.arguments as String;

          final chofer = choferes.firstWhere(
            (ch) => ch['id'] == choferId,
            orElse: () =>
                <
                  String,
                  dynamic
                >{}, // Retorna un mapa vacío si no encuentra el chofer
          );

          final ubicacionChofer = chofer['ubicacion'];
          final LatLng centro = LatLng(
            ubicacionChofer['latitude'],
            ubicacionChofer['longitude'],
          );

          Future<Map<String, dynamic>> obtenerUbicacionPedido(
            String ticketId,
          ) async {
            // Simula una consulta a base de datos o API
            await Future.delayed(Duration(seconds: 1));
            return {'latitud': -12.0464, 'longitud': -77.0428};
          }

          // ...existing code...
          final String ticketId =
              'ID_DEL_TICKET'; // Reemplaza con el ID real del ticket
          final Future<Map<String, dynamic>> pedidoUbicacion =
              obtenerUbicacionPedido(ticketId);

          return FutureBuilder<Map<String, dynamic>>(
            future: pedidoUbicacion,
            builder: (context, pedidoSnapshot) {
              if (pedidoSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (pedidoSnapshot.hasError) {
                return Center(child: Text('Error: ${pedidoSnapshot.error}'));
              }

              final ubicacionPedido = pedidoSnapshot.data;
              if (ubicacionPedido == null) {
                return Center(
                  child: Text('No se encontró la ubicación del pedido.'),
                );
              }
              final LatLng ubicacionEntrega = LatLng(
                ubicacionPedido['latitud'],
                ubicacionPedido['longitud'],
              );
              // ...existing code...

              return FlutterMap(
                options: MapOptions(initialCenter: centro, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      // Marcador del chofer
                      Marker(
                        width: 75,
                        height: 75,
                        point: LatLng(
                          ubicacionChofer['latitude'],
                          ubicacionChofer['longitude'],
                        ),
                        child: MarcadorChoferWidget(
                          nombre: chofer['nombre'],
                          fotoUrl: chofer['foto_url'],
                          esActivo: chofer['id'] == choferId,
                          onTap: () {
                            // Mostrar más detalles del chofer si es necesario
                          },
                        ),
                      ),
                      // Marcador del punto de entrega
                      Marker(
                        width: 75,
                        height: 75,
                        point: ubicacionEntrega,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ), // O el ícono que prefieras
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
