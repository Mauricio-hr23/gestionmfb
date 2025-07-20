import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../mapa/mapa_tiempo_real_demo.dart'; // Usa la ruta real donde pegaste el archivo anterior

class PanelChoferPantalla extends StatefulWidget {
  const PanelChoferPantalla({super.key});

  @override
  State<PanelChoferPantalla> createState() => _PanelChoferPantallaState();
}

class _PanelChoferPantallaState extends State<PanelChoferPantalla> {
  Map<String, dynamic>? datosChofer;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatosChofer();
  }

  Future<void> cargarDatosChofer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    setState(() {
      datosChofer = doc.data();
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (cargando) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (datosChofer == null) {
      return Scaffold(
        body: Center(child: Text('No se encontraron datos de chofer')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Chofer'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navega a la pantalla de login o splash según tu app
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header de perfil
          Container(
            margin: EdgeInsets.only(top: 35, bottom: 16),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: datosChofer!['foto'] != null
                      ? NetworkImage(datosChofer!['foto'])
                      : null,
                  radius: 38,
                  child: datosChofer!['foto'] == null
                      ? Icon(Icons.person, size: 42)
                      : null,
                ),
                SizedBox(height: 10),
                Text(
                  "¡Hola, ${datosChofer!['nombre'] ?? 'Chofer'}!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Divider(),
          // Estado de la ubicación
          ListTile(
            leading: Icon(Icons.gps_fixed, color: Colors.green),
            title: Text('Ubicación en tiempo real'),
            subtitle: Text('Tu ubicación se está compartiendo con la central.'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
          // Botón para ir al mapa
          Padding(
            padding: EdgeInsets.symmetric(vertical: 22.0, horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 52),
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              icon: Icon(Icons.map_rounded, size: 30),
              label: Text(
                "Ver Mapa en Tiempo Real",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapaTiempoRealDemo(userId: user!.uid),
                  ),
                );
              },
            ),
          ),
          // Puedes poner más widgets aquí: pedidos asignados, incidencias, etc.
        ],
      ),
    );
  }
}
