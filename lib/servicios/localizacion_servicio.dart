import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalizacionServicio {
  // Obtiene la ubicación actual del teléfono
  Future<Position?> obtenerUbicacionActual() async {
    bool permiso = await Geolocator.isLocationServiceEnabled();
    if (!permiso) return null;
    LocationPermission permisoUbicacion = await Geolocator.checkPermission();
    if (permisoUbicacion == LocationPermission.denied) {
      permisoUbicacion = await Geolocator.requestPermission();
      if (permisoUbicacion == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  // Actualiza la ubicación del chofer en Firestore
  Future<void> actualizarUbicacionChofer(String userId) async {
    Position? pos = await obtenerUbicacionActual();
    if (pos == null) return;
    await FirebaseFirestore.instance.collection('usuarios').doc(userId).update({
      'ubicacion': {'latitude': pos.latitude, 'longitude': pos.longitude},
    });
  }

  // Stream para actualización automática (cada X segundos)
  Stream<Position> streamUbicacion() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8, // Solo si se mueve más de 8 metros
      ),
    );
  }
}
