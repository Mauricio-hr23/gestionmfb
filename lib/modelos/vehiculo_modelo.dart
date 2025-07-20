class VehiculoModelo {
  final String id;
  final String modelo;
  final String placa;
  final String? anio;
  final String estado;
  final String? fotoUrl;
  final String? choferId;

  VehiculoModelo({
    required this.id,
    required this.modelo,
    required this.placa,
    this.anio,
    required this.estado,
    this.fotoUrl,
    this.choferId,
  });

  factory VehiculoModelo.fromMap(Map<String, dynamic> data, String docId) {
    return VehiculoModelo(
      id: docId,
      modelo: data['modelo'] ?? '',
      placa: data['placa'] ?? '',
      anio: data['anio']?.toString(),
      estado: data['estado'] ?? 'activo',
      fotoUrl: data['fotoUrl'],
      // Acepta ambos para compatibilidad vieja, pero prefiere chofer_id
      choferId: data['chofer_id'] ?? data['choferId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelo': modelo,
      'placa': placa,
      'anio': anio,
      'estado': estado,
      'fotoUrl': fotoUrl,
      'chofer_id': choferId ?? '',
    };
  }
}
