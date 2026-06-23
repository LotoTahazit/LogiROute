import '../models/client_model.dart';
import '../utils/geocoding_helper.dart';
import 'client_service.dart';
import 'firestore_paths.dart';

class ClientRegeocodeReport {
  final int total;
  final int updated;
  final int unchanged;
  final int failed;
  final int skippedNoAddress;
  final int pointsUpdated;

  const ClientRegeocodeReport({
    required this.total,
    required this.updated,
    required this.unchanged,
    required this.failed,
    required this.skippedNoAddress,
    required this.pointsUpdated,
  });
}

/// Массовый перегеокодинг клиентов (web + componentRestrictions).
class ClientRegeocodeService {
  final String companyId;
  final ClientService _clients;

  ClientRegeocodeService({required this.companyId})
      : _clients = ClientService(companyId: companyId);

  static bool _coordsChanged(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const t = 0.0005; // ~50 м
    return (lat1 - lat2).abs() > t || (lng1 - lng2).abs() > t;
  }

  Future<int> _syncDeliveryPoints(
    String clientNumber,
    double newLat,
    double newLng,
  ) async {
    if (clientNumber.isEmpty) return 0;
    final snap = await FirestorePaths.deliveryPointsOf(companyId)
        .where('clientNumber', isEqualTo: clientNumber)
        .get();
    var n = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final plat = (data['latitude'] as num?)?.toDouble() ?? 0;
      final plng = (data['longitude'] as num?)?.toDouble() ?? 0;
      if (!_coordsChanged(plat, plng, newLat, newLng)) continue;
      await doc.reference.update({
        'latitude': newLat,
        'longitude': newLng,
      });
      n++;
    }
    return n;
  }

  Future<ClientRegeocodeReport> regeocodeAll({
    void Function(int done, int total)? onProgress,
    Duration throttle = const Duration(milliseconds: 250),
  }) async {
    final list = await _clients.getAllClients();
    var updated = 0, unchanged = 0, failed = 0, skipped = 0, pointsUpdated = 0;
    final total = list.length;

    for (var i = 0; i < list.length; i++) {
      onProgress?.call(i + 1, total);
      final client = list[i];
      final address = client.address.trim();
      if (address.isEmpty) {
        skipped++;
        continue;
      }

      final geo = await GeocodingHelper.geocodeAddress(address);
      if (geo == null) {
        failed++;
        await Future.delayed(throttle);
        continue;
      }

      final newLat = geo['latitude']!;
      final newLng = geo['longitude']!;

      if (_coordsChanged(
          client.latitude, client.longitude, newLat, newLng)) {
        await _clients.updateClient(
          client.id,
          ClientModel(
            id: client.id,
            clientNumber: client.clientNumber,
            name: client.name,
            address: client.address,
            latitude: newLat,
            longitude: newLng,
            phone: client.phone,
            contactPerson: client.contactPerson,
            vatId: client.vatId,
            companyId: client.companyId,
            zones: client.zones,
            paymentMethod: client.paymentMethod,
          ),
        );
        updated++;
      } else {
        unchanged++;
      }

      // Карта читает координаты из delivery_points — синхронизируем всегда.
      pointsUpdated += await _syncDeliveryPoints(
        client.clientNumber,
        newLat,
        newLng,
      );

      await Future.delayed(throttle);
    }

    return ClientRegeocodeReport(
      total: total,
      updated: updated,
      unchanged: unchanged,
      failed: failed,
      skippedNoAddress: skipped,
      pointsUpdated: pointsUpdated,
    );
  }
}
