import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../servicios/ruta_servicio.dart'; // Servicio para obtener la ruta

class RutaPantalla extends StatefulWidget {
  final String choferId;
  const RutaPantalla({super.key, required this.choferId});

  @override
  State<RutaPantalla> createState() => _RutaPantallaState();
}

class _RutaPantallaState extends State<RutaPantalla> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    // Obtener los pedidos de un chofer
    RutaServicio().obtenerPedidosPorChofer(widget.choferId).then((pedidos) {
      // Luego, obtener la ruta entre esos puntos
      RutaServicio().obtenerRutaDeChofer(pedidos).then((route) {
        // Agregar la ruta al mapa
        _agregarRuta(route, pedidos);
      });
    });
  }

  void _agregarRuta(List<dynamic> steps, List<Map<String, dynamic>> pedidos) {
    List<LatLng> points = [];
    for (var step in steps) {
      final lat = step['end_location']['lat'];
      final lng = step['end_location']['lng'];
      points.add(LatLng(lat, lng));
    }
    setState(() {
      // Agregar la ruta en el mapa
      _polylines.add(
        Polyline(points: points, color: Colors.blue, strokeWidth: 5),
      );

      // Agregar los marcadores para las paradas intermedias (puntos de entrega)
      for (var pedido in pedidos) {
        final point = LatLng(pedido['latitud'], pedido['longitud']);
        _markers.add(
          Marker(
            point: point,
            width: 30.0,
            height: 30.0,
            child: Icon(Icons.location_on, color: Colors.red),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ruta Asignada al Chofer")),
      body: FlutterMap(
        options: MapOptions(
          // No se usan `center` ni `zoom` aquí
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers.toList()),
          PolylineLayer(polylines: _polylines.toList()),
        ],
      ),
    );
  }
}
