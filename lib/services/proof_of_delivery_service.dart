import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

/// Proof of Delivery: фото хранится в Storage ~90 дней (см. cleanupPodPhotos).
class ProofOfDeliveryService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickPhotoFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  Future<Position?> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  /// Расстояние до точки доставки в метрах (для контроля «на месте»).
  int? distanceToPointM({
    required double driverLat,
    required double driverLng,
    required double pointLat,
    required double pointLng,
  }) {
    if (pointLat == 0 || pointLng == 0) return null;
    return Geolocator.distanceBetween(
      driverLat,
      driverLng,
      pointLat,
      pointLng,
    ).round();
  }

  Future<String> uploadPhoto({
    required String companyId,
    required String pointId,
    required Uint8List bytes,
  }) async {
    final path =
        'companies/$companyId/pod/$pointId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
