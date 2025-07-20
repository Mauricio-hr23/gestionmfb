import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarPantalla extends StatefulWidget {
  const RegistrarPantalla({super.key});

  @override
  State<RegistrarPantalla> createState() => _RegistrarPantallaState();
}

class _RegistrarPantallaState extends State<RegistrarPantalla> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  String _rol = "cliente";
  bool _cargando = false;
  String? _error;

  Future<void> _registrarUsuario() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      UserCredential credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _correoController.text.trim(),
            password: _contrasenaController.text,
          );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
            'nombre': _nombreController.text,
            'correo': _correoController.text,
            'rol': _rol,
            'estado': 'activo',
          });

      // Aquí puedes navegar a otra pantalla o mostrar mensaje de éxito
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = "Error desconocido");
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
            colors: [Colors.blueGrey.shade900, Colors.blue.shade500],
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
                        'Registro de Usuario',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: "Nombre completo",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Ingrese su nombre" : null,
                      ),
                      SizedBox(height: 18),
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
                            v!.length < 6 ? "Mínimo 6 caracteres" : null,
                      ),
                      SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _rol,
                        items: [
                          DropdownMenuItem(
                            value: "cliente",
                            child: Text("Cliente"),
                          ),
                          DropdownMenuItem(
                            value: "chofer",
                            child: Text("Chofer"),
                          ),
                          DropdownMenuItem(
                            value: "administrador",
                            child: Text("Administrador"),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _rol = value ?? "cliente"),
                        decoration: InputDecoration(
                          labelText: "Rol",
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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
                                    _registrarUsuario();
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
                                  "Registrarse",
                                  style: TextStyle(fontSize: 16),
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
