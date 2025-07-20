import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modelos/vehiculo_modelo.dart';
import '../../modelos/usuario_modelo.dart';

class EditarVehiculoPantalla extends StatefulWidget {
  final VehiculoModelo? vehiculo;
  const EditarVehiculoPantalla({super.key, this.vehiculo});

  @override
  State<EditarVehiculoPantalla> createState() => _EditarVehiculoPantallaState();
}

class _EditarVehiculoPantallaState extends State<EditarVehiculoPantalla> {
  final formKey = GlobalKey<FormState>();
  final modeloCtrl = TextEditingController();
  final placaCtrl = TextEditingController();
  final anioCtrl = TextEditingController();
  String estado = 'activo';
  String? fotoUrl;
  File? _fotoFile;
  String? error;
  UsuarioModelo? choferAsignado;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    if (v != null) {
      modeloCtrl.text = v.modelo;
      placaCtrl.text = v.placa;
      anioCtrl.text = v.anio?.toString() ?? '';
      estado = (v.estado.toLowerCase().trim() == 'activo')
          ? 'activo'
          : 'inactivo';
      fotoUrl = v.fotoUrl;
      _cargarChofer(v.choferId);
    }
  }

  Future<void> _cargarChofer(String? choferId) async {
    if (choferId != null && choferId.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(choferId)
          .get();
      if (snap.exists) {
        setState(() {
          choferAsignado = UsuarioModelo.fromMap(snap.data()!, snap.id);
        });
      }
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _fotoFile = File(picked.path));
  }

  Future<String?> _subirFoto(File archivo) async {
    final nombre =
        'vehiculos/${DateTime.now().millisecondsSinceEpoch}_${archivo.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child(nombre);
    await ref.putFile(archivo);
    return await ref.getDownloadURL();
  }

  Future<void> _guardar() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => cargando = true);

    try {
      String? url = fotoUrl;
      if (_fotoFile != null) {
        url = await _subirFoto(_fotoFile!);
      }

      final vehiculoData = {
        'modelo': modeloCtrl.text.trim(),
        'placa': placaCtrl.text.trim(),
        'anio': anioCtrl.text.trim(),
        'estado': estado.toLowerCase().trim(),
        'fotoUrl': url,
        'chofer_id': widget.vehiculo?.choferId ?? '',
      };

      if (widget.vehiculo == null) {
        // Crear nuevo
        await FirebaseFirestore.instance
            .collection('vehiculos')
            .add(vehiculoData);
      } else {
        // Editar existente
        await FirebaseFirestore.instance
            .collection('vehiculos')
            .doc(widget.vehiculo!.id)
            .update(vehiculoData);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Vehículo guardado')));
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehiculo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Editar Vehículo" : "Nuevo Vehículo"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto
              Center(
                child: GestureDetector(
                  onTap: _seleccionarFoto,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _fotoFile != null
                        ? FileImage(_fotoFile!)
                        : (fotoUrl != null && fotoUrl!.isNotEmpty
                                  ? NetworkImage(fotoUrl!)
                                  : null)
                              as ImageProvider?,
                    child:
                        _fotoFile == null &&
                            (fotoUrl == null || fotoUrl!.isEmpty)
                        ? Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: modeloCtrl,
                decoration: InputDecoration(labelText: 'Modelo'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese el modelo' : null,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: placaCtrl,
                decoration: InputDecoration(labelText: 'Placa'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese la placa' : null,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: anioCtrl,
                decoration: InputDecoration(labelText: 'Año'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // opcional
                  final n = int.tryParse(v);
                  if (n == null || n < 1900 || n > DateTime.now().year + 1) {
                    return "Año inválido";
                  }
                  return null;
                },
              ),
              SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: estado,
                items: [
                  DropdownMenuItem(value: "activo", child: Text("Activo")),
                  DropdownMenuItem(value: "inactivo", child: Text("Inactivo")),
                ],
                onChanged: (v) => setState(() => estado = v ?? "activo"),
                decoration: InputDecoration(labelText: "Estado"),
              ),
              SizedBox(height: 20),
              Text(
                "Chofer asignado:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              choferAsignado != null
                  ? Text(choferAsignado!.nombre)
                  : Text(
                      "No tiene chofer asignado",
                      style: TextStyle(color: Colors.grey),
                    ),
              SizedBox(height: 20),
              if (error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(error!, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cargando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: cargando
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? "Guardar cambios" : "Crear vehículo"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
