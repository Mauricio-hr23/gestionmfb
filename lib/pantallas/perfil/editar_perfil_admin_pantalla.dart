import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _rol =
      "cliente"; // Aun lo mantenemos, pero no se mostrará ni podrá ser editado
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
      _rol =
          doc['rol'] ??
          'cliente'; // Aunque no sea editable, seguimos obteniendo el rol
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
    if (_nuevaFoto == null)
      return _urlFoto; // Si no hay nueva foto, retorna la URL existente.

    final ref = FirebaseStorage.instance.ref().child(
      'usuarios/${widget.uidUsuario}/foto_perfil.jpg',
    );

    try {
      // Subir nueva foto
      await ref.putFile(_nuevaFoto!);

      // Obtener la URL de la foto cargada
      String downloadURL = await ref.getDownloadURL();

      return downloadURL; // Retornar la URL pública de la imagen
    } catch (e) {
      // Si ocurre un error, manejarlo adecuadamente
      print("Error al subir la foto: $e");
      return null;
    }
  }

  // Validación estricta para el número de teléfono
  bool _validarTelefono(String telefono) {
    // Limpiar el número para quitar espacios, guiones y otros caracteres no numéricos
    String numeroLimpiado = telefono.replaceAll(
      RegExp(r'\D'),
      '',
    ); // Quita todo lo que no sea número

    // Verificar que tenga exactamente 10 dígitos y comience con '09'
    final regex = RegExp(r'^09\d{8}$');
    return regex.hasMatch(numeroLimpiado);
  }

  // Validación del nombre para solo permitir letras y espacios
  bool _validarNombre(String nombre) {
    final regex = RegExp(r'^[A-Za-zÁáÉéÍíÓóÚúÑñ\s]+$');
    return regex.hasMatch(nombre);
  }

  Future<void> _guardarPerfil() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });

    // Validación de nombre
    String nombre = _nombreController.text;
    if (nombre.isEmpty) {
      setState(() {
        _mensaje = "Por favor ingrese un nombre.";
      });
      setState(() => _cargando = false);
      return;
    }

    if (!_validarNombre(nombre)) {
      setState(() {
        _mensaje = "El nombre solo debe contener letras y espacios.";
      });
      setState(() => _cargando = false);
      return;
    }

    // Validación de número de teléfono
    String telefono = _telefonoController.text;
    if (telefono.isEmpty) {
      setState(() {
        _mensaje = "Por favor ingrese un número de teléfono.";
      });
      setState(() => _cargando = false);
      return;
    }

    // Verificar si el número tiene letras o caracteres no numéricos
    if (!RegExp(r'^[0-9]+$').hasMatch(telefono)) {
      setState(() {
        _mensaje =
            "Número de teléfono inválido. Debe tener 10 dígitos, comenzar con 09 y no contener letras ni caracteres especiales.";
      });
      setState(() => _cargando = false);
      return;
    }

    // Validar que el número cumpla con la estructura correcta
    if (!_validarTelefono(telefono)) {
      setState(() {
        _mensaje =
            "Número de teléfono inválido. Debe tener 10 dígitos y comenzar con 09.";
      });
      setState(() => _cargando = false);
      return;
    }

    try {
      String? urlFoto = await _subirFoto();
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uidUsuario)
          .update({
            'nombre': nombre,
            'telefono': telefono,
            'foto_url': urlFoto,
            // El rol no se actualiza ya que no es editable
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
        // Regresar a la lista
        setState(() {
          _mensaje = "Usuario eliminado";
        });
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
      appBar: AppBar(title: Text('Editar Perfil de Usuario')),
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
                              ? FileImage(
                                  _nuevaFoto!,
                                ) // Usar la nueva foto seleccionada
                              : (_urlFoto != null && _urlFoto!.isNotEmpty)
                              ? NetworkImage(_urlFoto!)
                                    as ImageProvider // Usar la foto de Firebase
                              : null, // No se asigna ninguna imagen predeterminada
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
