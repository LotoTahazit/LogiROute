import 'package:cloud_firestore/cloud_firestore.dart';
import 'suspicious_order.dart';

/// Модель товара в инвентаризации
class CountItem {
  final String productCode;
  final String type;
  final String number;
  final int expectedQuantity; // Ожидаемое количество (из системы)
  final int? actualQuantity; // Фактическое количество (подсчитанное)
  final DateTime? checkedAt; // Когда проверено
  final List<SuspiciousOrder> relatedOrders; // Подозрительные заказы
  final String? notes; // Комментарий кладовщика

  CountItem({
    required this.productCode,
    required this.type,
    required this.number,
    required this.expectedQuantity,
    this.actualQuantity,
    this.checkedAt,
    this.relatedOrders = const [],
    this.notes,
  });

  /// Разница между фактическим и ожидаемым
  int? get difference {
    if (actualQuantity == null) return null;
    return actualQuantity! - expectedQuantity;
  }

  /// Есть ли расхождение
  bool get hasDifference {
    return difference != null && difference != 0;
  }

  /// Проверен ли товар
  bool get isChecked {
    return actualQuantity != null;
  }

  /// Недостача (отрицательная разница)
  bool get isShortage {
    return difference != null && difference! < 0;
  }

  /// Излишек (положительная разница)
  bool get isSurplus {
    return difference != null && difference! > 0;
  }

  factory CountItem.fromMap(Map<String, dynamic> map) {
    return CountItem(
      productCode: map['productCode'] as String,
      type: map['type'] as String,
      number: map['number'] as String,
      expectedQuantity: map['expectedQuantity'] as int,
      actualQuantity: map['actualQuantity'] as int?,
      checkedAt: map['checkedAt'] != null
          ? (map['checkedAt'] as Timestamp).toDate()
          : null,
      relatedOrders: (map['relatedOrders'] as List<dynamic>?)
              ?.map((order) =>
                  SuspiciousOrder.fromMap(order as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode,
      'type': type,
      'number': number,
      'expectedQuantity': expectedQuantity,
      'actualQuantity': actualQuantity,
      'checkedAt': checkedAt != null ? Timestamp.fromDate(checkedAt!) : null,
      'relatedOrders': relatedOrders.map((order) => order.toMap()).toList(),
      'notes': notes,
    };
  }

  /// Копировать с изменениями
  CountItem copyWith({
    String? productCode,
    String? type,
    String? number,
    int? expectedQuantity,
    int? actualQuantity,
    DateTime? checkedAt,
    List<SuspiciousOrder>? relatedOrders,
    String? notes,
  }) {
    return CountItem(
      productCode: productCode ?? this.productCode,
      type: type ?? this.type,
      number: number ?? this.number,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      checkedAt: checkedAt ?? this.checkedAt,
      relatedOrders: relatedOrders ?? this.relatedOrders,
      notes: notes ?? this.notes,
    );
  }
}
