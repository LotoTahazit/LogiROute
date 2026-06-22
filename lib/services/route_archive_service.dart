import '../models/delivery_point.dart';
import 'firestore_paths.dart';

/// Архив завершённых точек: archive_routes + delivery_points с archived=true.
class RouteArchiveService {
  RouteArchiveService({required this.companyId});

  final String companyId;
  static const int retentionDays = 90;

  Future<List<DeliveryPoint>> fetchArchivedPoints() async {
    final cutoff = DateTime.now().subtract(const Duration(days: retentionDays));
    final seen = <String>{};
    final out = <DeliveryPoint>[];

    void add(DeliveryPoint p) {
      if (seen.contains(p.id)) return;
      final when = p.completedAt ?? p.archivedAt;
      if (when != null && when.isBefore(cutoff)) return;
      seen.add(p.id);
      out.add(p);
    }

    try {
      final archived = await FirestorePaths.archiveRoutesOf(companyId)
          .orderBy('archivedAt', descending: true)
          .limit(400)
          .get();
      for (final doc in archived.docs) {
        add(DeliveryPoint.fromMap(doc.data(), doc.id));
      }
    } catch (_) {
      final archived = await FirestorePaths.archiveRoutesOf(companyId)
          .limit(400)
          .get();
      for (final doc in archived.docs) {
        add(DeliveryPoint.fromMap(doc.data(), doc.id));
      }
    }

    final flagged = await FirestorePaths.deliveryPointsOf(companyId)
        .where('archived', isEqualTo: true)
        .limit(200)
        .get();
    for (final doc in flagged.docs) {
      add(DeliveryPoint.fromMap(doc.data(), doc.id));
    }

    out.sort((a, b) {
      final da = a.completedAt ?? a.archivedAt ?? DateTime(1970);
      final db = b.completedAt ?? b.archivedAt ?? DateTime(1970);
      return db.compareTo(da);
    });
    return out;
  }
}
