import 'package:flutter/material.dart';
import 'package:gestion_mfb/pantallas/mapa/gestionar_marcas_mapa.dart';
import 'package:gestion_mfb/pantallas/mapa/estadisticas_ubicaciones.dart';
import 'package:gestion_mfb/pantallas/mapa/mapa_calor_pedidos.dart';
import 'package:gestion_mfb/pantallas/mapa/analisis_geografico_pedidos.dart';
import 'package:gestion_mfb/pantallas/mapa/analisis_cuadrantes_pedidos.dart';
import 'package:gestion_mfb/pantallas/rutas/ruta_pantalla.dart';
import 'package:gestion_mfb/pantallas/rutas/ver_choferes_con_rutas.dart';
import 'package:gestion_mfb/servicios/pedido_servicio.dart'; // Asegúrate de que esta ruta sea correcta

class AdminMenuPantalla extends StatelessWidget {
  const AdminMenuPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        backgroundColor: Colors.transparent, // Hacer la AppBar transparente
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.purple.shade800,
            ], // Fondo degradado
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: GridView.count(
            crossAxisCount: 1,
            childAspectRatio: 2.5,
            mainAxisSpacing: 28,
            children: [
              _AdminMenuCard(
                color: Colors.blue.shade700,
                icon: Icons.people,
                title: 'Gestión de Usuarios',
                onTap: () => Navigator.pushNamed(context, '/lista_usuarios'),
              ),
              _AdminMenuCard(
                color: Colors.green.shade700,
                icon: Icons.local_shipping,
                title: 'Gestión de Vehículos',
                onTap: () => Navigator.pushNamed(context, '/vehiculos'),
              ),
              _AdminMenuCard(
                color: Colors.orange.shade700,
                icon: Icons.person,
                title: 'Gestión de Choferes',
                onTap: () => Navigator.pushNamed(context, '/choferes'),
              ),
              _AdminMenuCard(
                color: Colors.purple.shade700,
                icon: Icons.add_box_outlined,
                title: 'Crear Pedido',
                onTap: () => Navigator.pushNamed(context, '/crear-pedido'),
              ),
              _AdminMenuCard(
                color: Colors.teal.shade700,
                icon: Icons.list_alt_rounded,
                title: 'Lista de Pedidos',
                onTap: () => Navigator.pushNamed(context, '/lista-pedidos'),
              ),
              _AdminMenuCard(
                color: Colors.purple.shade700,
                icon: Icons.edit_location_alt,
                title: 'Editar/Eliminar ubicaciones',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GestionarMarcasMapaPantalla(),
                  ),
                ),
              ),
              _AdminMenuCard(
                color: Colors.deepPurple.shade700,
                icon: Icons.local_fire_department,
                title: 'Mapa de calor de pedidos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapaCalorPedidosPantalla(),
                    ),
                  );
                },
              ),
              _AdminMenuCard(
                color: Colors.indigo.shade700,
                icon: Icons.analytics,
                title: 'Análisis geográfico',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalisisGeograficoPedidosPantalla(),
                  ),
                ),
              ),
              _AdminMenuCard(
                color: Colors.green.shade800,
                icon: Icons.grid_on,
                title: 'Análisis por cuadrantes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalisisCuadrantesPedidosPantalla(),
                  ),
                ),
              ),
              _AdminMenuCard(
                color: Colors.green.shade800,
                icon: Icons.grid_on,
                title: 'Ver Ruta del Chofer',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RutaPantalla(choferId: "123"),
                  ),
                ),
              ),
              //
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EstadisticasUbicacionesPantalla(),
                    ),
                  );
                },
                child: Text("Ver Estadísticas de Ubicaciones"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300), // Animación al tocar
      curve: Curves.easeInOut,
      child: Card(
        elevation: 6,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
            child: ListTile(
              leading: Icon(icon, color: Colors.white, size: 38),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
