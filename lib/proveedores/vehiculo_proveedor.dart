import 'package:flutter/material.dart';
import '../modelos/vehiculo_modelo.dart';
import '../servicios/vehiculo_servicio.dart';

class VehiculoProveedor with ChangeNotifier {
  List<VehiculoModelo> _vehiculos = [];
  final VehiculoServicio _servicio = VehiculoServicio();

  List<VehiculoModelo> get vehiculos => _vehiculos;

  Future<void> cargarVehiculos() async {
    _vehiculos = await _servicio.obtenerVehiculos();
    notifyListeners();
  }

  Future<void> agregarVehiculo(VehiculoModelo vehiculo) async {
    await _servicio.crearVehiculo(vehiculo);
    await cargarVehiculos();
  }

  Future<void> editarVehiculo(VehiculoModelo vehiculo) async {
    await _servicio.actualizarVehiculo(vehiculo);
    await cargarVehiculos();
  }

  Future<void> eliminarVehiculo(String id) async {
    await _servicio.eliminarVehiculo(id);
    await cargarVehiculos();
  }
}
