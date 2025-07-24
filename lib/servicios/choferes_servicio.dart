import 'package:cloud_firestore/cloud_firestore.dart';

class ChoferesServicio {
  final _usuarios = FirebaseFirestore.instance.collection('usuarios');

  Stream<List<Map<String, dynamic>>> obtenerChoferesConUbicacion() {
    return _usuarios
        .where('rol', isEqualTo: 'chofer') // Filtramos por rol "chofer"
        .where('estado', isEqualTo: 'activo') // Filtramos por estado "activo"
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where(
                (doc) => doc.data().containsKey('ubicacion'),
              ) // Solo choferes con ubicación
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'nombre': data['nombre'], // Nombre del chofer
                  'ubicacion': data['ubicacion'], // Ubicación del chofer
                  'foto_url': data.containsKey('foto_url')
                      ? data['foto_url']
                      : null, // Foto, si existe
                  'telefono': data.containsKey('telefono')
                      ? data['telefono']
                      : null, // Teléfono, si existe
                };
              })
              .toList(),
        );
  }
}
