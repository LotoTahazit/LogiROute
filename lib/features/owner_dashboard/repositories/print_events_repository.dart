import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/print_event.dart';

/// Репозиторий для чтения событий печати компании.
///
/// Работает с коллекцией `/companies/{companyId}/printEvents/{eventId}`.
/// Read-only: события печати создаются модулем accounting,
/// клиент только читает.
///
/// Все операции требуют `companyId` для обеспечения tenant isolation.
class PrintEventsRepository {
  final FirebaseFirestore _firestore;
  final String companyId;

  PrintEventsRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _validateCompanyId();
  }

  /// Ссылка на коллекцию printEvents компании.
  CollectionReference<Map<String, dynamic>> get _printEventsCollection =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('printEvents');

  /// Стрим событий печати в реальном времени, отсортированных
  /// по убыванию `printedAt`.
  ///
  /// Если [statusFilter] указан, возвращает только события с данным статусом.
  Stream<List<PrintEvent>> watchPrintEvents({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _printEventsCollection;

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.orderBy('printedAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final raw = doc.data();
        final data = Map<String, dynamic>.from(raw as Map);
        return PrintEvent.fromMap(data, id: doc.id);
      }).toList();
    });
  }

  void _validateCompanyId() {
    if (companyId.isEmpty) {
      throw ArgumentError(
        'companyId is required for PrintEventsRepository. '
        'Use CompanyContext to get the correct companyId.',
      );
    }
  }
}
