import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/vehiculo_modelo.dart';

class VehiculoServicio {
  final _vehiculosRef = FirebaseFirestore.instance.collection('vehiculos');

  Future<List<VehiculoModelo>> obtenerVehiculos() async {
    final query = await _vehiculosRef.get();
    return query.docs
        .map((doc) => VehiculoModelo.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> crearVehiculo(VehiculoModelo vehiculo) async {
    await _vehiculosRef.add(vehiculo.toMap());
  }

  Future<void> actualizarVehiculo(VehiculoModelo vehiculo) async {
    await _vehiculosRef.doc(vehiculo.id).update(vehiculo.toMap());
  }

  Future<void> eliminarVehiculo(String id) async {
    await _vehiculosRef.doc(id).delete();
  }

  Future<void> asignarVehiculoAChofer(
    String vehiculoId,
    String choferId,
  ) async {
    await _vehiculosRef.doc(vehiculoId).update({'chofer_id': choferId});
  }
}
