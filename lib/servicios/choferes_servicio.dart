import 'package:cloud_firestore/cloud_firestore.dart';

class ChoferesServicio {
  final _usuarios = FirebaseFirestore.instance.collection('usuarios');

  Stream<List<Map<String, dynamic>>> obtenerChoferesConUbicacion() {
    // Solo choferes activos
    return _usuarios
        .where('rol', isEqualTo: 'chofer')
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data().containsKey('ubicacion'))
              .map(
                (doc) => {
                  'id': doc.id,
                  'nombre': doc['nombre'],
                  'ubicacion': doc['ubicacion'],
                  'foto_url': doc.data().containsKey('foto_url')
                      ? doc['foto_url']
                      : null,
                  'telefono': doc.data().containsKey('telefono')
                      ? doc['telefono']
                      : null,
                },
              )
              .toList(),
        );
  }
}
