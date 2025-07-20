class UsuarioModelo {
  final String id;
  final String nombre;
  final String rol;
  final String estado;
  final String? telefono;

  UsuarioModelo({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.estado,
    this.telefono,
  });

  factory UsuarioModelo.fromMap(Map<String, dynamic> data, String id) {
    return UsuarioModelo(
      id: id,
      nombre: data['nombre'] ?? '',
      rol: data['rol'] ?? '',
      estado: data['estado'] ?? '',
      telefono: data['telefono'] ?? '',
    );
  }
}
