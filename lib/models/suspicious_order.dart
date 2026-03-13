import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель подозрительного заказа (связанного с расхождением)
class SuspiciousOrder {
  final String orderId;
  final int orderNumber;
  final String clientName;
  final int quantity; // Количество этого товара в заказе
  final String status; // delivered, in_transit, cancelled, etc.
  final DateTime? deliveredAt;
  final String suspicionLevel; // "high" | "medium" | "low"
  final String reason; // Причина подозрения

  SuspiciousOrder({
    required this.orderId,
    required this.orderNumber,
    required this.clientName,
    required this.quantity,
    required this.status,
    this.deliveredAt,
    required this.suspicionLevel,
    required this.reason,
  });

  factory SuspiciousOrder.fromMap(Map<String, dynamic> map) {
    return SuspiciousOrder(
      orderId: map['orderId'] as String,
      orderNumber: ((map['orderNumber'] ?? 0) as num).toInt(),
      clientName: map['clientName'] as String,
      quantity: ((map['quantity'] ?? 0) as num).toInt(),
      status: map['status'] as String,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      suspicionLevel: map['suspicionLevel'] as String,
      reason: map['reason'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'clientName': clientName,
      'quantity': quantity,
      'status': status,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'suspicionLevel': suspicionLevel,
      'reason': reason,
    };
  }

  /// Иконка по уровню подозрения
  String get icon {
    switch (suspicionLevel) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }
}
