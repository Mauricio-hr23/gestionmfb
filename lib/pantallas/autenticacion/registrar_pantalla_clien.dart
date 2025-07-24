import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart'; // Importando la librería de validación

class RegistrarPantallaclien extends StatefulWidget {
  const RegistrarPantallaclien({super.key});

  @override
  State<RegistrarPantallaclien> createState() => _RegistrarPantallaStateclien();
}

class _RegistrarPantallaStateclien extends State<RegistrarPantallaclien> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final String _rol = "cliente"; // El rol es fijo
  bool _cargando = false;
  String? _error;
  String? _dominioError;

  // Lista blanca de dominios comunes y populares
  final List<String> domainsWhitelist = [
    "gmail.com",
    "hotmail.com",
    "outlook.com",
    "yahoo.com",
    "icloud.com",
    "aol.com",
  ];

  Future<void> _registrarUsuario() async {
    setState(() {
      _cargando = true;
      _error = null;
      _dominioError =
          null; // Limpiar el error de dominio al intentar registrarse
    });
    try {
      // Intentamos registrar el usuario en Firebase Auth
      UserCredential credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _correoController.text.trim(),
            password: _contrasenaController.text,
          );

      // Si el registro es exitoso, guardamos los datos del usuario en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
            'nombre': _nombreController.text,
            'correo': _correoController.text,
            'rol': _rol,
            'estado': 'activo',
          });

      // Redirigir al usuario a la pantalla de inicio de sesión
      Navigator.pushReplacementNamed(
        context,
        '/login', // Actualizamos la ruta para que coincida con la definida en tu main.dart
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message); // Si ocurre un error con FirebaseAuth
    } catch (e) {
      setState(() => _error = "Error desconocido"); // Manejo de otros errores
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<bool> _isDomainWhitelisted(String domain) async {
    // Verifica si el dominio está en la lista blanca
    return domainsWhitelist.contains(domain);
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
                      // Campo de nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: "Nombre completo",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          RegExp regExp = RegExp(r'^[a-zA-Z\s]+$');
                          return regExp.hasMatch(v!)
                              ? null
                              : "Ingrese un nombre válido (solo letras y espacios)";
                        },
                      ),
                      SizedBox(height: 18),
                      // Campo de correo electrónico
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
                        // Validación síncrona en el 'validator' para formato
                        validator: (v) {
                          // Validación básica de formato
                          if (!EmailValidator.validate(v!)) {
                            return "Correo electrónico con formato incorrecto";
                          }
                          final emailParts = v.split('@');
                          if (emailParts.length != 2) {
                            return "Correo electrónico con formato incorrecto";
                          }
                          return null; // Si el formato es correcto
                        },
                        onChanged: (v) async {
                          // Verificación de dominio (ejemplo básico)
                          if (EmailValidator.validate(v)) {
                            final emailParts = v.split('@');
                            if (emailParts.length == 2) {
                              // Verificación de existencia del dominio
                              final domain = emailParts[1];
                              bool isWhitelisted = await _isDomainWhitelisted(
                                domain,
                              );
                              if (!isWhitelisted) {
                                setState(() {
                                  _dominioError =
                                      "Dominio no válido o inexistente";
                                });
                              } else {
                                setState(() {
                                  _dominioError = null; // Dominio válido
                                });
                              }
                            }
                          }
                        },
                      ),
                      if (_dominioError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _dominioError!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      SizedBox(height: 18),
                      // Campo de contraseña
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
                        validator: (v) {
                          String password = v!;

                          // Verificar longitud mínima de 8 caracteres
                          if (password.length < 8) {
                            return "La contraseña debe tener al menos 8 caracteres";
                          }

                          // Verificar que contenga al menos una letra mayúscula
                          if (!password.contains(RegExp(r'[A-Z]'))) {
                            return "La contraseña debe contener al menos una letra mayúscula";
                          }

                          // Verificar que contenga al menos una letra minúscula
                          if (!password.contains(RegExp(r'[a-z]'))) {
                            return "La contraseña debe contener al menos una letra minúscula";
                          }

                          // Verificar que contenga al menos un número
                          if (!password.contains(RegExp(r'[0-9]'))) {
                            return "La contraseña debe contener al menos un número";
                          }

                          // Verificar que contenga al menos un símbolo especial
                          if (!password.contains(RegExp(r'[@$!%*?&]'))) {
                            return "La contraseña debe contener al menos un símbolo especial";
                          }

                          return null; // Si pasa todas las validaciones
                        },
                      ),
                      SizedBox(height: 24),
                      // Si hay un error, se muestra aquí
                      if (_error != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      // Botón de registro
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cargando
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _registrarUsuario(); // Registramos al usuario
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
