import 'package:flutter/material.dart';
import '../../servicios/pedido_servicio.dart';
import '../../widgets/tarjeta_pedido.dart';
import '../../modelos/pedido_modelo.dart';
import 'asignar_pedido_pantalla.dart';
import 'seguimiento_pedido_pantalla.dart';

class ListaPedidosPantalla extends StatefulWidget {
  const ListaPedidosPantalla({super.key});

  @override
  State<ListaPedidosPantalla> createState() => _ListaPedidosPantallaState();
}

class _ListaPedidosPantallaState extends State<ListaPedidosPantalla> {
  String filtroEstado = 'todos';
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Pedidos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}), // Forzar refresco
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // FILTROS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: filtroEstado,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'en curso',
                      child: Text('En Curso'),
                    ),
                    DropdownMenuItem(
                      value: 'completado',
                      child: Text('Completado'),
                    ),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      filtroEstado = valor!;
                    });
                  },
                ),
                // BÚSQUEDA
                SizedBox(
                  width: 180,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Buscar cliente o producto",
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (valor) {
                      setState(() {
                        busqueda = valor.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // LISTA DE PEDIDOS
            Expanded(
              child: StreamBuilder<List<PedidoModelo>>(
                stream: PedidoServicio().obtenerPedidos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final pedidos = snapshot.data ?? [];

                  // FILTRADO por estado y búsqueda
                  final pedidosFiltrados = pedidos.where((pedido) {
                    final coincideEstado =
                        filtroEstado == 'todos' ||
                        pedido.estado == filtroEstado;
                    final coincideBusqueda =
                        busqueda.isEmpty ||
                        pedido.clienteId.toLowerCase().contains(busqueda) ||
                        pedido.productos.any(
                          (p) => p.toLowerCase().contains(busqueda),
                        );
                    return coincideEstado && coincideBusqueda;
                  }).toList();

                  if (pedidosFiltrados.isEmpty) {
                    return const Center(
                      child: Text('No hay pedidos con ese criterio.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: pedidosFiltrados.length,
                    itemBuilder: (context, i) {
                      final pedido = pedidosFiltrados[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: TarjetaPedido(
                          pedido: pedido,
                          onTap: () {
                            if (pedido.estado.toLowerCase() == 'pendiente') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AsignarPedidoPantalla(pedido: pedido),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SeguimientoPedidoPantalla(
                                    pedidoId: pedido.id!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
