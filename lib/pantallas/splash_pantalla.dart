import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashPantalla extends StatefulWidget {
  const SplashPantalla({super.key});

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    await Future.delayed(const Duration(seconds: 2)); // Simula carga/logo

    User? usuario = FirebaseAuth.instance.currentUser;

    if (usuario != null) {
      // Busca el documento del usuario en Firestore
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!doc.exists) {
        // Si el doc no existe, pide que contacte al admin o cerrar sesión
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final data = doc.data();
      if (data == null || !data.containsKey('rol')) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      String rol = data['rol'];
      if (rol == 'administrador') {
        Navigator.pushReplacementNamed(context, '/admin_menu');
      } else if (rol == 'chofer') {
        // Navigator.pushReplacementNamed(context, '/panel_chofer');
        Navigator.pushReplacementNamed(context, '/login'); // Temporal
      } else {
        // Navigator.pushReplacementNamed(context, '/panel_cliente');
        Navigator.pushReplacementNamed(context, '/login'); // Temporal
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
