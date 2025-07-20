import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../proveedores/vehiculo_proveedor.dart';
import '../../widgets/tarjeta_vehiculo.dart';
import '../vehiculos/editar_vehiculo_pantalla.dart';
import '../../modelos/vehiculo_modelo.dart';

class ListaVehiculosPantalla extends StatefulWidget {
  const ListaVehiculosPantalla({super.key});

  @override
  State<ListaVehiculosPantalla> createState() => _ListaVehiculosPantallaState();
}

class _ListaVehiculosPantallaState extends State<ListaVehiculosPantalla> {
  String _busqueda = '';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<VehiculoProveedor>(
        context,
        listen: false,
      ).cargarVehiculos(),
    );
  }

  List<VehiculoModelo> _filtrarVehiculos(List<VehiculoModelo> vehiculos) {
    return vehiculos.where((v) {
      final texto = _busqueda.toLowerCase();
      final coincideBusqueda =
          v.modelo.toLowerCase().contains(texto) ||
          v.placa.toLowerCase().contains(texto);
      final coincideEstado =
          _filtroEstado == 'todos' || v.estado == _filtroEstado;
      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehículos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Nuevo Vehículo",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditarVehiculoPantalla()),
              );
              Provider.of<VehiculoProveedor>(
                context,
                listen: false,
              ).cargarVehiculos();
            },
          ),
        ],
      ),
      body: Consumer<VehiculoProveedor>(
        builder: (context, proveedor, _) {
          final vehiculosFiltrados = _filtrarVehiculos(proveedor.vehiculos);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar por modelo, placa o chofer',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) => setState(() => _busqueda = value),
                      ),
                    ),
                    SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _filtroEstado,
                      items: [
                        DropdownMenuItem(value: 'todos', child: Text("Todos")),
                        DropdownMenuItem(
                          value: 'activo',
                          child: Text("Activos"),
                        ),
                        DropdownMenuItem(
                          value: 'inactivo',
                          child: Text("Inactivos"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroEstado = value ?? 'todos');
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: vehiculosFiltrados.isEmpty
                    ? Center(child: Text("No hay vehículos registrados"))
                    : ListView.builder(
                        itemCount: vehiculosFiltrados.length,
                        itemBuilder: (context, index) {
                          final vehiculo = vehiculosFiltrados[index];
                          return TarjetaVehiculo(
                            vehiculo: vehiculo,
                            onEdit: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditarVehiculoPantalla(
                                    vehiculo: vehiculo,
                                  ),
                                ),
                              );
                              Provider.of<VehiculoProveedor>(
                                context,
                                listen: false,
                              ).cargarVehiculos();
                            },
                            onDelete: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("¿Eliminar vehículo?"),
                                  content: Text(
                                    "¿Seguro que deseas eliminar este vehículo?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text("Eliminar"),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                Provider.of<VehiculoProveedor>(
                                  context,
                                  listen: false,
                                ).eliminarVehiculo(vehiculo.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
