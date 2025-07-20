import 'package:flutter/material.dart';
import '../modelos/usuario_modelo.dart';

class TarjetaChofer extends StatelessWidget {
  final UsuarioModelo chofer;
  final VoidCallback onTap;

  const TarjetaChofer({required this.chofer, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.directions_car)),
        title: Text(chofer.nombre),
        subtitle: Text('Tel: ${chofer.telefono ?? "Sin número"}'),
        trailing: Icon(Icons.add_task, color: Colors.green[700]),
        onTap: onTap,
      ),
    );
  }
}
