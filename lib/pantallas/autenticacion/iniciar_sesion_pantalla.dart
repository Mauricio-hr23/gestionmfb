import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IniciarSesionPantalla extends StatefulWidget {
  const IniciarSesionPantalla({super.key});

  @override
  State<IniciarSesionPantalla> createState() => _IniciarSesionPantallaState();
}

class _IniciarSesionPantallaState extends State<IniciarSesionPantalla> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      UserCredential credencial = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _correoController.text.trim(),
            password: _contrasenaController.text,
          );
      print('UID: ${credencial.user!.uid}'); // <-- AQUÍ

      DocumentSnapshot usuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .get();
      print('Usuario exists: ${usuario.exists}'); // <-- AQUÍ
      print('Usuario data: ${usuario.data()}'); // <-- AQUÍ

      if (!usuario.exists) {
        setState(
          () => _error =
              'No existe documento de usuario en Firestore. Contacta al administrador.',
        );
        return;
      }

      final data = usuario.data() as Map<String, dynamic>?;
      print('Data: $data'); // <-- AQUÍ
      if (data == null || !data.containsKey('rol')) {
        setState(
          () => _error = 'El documento de usuario no tiene el campo "rol".',
        );
        return;
      }
      String rol = data['rol'];
      print('ROL: $rol'); // <-- AQUÍ

      // Navega según el rol
      if (rol == 'administrador') {
        Navigator.pushReplacementNamed(context, '/admin_menu');
      } else if (rol == 'chofer') {
        Navigator.pushReplacementNamed(context, '/panel_chofer');
      } else if (rol == 'cliente') {
        // Navigator.pushReplacementNamed(context, '/panel_cliente');
      } else {
        setState(() => _error = 'Rol de usuario no reconocido.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Auth error: ${e.code} - ${e.message}');
      print('Auth error: ${e.code} - ${e.message}'); // <-- AQUÍ
    } catch (e) {
      setState(() => _error = 'Firestore error: $e');
      print('Firestore error: $e'); // <-- AQUÍ
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blueGrey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              margin: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        controller: _correoController,
                        decoration: InputDecoration(
                          labelText: "Correo electrónico",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.contains('@')
                            ? null
                            : "Correo electrónico inválido",
                      ),
                      SizedBox(height: 18),
                      TextFormField(
                        controller: _contrasenaController,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        obscureText: true,
                        validator: (v) =>
                            v!.isEmpty ? "Ingrese su contraseña" : null,
                      ),
                      SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cargando
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _iniciarSesion();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: _cargando
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Iniciar Sesión",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // BOTÓN AGREGADO: Ir a registro
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/registro');
                        },
                        child: Text(
                          "¿No tienes cuenta? Regístrate aquí",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // BOTÓN AGREGADO: Recuperar contraseña
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/recuperar');
                        },
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
