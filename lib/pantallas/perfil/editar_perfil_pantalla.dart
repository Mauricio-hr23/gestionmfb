import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditarPerfilPantalla extends StatefulWidget {
  const EditarPerfilPantalla({super.key});

  @override
  State<EditarPerfilPantalla> createState() => _EditarPerfilPantallaState();
}

class _EditarPerfilPantallaState extends State<EditarPerfilPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? _urlFoto;
  File? _nuevaFoto;
  bool _cargando = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  Future<void> _cargarDatosPerfil() async {
    setState(() => _cargando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      _nombreController.text = doc['nombre'] ?? '';
      _correoController.text = doc['correo'] ?? '';
      _telefonoController.text = doc['telefono'] ?? '';
      _urlFoto = doc['foto_url'];
      setState(() {});
    } catch (e) {
      setState(() => _mensaje = "Error cargando perfil");
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _nuevaFoto = File(pickedFile.path);
      });
    }
  }

  Future<String?> _subirFoto(String uid) async {
    if (_nuevaFoto == null) return _urlFoto;
    final ref = FirebaseStorage.instance.ref().child(
      'usuarios/$uid/foto_perfil.jpg',
    );
    await ref.putFile(_nuevaFoto!);
    return await ref.getDownloadURL();
  }

  Future<void> _guardarPerfil() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? urlFoto = await _subirFoto(uid);
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'nombre': _nombreController.text,
        'telefono': _telefonoController.text,
        'foto_url': urlFoto,
      });
      setState(() {
        _mensaje = "Perfil actualizado correctamente";
        _urlFoto = urlFoto;
        _nuevaFoto = null;
      });
    } catch (e) {
      setState(() => _mensaje = "Error al actualizar perfil");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = 110.0;
    return Scaffold(
      appBar: AppBar(title: Text('Editar Perfil')),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: imgSize / 2,
                          backgroundImage: _nuevaFoto != null
                              ? FileImage(_nuevaFoto!)
                              : (_urlFoto != null && _urlFoto!.isNotEmpty)
                              ? NetworkImage(_urlFoto!) as ImageProvider
                              : AssetImage('assets/avatar_default.png'),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Material(
                            color: Colors.white,
                            shape: CircleBorder(),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 28,
                                color: Colors.blueAccent,
                              ),
                              onPressed: _seleccionarFoto,
                            ),
                          ),
                        ),
                      ],
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
                      validator: (v) => v!.isEmpty ? "Ingrese su nombre" : null,
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      controller: _correoController,
                      enabled:
                          false, // solo lectura, quita esto si quieres permitir editar
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: "Teléfono",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.length < 8
                          ? "Ingrese un teléfono válido"
                          : null,
                    ),
                    SizedBox(height: 24),
                    if (_mensaje != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          _mensaje!,
                          style: TextStyle(
                            color: _mensaje!.contains("actualizado")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _cargando
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _guardarPerfil();
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
                                "Guardar cambios",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
