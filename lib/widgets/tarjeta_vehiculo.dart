import 'package:flutter/material.dart';
import '../modelos/vehiculo_modelo.dart';

class TarjetaVehiculo extends StatelessWidget {
  final VehiculoModelo vehiculo;
  final Function()? onEdit;
  final Function()? onDelete;

  const TarjetaVehiculo({
    super.key,
    required this.vehiculo,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.local_shipping, size: 38),
        title: Text(
          '${vehiculo.modelo} - ${vehiculo.placa}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Estado: ${vehiculo.estado}\nChofer: ${(vehiculo.choferId ?? '').isNotEmpty ? vehiculo.choferId : "No asignado"}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit?.call();
            } else if (value == 'delete') {
              onDelete?.call();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
