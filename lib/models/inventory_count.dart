import 'package:cloud_firestore/cloud_firestore.dart';
import 'count_item.dart';

/// Модель сессии инвентаризации (ספירת מלאי)
class InventoryCount {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status; // "in_progress" | "completed"
  final String userName;
  final List<CountItem> items;
  final CountSummary summary;
  final String? notes;

  InventoryCount({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.userName,
    required this.items,
    required this.summary,
    this.notes,
  });

  /// Создать из Firestore документа
  factory InventoryCount.fromMap(Map<String, dynamic> map, String id) {
    return InventoryCount(
      id: id,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      status: map['status'] as String,
      userName: map['userName'] as String,
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CountItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      summary: CountSummary.fromMap(map['summary'] as Map<String, dynamic>),
      notes: map['notes'] as String?,
    );
  }

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'summary': summary.toMap(),
      'notes': notes,
    };
  }

  /// Копировать с изменениями
  InventoryCount copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    String? status,
    String? userName,
    List<CountItem>? items,
    CountSummary? summary,
    String? notes,
  }) {
    return InventoryCount(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      notes: notes ?? this.notes,
    );
  }
}

/// Сводка по подсчету
class CountSummary {
  final int totalItems;
  final int checkedItems;
  final int itemsWithDifference;
  final int totalShortage; // Общая недостача (отрицательные разницы)
  final int totalSurplus; // Общий излишек (положительные разницы)

  CountSummary({
    required this.totalItems,
    required this.checkedItems,
    required this.itemsWithDifference,
    required this.totalShortage,
    required this.totalSurplus,
  });

  factory CountSummary.fromMap(Map<String, dynamic> map) {
    return CountSummary(
      totalItems: map['totalItems'] as int,
      checkedItems: map['checkedItems'] as int,
      itemsWithDifference: map['itemsWithDifference'] as int,
      totalShortage: map['totalShortage'] as int,
      totalSurplus: map['totalSurplus'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalItems': totalItems,
      'checkedItems': checkedItems,
      'itemsWithDifference': itemsWithDifference,
      'totalShortage': totalShortage,
      'totalSurplus': totalSurplus,
    };
  }

  /// Создать пустую сводку
  factory CountSummary.empty() {
    return CountSummary(
      totalItems: 0,
      checkedItems: 0,
      itemsWithDifference: 0,
      totalShortage: 0,
      totalSurplus: 0,
    );
  }
}
