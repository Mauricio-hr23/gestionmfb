import 'package:flutter/material.dart';
import '../../modelos/pedido_modelo.dart';
import '../../modelos/usuario_modelo.dart';
import '../../servicios/pedido_servicio.dart';
import '../../servicios/usuario_servicio.dart';
import '../../widgets/tarjeta_chofer.dart';

class AsignarPedidoPantalla extends StatefulWidget {
  final PedidoModelo pedido;

  const AsignarPedidoPantalla({required this.pedido, super.key});

  @override
  State<AsignarPedidoPantalla> createState() => _AsignarPedidoPantallaState();
}

class _AsignarPedidoPantallaState extends State<AsignarPedidoPantalla> {
  late Future<List<UsuarioModelo>> _futureChoferes;
  bool _asignando = false;

  @override
  void initState() {
    super.initState();
    _futureChoferes = UsuarioServicio().obtenerChoferesDisponibles();
  }

  Future<void> asignarChofer(String choferId) async {
    setState(() => _asignando = true);
    await PedidoServicio().asignarPedidoAChofer(widget.pedido.id!, choferId);
    setState(() => _asignando = false);
    // Opcional: puedes mostrar un mensaje de éxito aquí
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Pedido asignado correctamente')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asignar Chofer al Pedido')),
      body: _asignando
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<UsuarioModelo>>(
              future: _futureChoferes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay choferes disponibles'),
                  );
                }

                final choferes = snapshot.data!;
                return ListView.builder(
                  itemCount: choferes.length,
                  itemBuilder: (context, i) {
                    final chofer = choferes[i];
                    return TarjetaChofer(
                      chofer: chofer,
                      onTap: () => asignarChofer(chofer.id),
                    );
                  },
                );
              },
            ),
    );
  }
}
