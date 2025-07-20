import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../servicios/choferes_servicio.dart';
import '../../widgets/marcador_chofer_widget.dart';

class MapaTiempoRealPantalla extends StatelessWidget {
  final _choferesServicio = ChoferesServicio();

  MapaTiempoRealPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ubicación en Tiempo Real')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _choferesServicio.obtenerChoferesConUbicacion(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final choferes = snapshot.data!;
          return FlutterMap(
            options: MapOptions(
              initialCenter: choferes.isNotEmpty
                  ? LatLng(
                      choferes[0]['ubicacion'].latitude,
                      choferes[0]['ubicacion'].longitude,
                    )
                  : LatLng(-1.565, -79.004), // Por defecto (La Maná)
              initialZoom: 13,
              interactionOptions: const InteractionOptions(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tuapp.app',
              ),
              ...choferes.map((chofer) {
                final geo = chofer['ubicacion'];
                return MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: LatLng(geo.latitude, geo.longitude),
                      child: MarcadorChoferWidget(
                        nombre: chofer['nombre'],
                        fotoUrl: chofer['foto'],
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
