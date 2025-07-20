import 'package:flutter/material.dart';
import '../modelos/usuario_modelo.dart';
import '../servicios/usuario_servicio.dart';

class ChoferProveedor with ChangeNotifier {
  List<UsuarioModelo> _choferes = [];
  final UsuarioServicio _servicio = UsuarioServicio();

  List<UsuarioModelo> get choferes => _choferes;

  Future<void> cargarChoferes() async {
    _choferes = await _servicio.obtenerChoferes();
    notifyListeners();
  }
}
