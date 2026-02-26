import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryChange {
  final String id;
  final String productCode; // מק"ט
  final String type;
  final String number;
  final int
      quantityChange; // Изменение: положительное = добавление, отрицательное = списание
  final int quantityBefore; // Остаток до изменения
  final int quantityAfter; // Остаток после изменения
  final DateTime timestamp;
  final String userName; // Кто сделал изменение
  final String action; // 'add', 'deduct', 'update'
  final String? reason; // Причина (опционально)
  final bool archived; // Архивировано ли
  final DateTime? archivedAt; // Когда архивировано
  final String? archiveFile; // Путь к файлу архива

  InventoryChange({
    required this.id,
    required this.productCode,
    required this.type,
    required this.number,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.timestamp,
    required this.userName,
    required this.action,
    this.reason,
    this.archived = false,
    this.archivedAt,
    this.archiveFile,
  });

  factory InventoryChange.fromMap(Map<String, dynamic> map, String id) {
    return InventoryChange(
      id: id,
      productCode: map['productCode'] ?? '',
      type: map['type'] ?? '',
      number: map['number'] ?? '',
      quantityChange: map['quantityChange'] ?? 0,
      quantityBefore: map['quantityBefore'] ?? 0,
      quantityAfter: map['quantityAfter'] ?? 0,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      reason: map['reason'],
      archived: map['archived'] ?? false,
      archivedAt: map['archivedAt'] != null
          ? (map['archivedAt'] as Timestamp).toDate()
          : null,
      archiveFile: map['archiveFile'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode,
      'type': type,
      'number': number,
      'quantityChange': quantityChange,
      'quantityBefore': quantityBefore,
      'quantityAfter': quantityAfter,
      'timestamp': Timestamp.fromDate(timestamp),
      'userName': userName,
      'action': action,
      if (reason != null) 'reason': reason,
      'archived': archived,
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),
      if (archiveFile != null) 'archiveFile': archiveFile,
    };
  }

  String get actionInHebrew {
    switch (action) {
      case 'add':
        return 'הוספה';
      case 'deduct':
        return 'הוצאה';
      case 'update':
        return 'עדכון';
      default:
        return action;
    }
  }
}
