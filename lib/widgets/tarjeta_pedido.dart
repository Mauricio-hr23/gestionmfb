import 'package:flutter/material.dart';
import '../modelos/pedido_modelo.dart';

class TarjetaPedido extends StatelessWidget {
  final PedidoModelo pedido;
  final VoidCallback? onTap;

  const TarjetaPedido({required this.pedido, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    Color colorEstado;
    switch (pedido.estado) {
      case 'en curso':
        colorEstado = Colors.orange;
        break;
      case 'completado':
        colorEstado = Colors.green;
        break;
      default:
        colorEstado = Colors.blueGrey;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ListTile(
        onTap: onTap,

        leading: CircleAvatar(
          backgroundColor: colorEstado,
          child: Icon(Icons.local_shipping, color: Colors.white),
        ),
        title: Text(
          "Pedido de ${pedido.clienteId}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Productos: ${pedido.productos.join(", ")}"),
            Text(
              "Fecha estimada: ${pedido.fechaEstimada.day}/${pedido.fechaEstimada.month}/${pedido.fechaEstimada.year}",
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              "Estado: ${pedido.estado.toUpperCase()}",
              style: TextStyle(fontWeight: FontWeight.bold, color: colorEstado),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.black38),
      ),
    );
  }
}
