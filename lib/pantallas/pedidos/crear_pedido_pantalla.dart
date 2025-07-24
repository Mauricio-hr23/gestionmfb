import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../modelos/pedido_modelo.dart';
import '../../servicios/pedido_servicio.dart';
import '../../servicios/ruta_servicio.dart'; // <--- Importante
import '../mapa/seleccionar_destino_pedido.dart'; // Importa la nueva pantalla
import '../../servicios/choferes_servicio.dart'; // Asegúrate de tener este servicio para cargar los choferes

class CrearPedidoPantalla extends StatefulWidget {
  const CrearPedidoPantalla({super.key});

  @override
  State<CrearPedidoPantalla> createState() => _CrearPedidoPantallaState();
}

class _CrearPedidoPantallaState extends State<CrearPedidoPantalla> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productosCtrl = TextEditingController();
  final TextEditingController _fechaCtrl = TextEditingController();

  String? _choferIdSeleccionado; // Cambié a choferId
  DateTime? _fechaEstimada;

  LatLng? _ubicacionSeleccionada;
  String? _nombreUbicacion;
  String?
  _idMarcaSeleccionada; // NUEVO: para guardar el id si seleccionó una marca

  bool _cargando = false;

  void _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaEstimada = picked;
        _fechaCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _seleccionarUbicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarDestinoPedidoPantalla(
          ubicacionInicial: _ubicacionSeleccionada,
        ),
      ),
    );
    if (resultado != null) {
      setState(() {
        _ubicacionSeleccionada = LatLng(
          resultado['latitud'],
          resultado['longitud'],
        );
        _nombreUbicacion = resultado['nombre'];
        _idMarcaSeleccionada =
            resultado['id']; // <-- NUEVO: recoge el id si lo hay
      });
    }
  }

  Future<void> _guardarPedido() async {
    if (!_formKey.currentState!.validate() ||
        _choferIdSeleccionado == null ||
        _fechaEstimada == null ||
        _ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa todos los campos, incluida la ubicación'),
        ),
      );
      return;
    }
    setState(() => _cargando = true);

    // Si la ubicación es una marca guardada, actualiza contador de usos
    if (_idMarcaSeleccionada != null) {
      await RutaServicio().incrementarUsoMarca(_idMarcaSeleccionada!);
    }

    final pedido = PedidoModelo(
      choferId:
          _choferIdSeleccionado!, // Aquí guardamos el choferId en lugar de clienteId
      ticketId: _productosCtrl.text.split(','),
      fechaEstimada: _fechaEstimada!,
      ubicacion: {
        'latitud': _ubicacionSeleccionada!.latitude,
        'longitud': _ubicacionSeleccionada!.longitude,
        'nombre': _nombreUbicacion,
        'id': _idMarcaSeleccionada, // opcional para trazabilidad
      },
    );
    await PedidoServicio().crearPedido(pedido);
    setState(() => _cargando = false);
    Navigator.pop(context); // O muestra un mensaje de éxito
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Chofer (usando StreamBuilder para obtener los choferes)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: ChoferesServicio().obtenerChoferesConUbicacion(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Espera la carga de los datos
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final choferes = snapshot.data ?? [];

                      return DropdownButtonFormField<String>(
                        value: _choferIdSeleccionado,
                        items: choferes.map((chofer) {
                          return DropdownMenuItem<String>(
                            // Especificamos el tipo String
                            value: chofer['id'], // Usar ID del chofer
                            child: Text(
                              chofer['nombre'],
                            ), // Mostrar el nombre del chofer
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _choferIdSeleccionado = v),
                        decoration: InputDecoration(labelText: 'Chofer'),
                        validator: (v) =>
                            v == null ? 'Selecciona un chofer' : null,
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  // UBICACIÓN EN EL MAPA (selección moderna)
                  ListTile(
                    leading: Icon(Icons.map),
                    title: _ubicacionSeleccionada == null
                        ? Text("Selecciona un punto en el mapa")
                        : (_nombreUbicacion != null
                              ? Text("Ubicación: $_nombreUbicacion")
                              : Text(
                                  "Ubicación: "
                                  "${_ubicacionSeleccionada!.latitude.toStringAsFixed(6)}, "
                                  "${_ubicacionSeleccionada!.longitude.toStringAsFixed(6)}",
                                )),
                    trailing: ElevatedButton(
                      onPressed: _seleccionarUbicacion,
                      child: Text("Seleccionar"),
                    ),
                    subtitle: _ubicacionSeleccionada == null
                        ? Text(
                            "Obligatorio para guardar el pedido",
                            style: TextStyle(color: Colors.red),
                          )
                        : null,
                  ),
                  SizedBox(height: 16),
                  // ticketId
                  TextFormField(
                    controller:
                        _productosCtrl, // Cambiar a un controlador adecuado para tickets
                    decoration: InputDecoration(
                      labelText:
                          'Ticket ID(s) (separa por coma)', // Modificar el texto a algo adecuado para 'ticketId'
                      hintText: 'ej: ticket1, ticket2, ticket3',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 16),
                  // FECHA ESTIMADA
                  TextFormField(
                    controller: _fechaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Fecha estimada',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: _seleccionarFecha,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Selecciona una fecha' : null,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _guardarPedido,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _cargando
                          ? CircularProgressIndicator()
                          : Text('Guardar Pedido'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
