import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_paths.dart';

/// Минимальный tenant-context: company + firestore.
/// Без бизнес-логики, только контейнер зависимостей.
class CompanyContext {
  final String companyId;
  final FirebaseFirestore firestore;
  late final FirestorePaths paths;

  CompanyContext({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance {
    paths = FirestorePaths.fromContext(this);
  }
}
