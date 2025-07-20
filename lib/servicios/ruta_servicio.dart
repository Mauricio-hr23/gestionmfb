import 'package:cloud_firestore/cloud_firestore.dart';

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
}
