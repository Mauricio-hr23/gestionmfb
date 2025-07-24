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
    // Verificar si el chofer tiene nombre o solo mostrar "No asignado"
    final choferTexto = (vehiculo.choferId?.isNotEmpty ?? false)
        ? 'Chofer: ${vehiculo.choferId}' // Aquí deberías cambiarlo por el nombre real si lo tienes
        : "Chofer: No asignado";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.local_shipping, size: 38),
        title: Text(
          '${vehiculo.numeroVehiculo} - ${vehiculo.placa}', // Asegúrate de que 'numeroVehiculo' es lo que quieres mostrar
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Estado: ${vehiculo.estado}\n$choferTexto', // Aquí mostramos el texto del chofer
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
