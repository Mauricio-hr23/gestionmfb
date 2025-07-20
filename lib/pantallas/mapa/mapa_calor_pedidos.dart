import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../servicios/pedido_servicio.dart';

class MapaCalorPedidosPantalla extends StatelessWidget {
  const MapaCalorPedidosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mapa de calor de pedidos")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: PedidoServicio().obtenerDestinosPedidos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final destinos = snapshot.data!;
          if (destinos.isEmpty) {
            return Center(child: Text("No hay pedidos registrados."));
          }

          // Agrupa por lat/lng, cuenta repeticiones
          final Map<String, int> conteo = {};
          final Map<String, Map<String, dynamic>> ejemploDestino = {};
          for (var d in destinos) {
            final clave = "${d['latitud']},${d['longitud']}";
            conteo[clave] = (conteo[clave] ?? 0) + 1;
            ejemploDestino[clave] = d;
          }

          // Determina el máximo para el tamaño
          final maxCount = conteo.values.fold<int>(1, (a, b) => a > b ? a : b);

          return FlutterMap(
            options: MapOptions(
              initialCenter: destinos.isNotEmpty
                  ? LatLng(destinos[0]['latitud'], destinos[0]['longitud'])
                  : LatLng(-1.0572, -79.0069),
              initialZoom: 13,
              minZoom: 2,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.tu.app',
              ),
              MarkerLayer(
                markers: conteo.entries.map((entry) {
                  final partes = entry.key.split(',');
                  final lat = double.parse(partes[0]);
                  final lng = double.parse(partes[1]);
                  final count = entry.value;
                  final baseColor = count >= maxCount
                      ? Colors.red
                      : count >= (maxCount * 0.6)
                      ? Colors.orange
                      : count >= (maxCount * 0.3)
                      ? Colors.yellow
                      : Colors.green;
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 26.0 + 36.0 * (count / maxCount), // entre 26 y 62 px
                    height: 26.0 + 36.0 * (count / maxCount),
                    child: Tooltip(
                      message:
                          (ejemploDestino[entry.key]?['nombre'] ?? "") +
                          "\nPedidos: $count",
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: baseColor.withOpacity(
                            0.33 + 0.17 * (count / maxCount),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 12 + 12 * (count / maxCount),
                            height: 12 + 12 * (count / maxCount),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: baseColor.withOpacity(0.75),
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
