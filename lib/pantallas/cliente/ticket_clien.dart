import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketClienteScreen extends StatefulWidget {
  @override
  TicketClienteScreenState createState() => TicketClienteScreenState();
}

class TicketClienteScreenState extends State<TicketClienteScreen> {
  final TextEditingController _ticketController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  String choferId = ''; // Almacenar el choferId
  Map<String, dynamic>? choferData; // Almacenar los datos del chofer
  String estadoPedido = ''; // Almacenar el estado del pedido
  List<Map<String, dynamic>> productos = []; // Para los productos

  // Función para cargar los datos del ticket y el chofer desde Firestore
  Future<void> _cargarTicket() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      choferData = null; // Limpiar los datos del chofer anteriores
      productos.clear(); // Limpiar productos
    });

    String numeroTicket = _ticketController.text.trim();

    if (numeroTicket.isEmpty) {
      setState(() {
        errorMessage = 'Por favor ingrese un número de ticket.';
        isLoading = false;
      });
      return;
    }

    try {
      // Consulta la colección 'pedidos' usando el campo 'ticketsId'
      final pedidoDoc = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('ticketsId', isEqualTo: numeroTicket) // Buscar por ticketsId
          .get();

      if (pedidoDoc.docs.isNotEmpty) {
        // Obtener los datos del primer pedido que coincida
        var ticketData = pedidoDoc.docs[0]
            .data(); // Obtenemos el primer documento del ticket
        setState(() {
          estadoPedido =
              ticketData['estado'] ?? 'Estado no disponible'; // Obtener estado
          choferId = ticketData['choferId'] ?? ''; // Obtener choferId
        });

        // Usar el ticketsId para obtener los productos desde la colección 'tickets'
        await _obtenerProductosDeTicket(numeroTicket);

        // Obtener los datos del chofer usando el choferId
        if (choferId.isNotEmpty) {
          await _obtenerChofer(choferId);
        } else {
          setState(() {
            errorMessage = 'No se encontró el chofer para este ticket.';
          });
        }
      } else {
        setState(() {
          errorMessage = 'No se encontró el ticket. Verifique el número.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar el ticket: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para obtener los productos desde la colección 'tickets'
  Future<void> _obtenerProductosDeTicket(String ticketId) async {
    try {
      final ticketDoc = await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .get();

      if (ticketDoc.exists) {
        setState(() {
          productos = List<Map<String, dynamic>>.from(
            ticketDoc.data()!['productos'] ?? [],
          );
        });
      } else {
        setState(() {
          errorMessage = 'No se encontraron los productos para este ticket.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener los productos del ticket: $e';
      });
    }
  }

  // Función para obtener los datos del chofer desde la colección 'usuarios'
  Future<void> _obtenerChofer(String choferId) async {
    try {
      final choferDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(choferId)
          .get();

      if (choferDoc.exists) {
        setState(() {
          choferData = choferDoc.data(); // Guardar la data del chofer
        });
      } else {
        setState(() {
          errorMessage = 'No se encontró el chofer para este ticket.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener los datos del chofer: $e';
      });
    }
  }

  // Función para rastrear el pedido
  void _rastrearPedido() {
    if (choferData != null && choferId.isNotEmpty) {
      // Navegar al mapa con el choferId
      Navigator.pushNamed(
        context,
        '/mapa_tiempo_real',
        arguments: choferId, // Pasamos solo el choferId
      );
    } else {
      setState(() {
        errorMessage = 'No se pudo rastrear el pedido. Intente de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingresar Ticket'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        // Hacemos que la pantalla sea desplazable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ingrese el número de ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _ticketController,
                decoration: InputDecoration(
                  labelText: 'Número de Ticket',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargarTicket,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Cargar Ticket', style: TextStyle(fontSize: 16)),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (estadoPedido.isNotEmpty) ...[
                SizedBox(height: 24),
                Text(
                  'Estado del Pedido: $estadoPedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Mostrar los datos del chofer debajo del estado del pedido
                if (choferData != null) ...[
                  SizedBox(height: 20),
                  Text(
                    'Chofer Designado: ${choferData!['nombre']}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Placa: ${choferData!['placa'] ?? 'No disponible'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Teléfono: ${choferData!['telefono'] ?? 'No disponible'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
                // Mostrar productos en una tabla
                if (productos.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    'Productos:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Descripción')),
                      DataColumn(label: Text('Cantidad')),
                    ],
                    rows: productos.map((producto) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${producto['descripcion']}')),
                          DataCell(Text('${producto['cant']}')),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                // Botón para rastrear el pedido
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _rastrearPedido,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    'Rastrear Pedido',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
