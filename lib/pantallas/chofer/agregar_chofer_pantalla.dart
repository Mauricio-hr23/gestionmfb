import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart'; // Importando la librería de validación

class AgregarChoferPantalla extends StatefulWidget {
  const AgregarChoferPantalla({super.key});

  @override
  State<AgregarChoferPantalla> createState() => _AgregarChoferPantallaState();
}

class _AgregarChoferPantallaState extends State<AgregarChoferPantalla> {
  final formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  String estado = "activo";
  bool cargando = false;
  String? error;
  String? dominioError;

  // Lista blanca de dominios comunes y populares
  final List<String> domainsWhitelist = [
    "gmail.com",
    "hotmail.com",
    "outlook.com",
    "yahoo.com",
    "icloud.com",
    "aol.com",
  ];

  Future<void> _guardarChofer() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      cargando = true;
      error = null;
      dominioError = null;
    });

    // ------ VALIDACIÓN DE ADMIN ------
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (doc.data()?['rol'] != 'administrador') {
      setState(() {
        error = 'Solo admins pueden registrar choferes';
        cargando = false;
      });
      return;
    }
    // ------ FIN VALIDACIÓN DE ADMIN ------

    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: correoCtrl.text.trim(),
            password: passwordCtrl.text.trim(),
          );
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'nombre': nombreCtrl.text.trim(),
            'correo': correoCtrl.text.trim(),
            'rol': 'chofer',
            'estado': estado,
          });
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chofer creado')));
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = 'Error interno: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  Future<bool> _isDomainWhitelisted(String domain) async {
    // Verifica si el dominio está en la lista blanca
    return domainsWhitelist.contains(
      domain,
    ); // Si el dominio está en la lista blanca, lo acepta
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nuevo Chofer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: InputDecoration(labelText: "Nombre"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Ingrese nombre";
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return "El nombre solo puede contener letras";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: correoCtrl,
                decoration: InputDecoration(labelText: "Correo"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !EmailValidator.validate(value)) {
                    return "Correo electrónico con formato incorrecto";
                  }
                  return null;
                },
                onChanged: (v) async {
                  // Verificación del dominio de forma asíncrona
                  final emailParts = v.split('@');
                  if (emailParts.length == 2) {
                    final domain = emailParts[1];
                    bool isWhitelisted = await _isDomainWhitelisted(domain);
                    if (!isWhitelisted) {
                      setState(() {
                        dominioError =
                            "Dominio de correo no permitido o inválido";
                      });
                    } else {
                      setState(() {
                        dominioError = null;
                      });
                    }
                  }
                },
              ),
              if (dominioError != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    dominioError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 16),
              // Campo de contraseña con validaciones
              TextFormField(
                controller: passwordCtrl,
                decoration: InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (value) {
                  String password = value!;

                  // Validaciones de contraseña
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: estado,
                items: [
                  DropdownMenuItem(value: "activo", child: Text("Activo")),
                  DropdownMenuItem(value: "inactivo", child: Text("Inactivo")),
                ],
                onChanged: (v) => setState(() => estado = v!),
                decoration: InputDecoration(labelText: "Estado"),
              ),
              SizedBox(height: 28),
              if (error != null) ...[
                Text(error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cargando ? null : _guardarChofer,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: cargando
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Guardar", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
