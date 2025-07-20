import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditarPerfilAdminPantalla extends StatefulWidget {
  final String uidUsuario;
  const EditarPerfilAdminPantalla({super.key, required this.uidUsuario});

  @override
  State<EditarPerfilAdminPantalla> createState() =>
      _EditarPerfilAdminPantallaState();
}

class _EditarPerfilAdminPantallaState extends State<EditarPerfilAdminPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? _urlFoto;
  String _rol = "cliente";
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
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uidUsuario)
          .get();
      _nombreController.text = doc['nombre'] ?? '';
      _correoController.text = doc['correo'] ?? '';
      _telefonoController.text = doc['telefono'] ?? '';
      _urlFoto = doc['foto_url'];
      _rol = doc['rol'] ?? 'cliente';
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

  Future<String?> _subirFoto() async {
    if (_nuevaFoto == null) return _urlFoto;
    final ref = FirebaseStorage.instance.ref().child(
      'usuarios/${widget.uidUsuario}/foto_perfil.jpg',
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
      String? urlFoto = await _subirFoto();
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uidUsuario)
          .update({
            'nombre': _nombreController.text,
            'telefono': _telefonoController.text,
            'foto_url': urlFoto,
            'rol': _rol,
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

  Future<void> _eliminarUsuario() async {
    bool confirmado = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar usuario"),
        content: Text(
          "¿Seguro que deseas eliminar este usuario? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Eliminar"),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      setState(() => _cargando = true);
      try {
        // Elimina el usuario de Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.uidUsuario)
            .delete();
        // Elimina la foto de perfil si existe
        if (_urlFoto != null && _urlFoto!.isNotEmpty) {
          final ref = FirebaseStorage.instance.ref().child(
            'usuarios/${widget.uidUsuario}/foto_perfil.jpg',
          );
          await ref.delete();
        }
        // Puedes agregar aquí lógica para eliminar el usuario de Firebase Auth si quieres (requiere admin SDK en backend)
        setState(() {
          _mensaje = "Usuario eliminado";
        });
        // Regresar a la lista
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      } catch (e) {
        setState(() {
          _mensaje = "Error al eliminar usuario";
          _cargando = false;
        });
      }
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
      appBar: AppBar(title: Text('Editar Perfil (Admin)')),
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
                      enabled: false,
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
                        prefixIcon: Icon(Icons.verified_user),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_mensaje != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          _mensaje!,
                          style: TextStyle(
                            color:
                                _mensaje!.contains("actualizado") ||
                                    _mensaje!.contains("eliminado")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
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
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _cargando ? null : _eliminarUsuario,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.red,
                          ),
                          icon: Icon(Icons.delete, color: Colors.white),
                          label: Text(
                            "Eliminar",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
