import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class PedidoServicio {
  final _pedidos = FirebaseFirestore.instance.collection('pedidos');

  Stream<List<Map<String, dynamic>>> obtenerPedidos() {
    return _pedidos.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'ubicacion': data['ubicacion'] != null
              ? LatLng(
                  data['ubicacion']['latitud'],
                  data['ubicacion']['longitud'],
                )
              : null,
          'nombre': data['nombre'],
          'ticketsId': data['ticketsId'], // Aquí traemos ticketsId
        };
      }).toList(),
    );
  }
}

class MarcadorChoferWidget extends StatefulWidget {
  final String nombre;
  final String? fotoUrl;
  final bool esActivo;
  final bool esPedido;
  final VoidCallback onTap;

  const MarcadorChoferWidget({
    required this.nombre,
    this.fotoUrl,
    required this.onTap,
    this.esActivo = false,
    this.esPedido = false,
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
      duration: const Duration(milliseconds: 1300),
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
    if (widget.esPedido) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
            const SizedBox(height: 4),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.esActivo
                        ? Colors.blueAccent
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: widget.fotoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(widget.fotoUrl!),
                        radius: 22,
                      )
                    : const CircleAvatar(
                        radius: 22,
                        child: Icon(Icons.person, size: 24),
                      ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VerChoferesConRutasPantalla extends StatefulWidget {
  const VerChoferesConRutasPantalla({super.key});

  @override
  State<VerChoferesConRutasPantalla> createState() =>
      _VerChoferesConRutasPantallaState();
}

class _VerChoferesConRutasPantallaState
    extends State<VerChoferesConRutasPantalla> {
  List<Marker> _marcadoresChoferes = [];
  List<Marker> _marcadoresPedidos = [];
  List<Polyline> _rutas = [];
  final PedidoServicio _pedidoServicio = PedidoServicio();

  @override
  void initState() {
    super.initState();
    _obtenerChoferesConUbicacion();
    _obtenerPedidosConUbicacion();
  }

  Future<void> _calcularRuta(LatLng origen, LatLng destino) async {
    final apiKey = 'AIzaSyBj19l1JjUGzZeREbUq7iV4Tohea1PfqjQ';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origen.latitude},${origen.longitude}&destination=${destino.latitude},${destino.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];
        final decodedPoints = _decodePolyline(polyline);

        setState(() {
          _rutas = [
            Polyline(
              points: decodedPoints,
              strokeWidth: 4.0,
              color: Colors.blue,
            ),
          ];
        });
      }
    } else {
      print('Error al obtener la ruta: ${response.statusCode}');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b = 0;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
        index++;
      } while (b >= 0x20);

      int deltaLat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
        index++;
      } while (b >= 0x20);

      int deltaLng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += deltaLng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  // Calcular la distancia entre dos puntos
  double _calcularDistancia(LatLng punto1, LatLng punto2) {
    const radioTierra = 6371000; // Radio de la Tierra en metros
    var lat1 = _degToRad(punto1.latitude);
    var lat2 = _degToRad(punto2.latitude);
    var deltaLat = _degToRad(punto2.latitude - punto1.latitude);
    var deltaLon = _degToRad(punto2.longitude - punto1.longitude);

    var a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radioTierra * c; // Retorna la distancia en metros
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  void _obtenerChoferesConUbicacion() {
    FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'chofer')
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .listen((snapshot) {
          final nuevosMarcadores = snapshot.docs.map((doc) {
            final ubicacion = doc['ubicacion'];
            final nombre = doc['nombre'];
            final punto = LatLng(ubicacion['latitude'], ubicacion['longitude']);
            return Marker(
              point: punto,
              width: 75,
              height: 75,
              child: MarcadorChoferWidget(
                nombre: nombre,
                esActivo: true,
                esPedido: false,
                onTap: () => print("Chofer $nombre seleccionado"),
              ),
            );
          }).toList();

          setState(() {
            _marcadoresChoferes = nuevosMarcadores;
          });
        });
  }

  void _obtenerPedidosConUbicacion() {
    _pedidoServicio.obtenerPedidos().listen((pedidos) {
      final nuevosMarcadoresPedidos = <Marker>[];
      List<Map<String, dynamic>> pedidosOrdenados = [];

      for (var pedido in pedidos) {
        final ubicacionData = pedido['ubicacion'];
        final ticketsId = pedido['ticketsId'] ?? "Sin ID";
        if (ubicacionData != null) {
          LatLng ubicacion;
          if (ubicacionData is LatLng) {
            ubicacion = ubicacionData;
          } else if (ubicacionData is Map) {
            ubicacion = LatLng(
              ubicacionData['latitud'] ?? ubicacionData['latitude'],
              ubicacionData['longitud'] ?? ubicacionData['longitude'],
            );
          } else {
            continue;
          }

          // Calcular la distancia entre el chofer y el pedido
          final distancia = _calcularDistancia(
            _marcadoresChoferes[0]
                .point, // Asumimos que el primer chofer es el actual
            ubicacion,
          );

          pedidosOrdenados.add({'pedido': pedido, 'distancia': distancia});
        }
      }

      // Ordenar los pedidos por la distancia más cercana
      pedidosOrdenados.sort((a, b) => a['distancia'].compareTo(b['distancia']));

      // Ahora, agrega los marcadores de los pedidos ordenados
      for (var pedido in pedidosOrdenados) {
        final ubicacion = pedido['pedido']['ubicacion'];
        final ticketsId = pedido['pedido']['ticketsId'] ?? "Sin ID";

        nuevosMarcadoresPedidos.add(
          Marker(
            point: ubicacion,
            width: 60,
            height: 60,
            child: MarcadorChoferWidget(
              nombre: ticketsId,
              esActivo: false,
              esPedido: true,
              onTap: () {
                print("Pedido $ticketsId seleccionado");
                _calcularRuta(_marcadoresChoferes[0].point, ubicacion);
              },
            ),
          ),
        );
      }

      setState(() {
        _marcadoresPedidos = nuevosMarcadoresPedidos;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ver Choferes con Rutas"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {
              'accessToken':
                  'pk.eyJ1IjoicHJveWVjdG9zdXRjMjAyNSIsImEiOiJjbWRlM3ZibGowYmc5Mm1wd21xcWZxNGd5In0.ouOaou0lRTvJxf3W7IXlHQ',
              'id': 'mapbox/streets-v11',
            },
          ),
          MarkerLayer(markers: [..._marcadoresChoferes, ..._marcadoresPedidos]),
          PolylineLayer(polylines: _rutas),
        ],
      ),
    );
  }
}
