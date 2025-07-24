import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../servicios/pedido_servicio.dart';

class AnalisisCuadrantesPedidosPantalla extends StatefulWidget {
  const AnalisisCuadrantesPedidosPantalla({super.key});

  @override
  State<AnalisisCuadrantesPedidosPantalla> createState() =>
      _AnalisisCuadrantesPedidosPantallaState();
}

class _AnalisisCuadrantesPedidosPantallaState
    extends State<AnalisisCuadrantesPedidosPantalla> {
  late Future<Map<String, dynamic>> _futureAnalisis;
  final double gridSize = 0.005; // Aprox. 500m

  @override
  void initState() {
    super.initState();
    _futureAnalisis = analizarSectoresPorCuadrante();
  }

  String cuadranteKey(double lat, double lng) {
    int latGrid = (lat / gridSize).floor();
    int lngGrid = (lng / gridSize).floor();
    return "$latGrid,$lngGrid";
  }

  List<LatLng> cuadrantePolygon(double lat, double lng) {
    double baseLat = (lat / gridSize).floor() * gridSize;
    double baseLng = (lng / gridSize).floor() * gridSize;
    // Retorna las esquinas del cuadrante en sentido antihorario
    return [
      LatLng(baseLat, baseLng),
      LatLng(baseLat, baseLng + gridSize),
      LatLng(baseLat + gridSize, baseLng + gridSize),
      LatLng(baseLat + gridSize, baseLng),
    ];
  }

  Future<Map<String, dynamic>> analizarSectoresPorCuadrante() async {
    final destinos = await PedidoServicio().obtenerDestinosPedidos();
    if (destinos.isEmpty) return {};

    final conteo = <String, int>{};
    final ubicacionCentro = <String, Map<String, double>>{};

    for (var d in destinos) {
      final lat = d['latitud'];
      final lng = d['longitud'];
      final key = cuadranteKey(lat, lng);
      conteo[key] = (conteo[key] ?? 0) + 1;
      ubicacionCentro[key] = {'lat': lat, 'lng': lng};
    }

    // Top cuadrante
    final topEntry = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topKey = topEntry.key;
    final topCentro = ubicacionCentro[topKey]!;

    // Top 3
    final top3 = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3List = top3.take(3).map((e) {
      final centro = ubicacionCentro[e.key]!;
      return {
        'key': e.key,
        'centro_lat': centro['lat'],
        'centro_lng': centro['lng'],
        'total': e.value,
      };
    }).toList();

    // Cuadrante menos atendido
    final lowEntry = conteo.entries.reduce((a, b) => a.value < b.value ? a : b);
    final lowCentro = ubicacionCentro[lowEntry.key]!;

    return {
      'topCuadrante': {
        'key': topKey,
        'centro_lat': topCentro['lat'],
        'centro_lng': topCentro['lng'],
        'total': topEntry.value,
      },
      'top3': top3List,
      'cuadranteMenos': {
        'key': lowEntry.key,
        'centro_lat': lowCentro['lat'],
        'centro_lng': lowCentro['lng'],
        'total': lowEntry.value,
      },
      'totalPedidos': destinos.length,
      'cuadrantesUnicos': conteo.length,
      'promedioPorCuadrante': (destinos.length / conteo.length).toStringAsFixed(
        2,
      ),
      'destinos': destinos, // Pasar todos los destinos
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Análisis por Cuadrantes")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureAnalisis,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final analisis = snapshot.data!;
          if (analisis.isEmpty) {
            return const Center(child: Text("No hay datos para analizar."));
          }

          final topCuadrante = analisis['topCuadrante'];
          final top3 = analisis['top3'] as List<dynamic>;
          final cuadranteMenos = analisis['cuadranteMenos'];
          final totalPedidos = analisis['totalPedidos'];
          final cuadrantesUnicos = analisis['cuadrantesUnicos'];
          final promedio = analisis['promedioPorCuadrante'];
          final destinos =
              analisis['destinos'] as List<dynamic>; // Todos los destinos

          final List<Polygon> polygons = [
            // Polígono del cuadrante más demandado
            Polygon(
              points: cuadrantePolygon(
                topCuadrante['centro_lat'],
                topCuadrante['centro_lng'],
              ),
              color: Colors.red.withOpacity(0.23),
              borderColor: Colors.red,
              borderStrokeWidth: 3,
              isFilled: true,
              label: "Más demandado",
            ),
            // Polígono del cuadrante menos demandado
            Polygon(
              points: cuadrantePolygon(
                cuadranteMenos['centro_lat'],
                cuadranteMenos['centro_lng'],
              ),
              color: Colors.blueGrey.withOpacity(0.17),
              borderColor: Colors.blueGrey,
              borderStrokeWidth: 2,
              isFilled: true,
              label: "Menos demandado",
            ),
          ];

          final markers = <Marker>[
            // Centro del cuadrante más demandado
            Marker(
              point: LatLng(
                topCuadrante['centro_lat'],
                topCuadrante['centro_lng'],
              ),
              width: 55,
              height: 55,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.whatshot, color: Colors.red, size: 32),
                  Container(
                    constraints: BoxConstraints(maxWidth: 80),
                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 3),
                      ],
                    ),
                    child: Text(
                      "Hotspot",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Centro del cuadrante menos atendido
            Marker(
              point: LatLng(
                cuadranteMenos['centro_lat'],
                cuadranteMenos['centro_lng'],
              ),
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag, color: Colors.blueGrey, size: 20),
                  Container(
                    constraints: BoxConstraints(maxWidth: 60),
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 3),
                      ],
                    ),
                    child: Text(
                      "Bajo",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ];

          // Generar círculos con opacidad variable para simular el mapa de calor
          // Generar círculos con opacidad variable para simular el mapa de calor
          List<CircleMarker> circleMarkers = destinos.map((d) {
            final lat = d['latitud'];
            final lng = d['longitud'];
            final intensity = (d['total'] ?? 1)
                .toDouble(); // Aseguramos que intensity sea un double

            // Determinar el color según la intensidad
            Color color = Colors.green.withOpacity(0.1); // Color base (suave)
            if (intensity > 5)
              color = Colors.orange.withOpacity(
                0.6,
              ); // Más pedidos -> más intensidad
            if (intensity > 10)
              color = Colors.red.withOpacity(0.8); // Muy alto -> rojo intenso

            return CircleMarker(
              point: LatLng(lat, lng),
              radius: (10 + intensity * 2)
                  .toDouble(), // Ajustar tamaño según la intensidad y asegurarnos de que sea un double
              color: color,
              borderColor: color.withOpacity(1),
              borderStrokeWidth: 1,
            );
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureAnalisis = analizarSectoresPorCuadrante();
              });
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mapa
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 260,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            topCuadrante['centro_lat'],
                            topCuadrante['centro_lng'],
                          ),
                          initialZoom: 14, // Usamos initialZoom
                          maxZoom: 18,
                          minZoom: 2,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName: 'com.tu.app',
                          ),
                          PolygonLayer(polygons: polygons),
                          MarkerLayer(markers: markers),
                          CircleLayer(
                            circles: circleMarkers,
                          ), // Agregamos la capa de círculos
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Resumen
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Resumen General",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("• Total de pedidos: $totalPedidos"),
                          Text("• Cuadrantes únicos: $cuadrantesUnicos"),
                          Text("• Promedio por cuadrante: $promedio"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Top cuadrante caliente
                  Card(
                    color: Colors.red.shade50,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.whatshot,
                        color: Colors.red,
                        size: 34,
                      ),
                      title: Text(
                        "Cuadrante más demandado:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Centro: (${topCuadrante['centro_lat'].toStringAsFixed(5)}, ${topCuadrante['centro_lng'].toStringAsFixed(5)})",
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      trailing: Text(
                        "${topCuadrante['total']} pedidos",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cuadrante menos usado
                  Card(
                    color: Colors.blueGrey.shade50,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.flag,
                        color: Colors.blueGrey,
                        size: 28,
                      ),
                      title: Text(
                        "Cuadrante menos atendido:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Centro: (${cuadranteMenos['centro_lat'].toStringAsFixed(5)}, ${cuadranteMenos['centro_lng'].toStringAsFixed(5)})",
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      trailing: Text(
                        "${cuadranteMenos['total']} pedidos",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Top 3
                  Text(
                    "Top 3 cuadrantes con más pedidos:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  ...top3.asMap().entries.map((e) {
                    final i = e.key;
                    final cuadrante = e.value;
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: [
                            Colors.red,
                            Colors.orange,
                            Colors.amber,
                          ][i],
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          "Centro: (${cuadrante['centro_lat'].toStringAsFixed(5)}, ${cuadrante['centro_lng'].toStringAsFixed(5)})",
                          style: TextStyle(fontSize: 13),
                        ),
                        trailing: Text("${cuadrante['total']} pedidos"),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  // Conclusión automática
                  Card(
                    color: Colors.blue.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text(
                        _generarConclusion(
                          topCuadrante,
                          cuadranteMenos,
                          totalPedidos,
                          cuadrantesUnicos,
                          promedio,
                        ),
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _generarConclusion(
    Map topCuadrante,
    Map cuadranteMenos,
    int total,
    int unicos,
    String promedio,
  ) {
    String texto = "";
    texto +=
        "El cuadrante más demandado se encuentra en el centro: (${topCuadrante['centro_lat'].toStringAsFixed(5)}, ${topCuadrante['centro_lng'].toStringAsFixed(5)}) con ${topCuadrante['total']} pedidos, ";
    texto +=
        "mientras que el menos atendido está en (${cuadranteMenos['centro_lat'].toStringAsFixed(5)}, ${cuadranteMenos['centro_lng'].toStringAsFixed(5)}) con solo ${cuadranteMenos['total']}.\n";
    texto +=
        "En total se han realizado $total pedidos hacia $unicos cuadrantes diferentes, con un promedio de $promedio pedidos por cuadrante. ";
    texto +=
        "Esto permite optimizar rutas y recursos logísticos en las zonas de mayor y menor demanda.";
    return texto;
  }
}
