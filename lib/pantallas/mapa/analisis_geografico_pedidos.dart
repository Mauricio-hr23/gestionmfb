import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../servicios/pedido_servicio.dart';
import '../../servicios/usuario_servicio.dart'; // para obtener choferes

class AnalisisGeograficoPedidosPantalla extends StatefulWidget {
  const AnalisisGeograficoPedidosPantalla({super.key});

  @override
  State<AnalisisGeograficoPedidosPantalla> createState() =>
      _AnalisisGeograficoPedidosPantallaState();
}

class _AnalisisGeograficoPedidosPantallaState
    extends State<AnalisisGeograficoPedidosPantalla> {
  late Future<Map<String, dynamic>> _futureAnalisis;
  DateTimeRange? _rangoFechas;
  String? _choferSeleccionado;
  List<Map<String, dynamic>> _choferes = [];

  @override
  void initState() {
    super.initState();
    _cargarChoferes();
    _actualizarAnalisis();
  }

  void _actualizarAnalisis() {
    setState(() {
      _futureAnalisis = analizarDestinosPedidos(
        rangoFechas: _rangoFechas,
        choferId: _choferSeleccionado,
      );
    });
  }

  Future<void> _cargarChoferes() async {
    final lista = await UsuarioServicio().obtenerChoferes();
    setState(() {
      _choferes = lista.map((c) => {'id': c.id, 'nombre': c.nombre}).toList();
    });
  }

  // -------- Exportar a PDF ----------
  Future<void> exportarAnalisisAPDF(Map<String, dynamic> analisis) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Análisis Geográfico de Pedidos",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (_rangoFechas != null)
              pw.Text(
                "Rango de fechas: ${_rangoFechas!.start.toString().split(' ')[0]} al ${_rangoFechas!.end.toString().split(' ')[0]}",
                style: pw.TextStyle(fontSize: 13),
              ),
            if (_choferSeleccionado != null)
              pw.Text(
                "Filtrado por chofer: ${_choferes.firstWhere((c) => c['id'] == _choferSeleccionado, orElse: () => {'nombre': '---'})['nombre']}",
              ),
            pw.Text("Total de pedidos: ${analisis['totalPedidos']}"),
            pw.Text("Destinos únicos: ${analisis['destinosUnicos']}"),
            pw.Text("Promedio por destino: ${analisis['promedioPorDestino']}"),
            pw.SizedBox(height: 16),
            pw.Text(
              "Zona más demandada: ${analisis['topZona']['nombre']} - ${analisis['topZona']['total']} pedidos",
            ),
            pw.Text(
              "Zona menos atendida: ${analisis['zonaMenos']['nombre']} - ${analisis['zonaMenos']['total']} pedidos",
            ),
            pw.SizedBox(height: 12),
            pw.Text("Top 3 zonas:"),
            ...List.generate((analisis['top3'] as List).length, (i) {
              final zona = analisis['top3'][i];
              return pw.Text(
                " ${i + 1}. ${zona['nombre']} (${zona['total']} pedidos)",
              );
            }),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // -------- Exportar a CSV ----------
  Future<void> exportarAnalisisACSV(Map<String, dynamic> analisis) async {
    List<List<dynamic>> rows = [
      ['Indicador', 'Valor'],
      ['Total de pedidos', analisis['totalPedidos']],
      ['Destinos únicos', analisis['destinosUnicos']],
      ['Promedio por destino', analisis['promedioPorDestino']],
      ['Zona más demandada', analisis['topZona']['nombre']],
      ['Pedidos zona más demandada', analisis['topZona']['total']],
      ['Zona menos atendida', analisis['zonaMenos']['nombre']],
      ['Pedidos zona menos atendida', analisis['zonaMenos']['total']],
    ];

    rows.add([]);
    rows.add(['Ranking top 3']);
    (analisis['top3'] as List).asMap().forEach((i, zona) {
      rows.add(['${i + 1}', zona['nombre'], zona['total']]);
    });

    String csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/analisis_pedidos.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: "Análisis de pedidos (CSV)");
  }

  // -------- Pantalla principal --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Análisis Geográfico de Pedidos"),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _futureAnalisis,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox();
              }
              final analisis = snapshot.data!;
              return Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.picture_as_pdf),
                    tooltip: 'Exportar a PDF',
                    onPressed: () => exportarAnalisisAPDF(analisis),
                  ),
                  IconButton(
                    icon: Icon(Icons.table_view),
                    tooltip: 'Exportar a Excel/CSV',
                    onPressed: () => exportarAnalisisACSV(analisis),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                // Filtro de fecha
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.date_range),
                    label: Text(
                      _rangoFechas == null
                          ? "Filtrar por fecha"
                          : "${_rangoFechas!.start.day}/${_rangoFechas!.start.month}/${_rangoFechas!.start.year} - ${_rangoFechas!.end.day}/${_rangoFechas!.end.month}/${_rangoFechas!.end.year}",
                    ),
                    onPressed: () async {
                      final rango = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2022),
                        lastDate: DateTime.now().add(Duration(days: 1)),
                      );
                      if (rango != null) {
                        setState(() {
                          _rangoFechas = rango;
                        });
                        _actualizarAnalisis();
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Filtro de chofer
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Chofer",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    value: _choferSeleccionado,
                    items: [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._choferes.map(
                        (c) => DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['nombre']),
                        ),
                      ),
                    ],
                    onChanged: (valor) {
                      setState(() {
                        _choferSeleccionado = valor;
                      });
                      _actualizarAnalisis();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _futureAnalisis,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final analisis = snapshot.data!;
                if (analisis.isEmpty) {
                  return const Center(
                    child: Text("No hay datos para analizar."),
                  );
                }

                final topZona = analisis['topZona'];
                final top3 = analisis['top3'] as List<dynamic>;
                final zonaMenos = analisis['zonaMenos'];
                final totalPedidos = analisis['totalPedidos'];
                final destinosUnicos = analisis['destinosUnicos'];
                final promedio = analisis['promedioPorDestino'];

                final markers = <Marker>[
                  // Top zona (más demandada)
                  Marker(
                    point: LatLng(topZona['latitud'], topZona['longitud']),
                    width: 62,
                    height: 62,
                    alignment:
                        Alignment.topCenter, // para evitar overflow abajo
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.whatshot, color: Colors.red, size: 32),
                        Container(
                          constraints: BoxConstraints(maxWidth: 92),
                          padding: EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 3),
                            ],
                          ),
                          child: Text(
                            topZona['nombre'] ?? '',
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
                  // Zona menos atendida
                  Marker(
                    point: LatLng(zonaMenos['latitud'], zonaMenos['longitud']),
                    width: 52,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, color: Colors.blueGrey, size: 23),
                        Container(
                          constraints: BoxConstraints(maxWidth: 92),
                          padding: EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 3),
                            ],
                          ),
                          child: Text(
                            zonaMenos['nombre'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
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

                return RefreshIndicator(
                  onRefresh: () async => _actualizarAnalisis(),
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
                                  topZona['latitud'],
                                  topZona['longitud'],
                                ),
                                initialZoom: 13,
                                maxZoom: 18,
                                minZoom: 2,
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
                                Text("• Destinos únicos: $destinosUnicos"),
                                Text("• Promedio por destino: $promedio"),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Top zona caliente
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
                              "Zona más demandada:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${topZona['nombre']} (${topZona['latitud'].toStringAsFixed(5)}, ${topZona['longitud'].toStringAsFixed(5)})",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),
                            trailing: Text(
                              "${topZona['total']} pedidos",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Zona menos usada
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
                              "Zona menos atendida:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${zonaMenos['nombre']} (${zonaMenos['latitud'].toStringAsFixed(5)}, ${zonaMenos['longitud'].toStringAsFixed(5)})",
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),
                            trailing: Text(
                              "${zonaMenos['total']} pedidos",
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
                          "Top 3 zonas con más pedidos:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...top3.asMap().entries.map((e) {
                          final i = e.key;
                          final zona = e.value;
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
                              title: Text(zona['nombre'] ?? 'Sin nombre'),
                              subtitle: Text(
                                "Lat: ${zona['latitud'].toStringAsFixed(5)}, Lng: ${zona['longitud'].toStringAsFixed(5)}",
                              ),
                              trailing: Text("${zona['total']} pedidos"),
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
                                topZona,
                                zonaMenos,
                                totalPedidos,
                                destinosUnicos,
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
          ),
        ],
      ),
    );
  }

  // ------- Lógica de análisis y filtrado --------
  Future<Map<String, dynamic>> analizarDestinosPedidos({
    DateTimeRange? rangoFechas,
    String? choferId,
  }) async {
    final destinos = await PedidoServicio().obtenerDestinosPedidos(
      rangoFechas: rangoFechas,
      choferId: choferId,
    );
    if (destinos.isEmpty) return {};

    final conteo = <String, int>{};
    final info = <String, Map<String, dynamic>>{};
    for (var d in destinos) {
      final key = "${d['latitud']},${d['longitud']}";
      conteo[key] = (conteo[key] ?? 0) + 1;
      info[key] = d;
    }

    final topEntry = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topInfo = info[topEntry.key]!;

    final top3 = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3List = top3.take(3).map((e) {
      final d = info[e.key]!;
      return {
        'nombre': d['nombre'] ?? 'Sin nombre',
        'latitud': d['latitud'],
        'longitud': d['longitud'],
        'total': e.value,
      };
    }).toList();

    final lowEntry = conteo.entries.reduce((a, b) => a.value < b.value ? a : b);
    final lowInfo = info[lowEntry.key]!;

    return {
      'topZona': {
        'nombre': topInfo['nombre'] ?? 'Sin nombre',
        'latitud': topInfo['latitud'],
        'longitud': topInfo['longitud'],
        'total': topEntry.value,
      },
      'top3': top3List,
      'zonaMenos': {
        'nombre': lowInfo['nombre'] ?? 'Sin nombre',
        'latitud': lowInfo['latitud'],
        'longitud': lowInfo['longitud'],
        'total': lowEntry.value,
      },
      'totalPedidos': destinos.length,
      'destinosUnicos': conteo.length,
      'promedioPorDestino': (destinos.length / conteo.length).toStringAsFixed(
        2,
      ),
    };
  }

  String _generarConclusion(
    Map topZona,
    Map zonaMenos,
    int total,
    int unicos,
    String promedio,
  ) {
    String texto = "";
    if (topZona['nombre'] != null && topZona['nombre'] != 'Sin nombre') {
      texto += "La zona más demandada es \"${topZona['nombre']}\" ";
    } else {
      texto += "La ubicación más solicitada ";
    }
    texto += "ha recibido ${topZona['total']} pedidos, ";
    texto += "mientras que la menos atendida ";
    if (zonaMenos['nombre'] != null && zonaMenos['nombre'] != 'Sin nombre') {
      texto += "es \"${zonaMenos['nombre']}\" ";
    }
    texto += "con solo ${zonaMenos['total']}.\n";
    texto +=
        "En total se han realizado $total pedidos hacia $unicos destinos diferentes, ";
    texto += "con un promedio de $promedio pedidos por destino. ";
    texto +=
        "Se recomienda reforzar la logística en la zona más activa y analizar la baja demanda en las menos concurridas.";
    return texto;
  }
}
