import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../servicios/ruta_servicio.dart';

class EstadisticasUbicacionesPantalla extends StatelessWidget {
  const EstadisticasUbicacionesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ranking de Ubicaciones más Usadas")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Obtención de los datos
        future: RutaServicio().obtenerRankingMarcas(top: 7),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            ); // Muestra el cargando
          }
          final data = snapshot.data!; // Datos obtenidos
          if (data.isEmpty) {
            return Center(
              child: Text("Aún no hay datos de uso."),
            ); // Si no hay datos
          }

          // Gráfico de barras
          final maxUsos = data
              .map((e) => e['usos'] as int)
              .fold<int>(
                0,
                (prev, e) => e > prev ? e : prev,
              ); // Encuentra el valor máximo de usos

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 1, // Intervalo de las etiquetas del eje Y
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              int i = value.toInt();
                              if (i >= 0 && i < data.length) {
                                return SideTitleWidget(
                                  meta:
                                      meta, // Aquí es donde se pasa el parámetro meta
                                  child: Text(
                                    data[i]['nombre'].toString().length > 12
                                        ? "${data[i]['nombre'].toString().substring(0, 12)}…" // Corta los nombres largos
                                        : data[i]['nombre'],
                                    style: TextStyle(fontSize: 11),
                                  ),
                                );
                              }
                              return Container(); // Si no hay nombre, retorna un contenedor vacío
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                      ),
                      gridData: FlGridData(
                        show: false,
                      ), // Desactiva la cuadrícula
                      borderData: FlBorderData(show: false), // Sin borde
                      barGroups: [
                        for (int i = 0; i < data.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (data[i]['usos'] as int)
                                    .toDouble(), // Usos en el gráfico
                                width: 22,
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          ),
                      ],
                      maxY: (maxUsos + 1)
                          .toDouble(), // Ajusta el máximo del eje Y
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Ranking Top 7:", // Título del ranking
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ...data.asMap().entries.map((e) {
                  final i = e.key;
                  final marca = e.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: Text("${i + 1}"), // Muestra el ranking
                    ),
                    title: Text(marca['nombre'] ?? ''),
                    subtitle: Text("Usos: ${marca['usos']}"),
                    trailing: Icon(Icons.place, color: Colors.blue),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
