import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../perfil/editar_perfil_admin_pantalla.dart';
import '../chofer/agregar_chofer_pantalla.dart';

class ListaUsuariosPantalla extends StatefulWidget {
  const ListaUsuariosPantalla({super.key});

  @override
  State<ListaUsuariosPantalla> createState() => _ListaUsuariosPantallaState();
}

class _ListaUsuariosPantallaState extends State<ListaUsuariosPantalla> {
  String _busqueda = '';
  String _filtroRol = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios'),
        actions: [
          // Agregar un botón para navegar a la pantalla de agregar chofer
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navegar a la pantalla AgregarChoferPantalla
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AgregarChoferPantalla()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Buscar por nombre/correo",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => _busqueda = val.trim().toLowerCase()),
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filtroRol,
                  items: [
                    DropdownMenuItem(value: "todos", child: Text("Todos")),
                    DropdownMenuItem(value: "cliente", child: Text("Cliente")),
                    DropdownMenuItem(value: "chofer", child: Text("Chofer")),
                    DropdownMenuItem(
                      value: "administrador",
                      child: Text("Administrador"),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filtroRol = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final usuarios = snapshot.data!.docs.where((doc) {
                  final datos = doc.data() as Map<String, dynamic>;
                  final nombre = (datos['nombre'] ?? '')
                      .toString()
                      .toLowerCase();
                  final correo = (datos['correo'] ?? '')
                      .toString()
                      .toLowerCase();
                  final rol = (datos['rol'] ?? '').toString().toLowerCase();
                  final pasaBusqueda =
                      _busqueda.isEmpty ||
                      nombre.contains(_busqueda) ||
                      correo.contains(_busqueda);
                  final pasaRol = _filtroRol == "todos" || rol == _filtroRol;
                  return pasaBusqueda && pasaRol;
                }).toList();

                if (usuarios.isEmpty) {
                  return Center(child: Text('No hay usuarios'));
                }

                return ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, i) {
                    final doc = usuarios[i];
                    final datos = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (datos['foto_url'] != null &&
                                datos['foto_url'].toString().isNotEmpty)
                            ? NetworkImage(datos['foto_url'])
                            : AssetImage('assets/avatar_default.png')
                                  as ImageProvider,
                      ),
                      title: Text(datos['nombre'] ?? ''),
                      subtitle: Text(
                        '${datos['correo'] ?? ''} • ${datos['rol'] ?? ''}',
                      ),
                      trailing: Icon(Icons.edit),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditarPerfilAdminPantalla(uidUsuario: doc.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
