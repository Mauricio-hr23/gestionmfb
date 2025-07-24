import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gestion_mfb/servicios/pedido_servicio.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class VerChoferesConRutasPantalla extends StatefulWidget {
  final String ticketId; // Recibimos el ticketId

  const VerChoferesConRutasPantalla({super.key, required this.ticketId});

  @override
  State<VerChoferesConRutasPantalla> createState() =>
      _VerChoferesConRutasPantallaState();
}

class _VerChoferesConRutasPantallaState
    extends State<VerChoferesConRutasPantalla> {
  List<Marker> _marcadoresChoferes = [];
  List<Marker> _marcadoresPedidos = [];
  List<Polyline> _rutas = [];
  final PedidoServicio _pedidoServicio = PedidoServicio();

  @override
  void initState() {
    super.initState();
    _obtenerDatosDelTicket(widget.ticketId); // Usamos el ticketId recibido
  }

  // Función para obtener los datos del ticket, incluyendo la ubicación del pedido y el chofer
  Future<void> _obtenerDatosDelTicket(String ticketId) async {
    try {
      // Ahora usamos Future en lugar de Stream y esperamos el resultado con await
      final pedidoSnapshot = await _pedidoServicio.obtenerPedidos(ticketId);

      if (pedidoSnapshot.isNotEmpty) {
        final pedidoData = pedidoSnapshot.first;
        final pedidoUbicacion = pedidoData['ubicacion'];
        final choferId = pedidoData['choferId'];

        // Mostrar el marcador de ubicación del pedido
        _marcadoresPedidos.add(
          Marker(
            point: pedidoUbicacion,
            width: 75,
            height: 75,
            child: MarcadorChoferWidget(
              nombre: "Pedido",
              esActivo: false,
              esPedido: true,
              onTap: () {
                print("Pedido seleccionado");
              },
            ),
          ),
        );

        // Ahora obtenemos la ubicación del chofer
        _obtenerUbicacionDelChofer(choferId);

        setState(() {});
      }
    } catch (e) {
      print('Error al obtener datos del ticket: $e');
    }
  }

  // Función para obtener la ubicación del chofer desde la colección 'usuarios'
  Future<void> _obtenerUbicacionDelChofer(String choferId) async {
    try {
      final choferDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(choferId)
          .get();

      if (choferDoc.exists) {
        final choferData = choferDoc.data()!;
        final choferUbicacion = choferData['ubicacion'];

        // Mostrar el marcador de ubicación del chofer
        _marcadoresChoferes.add(
          Marker(
            point: LatLng(
              choferUbicacion['latitude'],
              choferUbicacion['longitude'],
            ),
            width: 75,
            height: 75,
            child: MarcadorChoferWidget(
              nombre: choferData['nombre'],
              fotoUrl: choferData['foto_url'],
              esActivo: true,
              esPedido: false,
              onTap: () {
                print("Chofer seleccionado");
              },
            ),
          ),
        );

        setState(() {});
      }
    } catch (e) {
      print('Error al obtener la ubicación del chofer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ver Choferes con Rutas"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(), // Sin center ni zoom
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: {
              'accessToken':
                  'pk.eyJ1IjoicHJveWVjdG9zdXRjMjAyNSIsImEiOiJjbWRlM3ZibGowYmc5Mm1wd21xcWZxNGd5In0.ouOaou0lRTvJxf3W7IXlHQ',
              'id': 'mapbox/streets-v11',
            },
          ),
          MarkerLayer(markers: [..._marcadoresChoferes, ..._marcadoresPedidos]),
          PolylineLayer(polylines: _rutas),
        ],
      ),
    );
  }
}

// El widget de marcadores que contiene la animación y el diseño para chofer y pedido
class MarcadorChoferWidget extends StatefulWidget {
  final String nombre;
  final String? fotoUrl;
  final bool esActivo;
  final bool esPedido;
  final VoidCallback onTap;

  const MarcadorChoferWidget({
    required this.nombre,
    this.fotoUrl,
    required this.onTap,
    this.esActivo = false,
    this.esPedido = false,
    super.key,
  });

  @override
  State<MarcadorChoferWidget> createState() => _MarcadorChoferWidgetState();
}

class _MarcadorChoferWidgetState extends State<MarcadorChoferWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: false);
    _anim = Tween<double>(
      begin: 1,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.esPedido) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
            const SizedBox(height: 4),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (widget.esActivo)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 54 * _anim.value,
                height: 54 * _anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(
                    0.25 * (2 - _anim.value),
                  ),
                ),
              );
            },
          ),
        GestureDetector(
          onTap: widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.esActivo
                        ? Colors.blueAccent
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: widget.fotoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(widget.fotoUrl!),
                        radius: 22,
                      )
                    : const CircleAvatar(
                        radius: 22,
                        child: Icon(Icons.person, size: 24),
                      ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
