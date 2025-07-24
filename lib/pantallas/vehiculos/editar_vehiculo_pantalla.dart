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
  final numeroVehiculoCtrl = TextEditingController();
  final placaCtrl = TextEditingController();
  final anioCtrl = TextEditingController();
  String estado = 'activo';
  String? fotoUrl;
  File? _fotoFile;
  String? error;
  UsuarioModelo? choferAsignado;
  List<UsuarioModelo> choferesDisponibles =
      []; // Para cargar los choferes disponibles
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarChoferesDisponibles(); // Cargar choferes disponibles al inicio

    final v = widget.vehiculo;
    if (v != null) {
      numeroVehiculoCtrl.text = v.numeroVehiculo; // No editable
      placaCtrl.text = v.placa; // No editable
      anioCtrl.text = v.anio?.toString() ?? '';
      estado = (v.estado.toLowerCase().trim() == 'activo')
          ? 'activo'
          : 'inactivo';
      fotoUrl = v.fotoUrl;

      // Verificar si choferAsignado es nulo y asignar un valor predeterminado
      choferAsignado = v.choferId != null
          ? choferesDisponibles.isNotEmpty
                ? choferesDisponibles.firstWhere(
                    (chofer) => chofer.id == v.choferId,
                    orElse: () =>
                        choferesDisponibles[0], // Asignar un valor predeterminado si no se encuentra
                  )
                : null
          : null;
    }
  }

  Future<void> _cargarChoferesDisponibles() async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'chofer') // Solo choferes disponibles
        .get();
    final choferes = snap.docs.map((doc) {
      return UsuarioModelo.fromMap(doc.data(), doc.id);
    }).toList();

    setState(() {
      choferesDisponibles = choferes;

      // Verificar si choferAsignado está vacío y asignar un valor predeterminado
      if (choferesDisponibles.isNotEmpty && choferAsignado == null) {
        choferAsignado = choferesDisponibles
            .first; // Asignar el primer chofer si no se ha asignado uno
      } else {
        choferAsignado =
            null; // No asignar ningún chofer si la lista está vacía
      }
    });
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
        'numero_vehiculo': numeroVehiculoCtrl.text
            .trim(), // Editable solo al crear
        'placa': placaCtrl.text.trim(), // Editable solo al crear
        'anio': anioCtrl.text.trim(),
        'estado': estado.toLowerCase().trim(),
        'fotoUrl': url,
        'chofer_id': choferAsignado?.id ?? '', // Asignar chofer seleccionado
      };

      if (widget.vehiculo == null) {
        // Crear nuevo vehículo
        await FirebaseFirestore.instance
            .collection('vehiculos')
            .add(vehiculoData);
      } else {
        // Editar vehículo existente
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
              // Número de Vehículo (editable solo al crear)
              TextFormField(
                controller: numeroVehiculoCtrl, // Editable solo al crear
                decoration: InputDecoration(labelText: 'Número de Vehículo'),
                enabled: widget.vehiculo == null, // Habilitar solo al crear
                validator: (v) => v == null || v.isEmpty
                    ? 'Ingrese el número de vehículo'
                    : null,
              ),
              SizedBox(height: 14),
              // Placa (editable solo al crear)
              TextFormField(
                controller: placaCtrl, // Editable solo al crear
                decoration: InputDecoration(labelText: 'Placa'),
                enabled: widget.vehiculo == null, // Habilitar solo al crear
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese la placa' : null,
              ),
              SizedBox(height: 14),
              // Año (editable siempre)
              TextFormField(
                controller: anioCtrl,
                decoration: InputDecoration(labelText: 'Año'),
                enabled: widget.vehiculo == null, // Habilitar solo al crear
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 1900 || n > DateTime.now().year + 1) {
                    return "Año inválido";
                  }
                  return null;
                },
              ),
              SizedBox(height: 14),
              // Estado (editable)
              DropdownButtonFormField<String>(
                value: estado,
                items: [
                  DropdownMenuItem(value: "activo", child: Text("Activo")),
                  DropdownMenuItem(value: "inactivo", child: Text("Inactivo")),
                ],
                onChanged: (v) => setState(() => estado = v ?? "activo"),
                decoration: InputDecoration(labelText: "Estado"),
              ),
              SizedBox(height: 14),
              // Chofer asignado (editable)
              DropdownButtonFormField<UsuarioModelo>(
                value: choferAsignado,
                items: [
                  DropdownMenuItem(value: null, child: Text("Sin chofer")),
                  ...choferesDisponibles.map((chofer) {
                    return DropdownMenuItem(
                      value: chofer,
                      child: Text(chofer.nombre),
                    );
                  }).toList(),
                ],
                onChanged: (chofer) => setState(() => choferAsignado = chofer),
                decoration: InputDecoration(labelText: "Asignar Chofer"),
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
