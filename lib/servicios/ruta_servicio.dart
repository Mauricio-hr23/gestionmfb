import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Para usar jsonDecode
import 'package:http/http.dart' as http; // Para hacer solicitudes HTTP

class RutaServicio {
  final _coleccion = FirebaseFirestore.instance.collection('rutas');

  // Obtener todas las rutas guardadas (en tiempo real)
  Stream<List<Map<String, dynamic>>> obtenerRutasGuardadas() {
    return _coleccion.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nombre': data['nombre'],
          'latitud': data['latitud'],
          'longitud': data['longitud'],
        };
      }).toList();
    });
  }

  // Agregar una nueva marca/ruta
  Future<void> guardarRuta(
    String nombre,
    double latitud,
    double longitud,
  ) async {
    await _coleccion.add({
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
    });
  }

  // Editar el nombre de una marca/ruta
  Future<void> editarNombreMarca(String id, String nuevoNombre) async {
    await _coleccion.doc(id).update({'nombre': nuevoNombre});
  }

  // Editar la ubicación de una marca/ruta
  Future<void> editarUbicacionMarca(
    String id,
    double nuevaLat,
    double nuevaLng,
  ) async {
    await _coleccion.doc(id).update({
      'latitud': nuevaLat,
      'longitud': nuevaLng,
    });
  }

  // Eliminar una marca/ruta
  Future<void> eliminarMarca(String id) async {
    await _coleccion.doc(id).delete();
  }

  // Incrementar el contador de usos
  Future<void> incrementarUsoMarca(String id) async {
    await _coleccion.doc(id).update({'usos': FieldValue.increment(1)});
  }

  // Ranking de marcas más usadas
  Future<List<Map<String, dynamic>>> obtenerRankingMarcas({
    int top = 10,
  }) async {
    final snap = await _coleccion
        .orderBy('usos', descending: true)
        .limit(top)
        .get();
    return snap.docs
        .map(
          (doc) => {
            'id': doc.id,
            'nombre': doc['nombre'],
            'latitud': doc['latitud'],
            'longitud': doc['longitud'],
            'usos': doc['usos'] ?? 0,
          },
        )
        .toList();
  }

  // Stream para estadísticas en vivo (opcional)
  Stream<List<Map<String, dynamic>>> rankingMarcasStream({int top = 10}) {
    return _coleccion
        .orderBy('usos', descending: true)
        .limit(top)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'nombre': doc['nombre'],
                  'latitud': doc['latitud'],
                  'longitud': doc['longitud'],
                  'usos': doc['usos'] ?? 0,
                },
              )
              .toList(),
        );
  }

  // Función para obtener la ruta desde OpenRouteService (alternativa)
  Future<List<dynamic>> obtenerRutaOpenRouteService(
    double latInicio,
    double lngInicio,
    double latDestino,
    double lngDestino,
  ) async {
    final String url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=5b3ce3597851110001cf6248ebc4492a6e4d444998e3dea5335f2237&start=$lngInicio,$latInicio&end=$lngDestino,$latDestino';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['features'][0]['geometry']['coordinates']; // Retorna las coordenadas de la ruta
    } else {
      throw Exception('Error al obtener la ruta');
    }
  }

  // Obtener los pedidos de un chofer específico
  Future<List<Map<String, dynamic>>> obtenerPedidosPorChofer(
    String choferId,
  ) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('choferId', isEqualTo: choferId)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'latitud': doc['ubicacion']['latitud'], // Accede a 'ubicacion'
        'longitud': doc['ubicacion']['longitud'], // Accede a 'ubicacion'
        'direccion': doc['direccion'],
        'estado': doc['estado'],
      };
    }).toList();
  }

  // Función para obtener la ruta de Google Maps Directions API
  Future<List<dynamic>> obtenerRutaDeChofer(
    List<Map<String, dynamic>> pedidos,
  ) async {
    final List<String> puntos = [];

    if (pedidos.isEmpty) {
      print("No se encontraron pedidos para el chofer.");
      return [];
    }

    // Agregar los puntos de cada pedido
    for (var pedido in pedidos) {
      final lat = pedido['latitud']; // Asegúrate de que estos campos existen
      final lng = pedido['longitud']; // Asegúrate de que estos campos existen
      print(
        "Punto del pedido: lat=$lat, lng=$lng",
      ); // Verifica que los puntos se extraen
      puntos.add("$lng,$lat");
    }

    // Si no se han añadido puntos a la lista
    if (puntos.isEmpty) {
      print("No se añadieron puntos de ruta.");
      return [];
    }

    // Crear el string de waypoints para Google Maps Directions API
    final waypoints = puntos.join('&waypoints=');
    final String apiKey = 'AIzaSyBj19l1JjUGzZeREbUq7iV4Tohea1PfqjQ';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${puntos[0]}&destination=${puntos.last}&waypoints=$waypoints&key=$apiKey';

    print(
      "URL de la API de Google: $url",
    ); // Verifica que la URL se construya correctamente

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['routes'][0]['legs'][0]['steps']; // Retorna los pasos de la ruta
    } else {
      print("Error al obtener la ruta: ${response.statusCode}");
      return [];
    }
  }
}
