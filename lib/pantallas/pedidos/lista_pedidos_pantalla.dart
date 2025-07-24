import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListaPedidosPantalla extends StatefulWidget {
  @override
  _ListaPedidosPantallaState createState() => _ListaPedidosPantallaState();
}

class _ListaPedidosPantallaState extends State<ListaPedidosPantalla> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Función para obtener el nombre del cliente o chofer
  Future<String> _obtenerNombreUsuario(String usuarioId) async {
    DocumentSnapshot usuarioSnapshot = await _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .get();
    if (usuarioSnapshot.exists) {
      return usuarioSnapshot['nombre'] ?? 'Nombre no disponible';
    } else {
      return 'Usuario no encontrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Pedidos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('pedidos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay pedidos disponibles"));
          }

          var pedidos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              var pedido = pedidos[index];
              // Verificación para el campo clienteId
              var clienteId =
                  pedido['clienteId'] ??
                  'Desconocido'; // Valor predeterminado si no existe

              var choferId = pedido['choferId'] ?? 'Desconocido';
              var estado = pedido['estado'] ?? 'Pendiente';

              // Verificación para el campo fechaEstimada
              var fechaEstimada = pedido['fechaEstimada'];

              if (fechaEstimada is Timestamp) {
                fechaEstimada = fechaEstimada.toDate();
              } else if (fechaEstimada is String) {
                fechaEstimada = DateTime.parse(fechaEstimada);
              } else {
                fechaEstimada = DateTime.now();
              }

              // Formatear la fecha para que solo se muestre la fecha sin la hora
              String fechaFormateada =
                  "${fechaEstimada.day}/${fechaEstimada.month}/${fechaEstimada.year}";

              var ticketsId = pedido['ticketsId'] ?? 'No disponible';

              // Usamos FutureBuilder para obtener el nombre del cliente y chofer
              return FutureBuilder<List<String>>(
                future: Future.wait([
                  _obtenerNombreUsuario(clienteId), // Nombre del cliente
                  _obtenerNombreUsuario(choferId), // Nombre del chofer
                ]),
                builder: (context, snapshotNombre) {
                  if (snapshotNombre.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Pedido #$ticketsId'),
                      subtitle: Text('Cargando datos...'),
                    );
                  }

                  String nombreCliente = snapshotNombre.data![0];
                  String nombreChofer = snapshotNombre.data![1];

                  return ListTile(
                    title: Text('Pedido #$ticketsId'),
                    subtitle: Text(
                      'Cliente: $nombreCliente, Chofer: $nombreChofer\nEstado: $estado',
                    ),
                    trailing: Text('Fecha estimada: $fechaFormateada'),
                    onTap: () {
                      // Aquí puedes agregar lógica para navegar a un detalle del pedido
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
