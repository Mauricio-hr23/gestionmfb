import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../proveedores/chofer_proveedor.dart';
import '../../servicios/vehiculo_servicio.dart';
import '../../modelos/usuario_modelo.dart';
import '../../modelos/vehiculo_modelo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListaChoferesPantalla extends StatefulWidget {
  const ListaChoferesPantalla({super.key});

  @override
  State<ListaChoferesPantalla> createState() => _ListaChoferesPantallaState();
}

class _ListaChoferesPantallaState extends State<ListaChoferesPantalla> {
  Map<String, VehiculoModelo?> _vehiculosAsignados = {};
  final TextEditingController _buscarCtrl = TextEditingController();
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<ChoferProveedor>(context, listen: false).cargarChoferes(),
    );
    cargarAsignaciones();
  }

  Future<void> cargarAsignaciones() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vehiculos')
        .get();
    final vehiculos = snapshot.docs
        .map((doc) => VehiculoModelo.fromMap(doc.data(), doc.id))
        .toList();

    final asignados = <String, VehiculoModelo?>{};
    for (final v in vehiculos) {
      // Solo usamos chofer_id
      if ((v.choferId ?? '').isNotEmpty) {
        asignados[v.choferId!] = v;
      }
    }
    setState(() {
      _vehiculosAsignados = asignados;
    });
  }

  Future<void> asignarVehiculo(
    BuildContext context,
    UsuarioModelo chofer,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vehiculos')
        .get();
    final vehiculos = snapshot.docs
        .map((doc) => VehiculoModelo.fromMap(doc.data(), doc.id))
        .toList();
    final disponibles = vehiculos
        .where((v) => (v.choferId ?? '').isEmpty || v.choferId == chofer.id)
        .toList();

    String? seleccion = _vehiculosAsignados[chofer.id]?.id;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Asignar Vehículo a ${chofer.nombre}"),
        content: DropdownButtonFormField<String>(
          value: seleccion,
          items: disponibles
              .map(
                (v) => DropdownMenuItem(
                  value: v.id,
                  child: Text('${v.modelo} - ${v.placa}'),
                ),
              )
              .toList(),
          onChanged: (v) => seleccion = v,
          hint: Text("Seleccione un vehículo"),
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text("Asignar"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (seleccion != null && (seleccion?.isNotEmpty ?? false)) {
      await VehiculoServicio().asignarVehiculoAChofer(seleccion!, chofer.id);
      cargarAsignaciones();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Vehículo asignado")));
    }
  }

  List<UsuarioModelo> _filtrarChoferes(List<UsuarioModelo> choferes) {
    String texto = _buscarCtrl.text.toLowerCase();
    return choferes.where((c) {
      bool coincideBusqueda = c.nombre.toLowerCase().contains(texto);
      bool coincideEstado =
          _filtroEstado == 'todos' || c.estado == _filtroEstado;
      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choferes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Nuevo Chofer",
            onPressed: () => Navigator.pushNamed(context, '/agregar_chofer'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscarCtrl,
                    decoration: InputDecoration(
                      hintText: "Buscar chofer por nombre",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filtroEstado,
                  items: [
                    DropdownMenuItem(value: 'todos', child: Text("Todos")),
                    DropdownMenuItem(value: 'activo', child: Text("Activos")),
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
            child: Consumer<ChoferProveedor>(
              builder: (context, proveedor, _) {
                final choferesFiltrados = _filtrarChoferes(proveedor.choferes);
                if (choferesFiltrados.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay choferes registrados.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: choferesFiltrados.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, index) {
                    final chofer = choferesFiltrados[index];
                    final vehiculo = _vehiculosAsignados[chofer.id];
                    return ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text(chofer.nombre),
                      subtitle: Text(
                        'Estado: ${chofer.estado}\nVehículo: ${vehiculo != null ? "${vehiculo.modelo} - ${vehiculo.placa}" : "No asignado"}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.drive_eta),
                        tooltip: "Asignar Vehículo",
                        onPressed: () => asignarVehiculo(context, chofer),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
