import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/pedido_modelo.dart';
import 'package:flutter/material.dart'; // Importar el paquete material.dart

class PedidoServicio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _pedidoRef = FirebaseFirestore.instance.collection('pedidos');

  // Crear un nuevo pedido
  Future<void> crearPedido(PedidoModelo pedido) async {
    await _pedidoRef.add(pedido.toMap());
  }

  // Asignar un pedido a un chofer
  Future<void> asignarPedidoAChofer(String pedidoId, String choferId) async {
    await _pedidoRef.doc(pedidoId).update({
      'choferId': choferId,
      'estado': 'en curso',
    });
    // También actualiza el chofer (opcional)
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(choferId)
        .update({'pedido_id': pedidoId});
  }

  // Obtener todos los pedidos en tiempo real
  Stream<List<PedidoModelo>> obtenerPedidos() {
    return _pedidoRef.snapshots().map((snapshot) {
      print(
        "Pedidos obtenidos: ${snapshot.docs.length}",
      ); // Añade esta línea para ver cuántos documentos se obtienen
      return snapshot.docs.map((doc) {
        return PedidoModelo.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Actualizar el estado de un pedido
  Future<void> actualizarEstadoPedido(
    String pedidoId,
    String nuevoEstado,
  ) async {
    await _pedidoRef.doc(pedidoId).update({'estado': nuevoEstado});
  }

  // Escuchar un pedido específico por ID
  Stream<PedidoModelo?> escucharPedidoPorId(String pedidoId) {
    return _pedidoRef.doc(pedidoId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PedidoModelo.fromMap(doc.data()! as Map<String, dynamic>, doc.id);
    });
  }

  // Para el mapa de calor: obtener todos los destinos de los pedidos
  Future<List<Map<String, dynamic>>> obtenerDestinosPedidos({
    DateTimeRange? rangoFechas,
    String? choferId,
  }) async {
    Query query = _pedidoRef;

    if (choferId != null && choferId.isNotEmpty) {
      query = query.where('choferId', isEqualTo: choferId);
    }
    if (rangoFechas != null) {
      query = query.where(
        'fechaEstimada',
        isGreaterThanOrEqualTo: Timestamp.fromDate(rangoFechas.start),
      );
      query = query.where(
        'fechaEstimada',
        isLessThanOrEqualTo: Timestamp.fromDate(rangoFechas.end),
      );
    }

    final snap = await query.get();

    return snap.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['ubicacion'] != null &&
              data['ubicacion']['latitud'] != null &&
              data['ubicacion']['longitud'] != null;
        })
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ubic = data['ubicacion'];
          return {
            'latitud': ubic['latitud'],
            'longitud': ubic['longitud'],
            'nombre': ubic['nombre'],
            'fecha': (data['fechaEstimada'] ?? data['fecha'] ?? DateTime.now())
                .toString(),
          };
        })
        .toList();
  }
}
