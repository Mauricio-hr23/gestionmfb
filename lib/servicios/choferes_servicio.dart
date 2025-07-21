import 'package:cloud_firestore/cloud_firestore.dart';

class ChoferesServicio {
  final _usuarios = FirebaseFirestore.instance.collection('usuarios');

  Stream<List<Map<String, dynamic>>> obtenerChoferesConUbicacion() {
    return _usuarios
        .where('rol', isEqualTo: 'chofer')
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data().containsKey('ubicacion'))
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'nombre': data['nombre'],
                  'ubicacion': data['ubicacion'],
                  'foto_url': data.containsKey('foto_url')
                      ? data['foto_url']
                      : null,
                  'telefono': data.containsKey('telefono')
                      ? data['telefono']
                      : null,
                };
              })
              .toList(),
        );
  }
}
