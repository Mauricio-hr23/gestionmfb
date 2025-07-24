import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/pedido_modelo.dart';
import '../../servicios/pedido_servicio.dart';

class SeguimientoPedidoPantalla extends StatelessWidget {
  final String pedidoId;

  const SeguimientoPedidoPantalla({required this.pedidoId, super.key});

  static const List<String> _estados = [
    "pendiente",
    "preparando",
    "en camino",
    "entregado",
    "cancelado",
  ];

  Future<String?> _obtenerRolUsuarioActual() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['rol'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _obtenerRolUsuarioActual(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Seguimiento de Pedido')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final rol = snapshot.data;
        final puedeActualizarEstado = rol == 'administrador' || rol == 'chofer';

        return Scaffold(
          appBar: AppBar(title: const Text('Seguimiento de Pedido')),
          body: StreamBuilder<PedidoModelo?>(
            stream: PedidoServicio().escucharPedidoPorId(pedidoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No se encontró el pedido.'));
              }
              final pedido = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(18.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cliente: ${pedido.choferId}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text("Productos: ${pedido.ticketId.join(', ')}"),
                        Text(
                          "Fecha estimada: ${pedido.fechaEstimada.day}/${pedido.fechaEstimada.month}/${pedido.fechaEstimada.year}",
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text(
                              "Estado actual: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(pedido.estado.toUpperCase()),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (puedeActualizarEstado) ...[
                          const Text(
                            "Actualizar estado:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 10,
                            children: _estados
                                .where((e) => e != pedido.estado)
                                .map(
                                  (estado) => ElevatedButton(
                                    onPressed: () async {
                                      await PedidoServicio()
                                          .actualizarEstadoPedido(
                                            pedido.id!,
                                            estado,
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Estado actualizado a "$estado"',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(estado.toUpperCase()),
                                  ),
                                )
                                .toList(),
                          ),
                        ] else
                          const Text(
                            "Solo personal autorizado puede actualizar el estado.",
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
