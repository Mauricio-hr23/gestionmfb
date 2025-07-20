import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../proveedores/chofer_proveedor.dart';

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

  Future<void> _guardarChofer() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      cargando = true;
      error = null;
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
      Provider.of<ChoferProveedor>(context, listen: false).cargarChoferes();
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
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: correoCtrl,
                decoration: InputDecoration(labelText: "Correo"),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return "Correo inválido";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: passwordCtrl,
                decoration: InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "Mínimo 6 caracteres";
                  }
                  return null;
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
