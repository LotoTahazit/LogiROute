import 'package:cloud_firestore/cloud_firestore.dart';
import 'import_wizard_type.dart';

/// Сохранённый шаблон сопоставления колонок импорта.
class SavedImportMapping {
  final String id;
  final String companyId;
  final ImportWizardType importType;
  final String name;
  final List<String> sourceHeaders;
  final Map<String, int> mapping;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final DateTime? lastUsedAt;

  const SavedImportMapping({
    required this.id,
    required this.companyId,
    required this.importType,
    required this.name,
    required this.sourceHeaders,
    required this.mapping,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastUsedAt,
  });

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'importType': importType.value,
        'name': name,
        'sourceHeaders': sourceHeaders,
        'mapping': mapping.map((k, v) => MapEntry(k, v)),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        if (lastUsedAt != null) 'lastUsedAt': Timestamp.fromDate(lastUsedAt!),
      };

  factory SavedImportMapping.fromMap(Map<String, dynamic> map, String id) {
    final rawMapping = map['mapping'] as Map<String, dynamic>? ?? {};
    return SavedImportMapping(
      id: id,
      companyId: map['companyId']?.toString() ?? '',
      importType:
          ImportWizardType.fromValue(map['importType']?.toString()) ??
              ImportWizardType.clients,
      name: map['name']?.toString() ?? '',
      sourceHeaders: (map['sourceHeaders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mapping: rawMapping.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy']?.toString() ?? '',
      lastUsedAt: (map['lastUsedAt'] as Timestamp?)?.toDate(),
    );
  }
}
