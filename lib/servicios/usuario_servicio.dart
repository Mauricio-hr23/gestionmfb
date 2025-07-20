import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/usuario_modelo.dart';

class UsuarioServicio {
  final _usuariosRef = FirebaseFirestore.instance.collection('usuarios');

  Future<List<UsuarioModelo>> obtenerChoferes() async {
    final query = await _usuariosRef.where('rol', isEqualTo: 'chofer').get();
    return query.docs
        .map((doc) => UsuarioModelo.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UsuarioModelo>> obtenerChoferesDisponibles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'chofer')
        .where('estado', isEqualTo: 'activo')
        .get();

    return snapshot.docs
        .where(
          (doc) =>
              doc.data().containsKey('pedido_id') ||
              doc.data()['pedido_id'] == null,
        )
        .map((doc) => UsuarioModelo.fromMap(doc.data(), doc.id))
        .toList();
  }
}
