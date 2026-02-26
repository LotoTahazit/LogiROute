import 'package:cloud_firestore/cloud_firestore.dart';

class Price {
  final String id; // companyId_type_number (например: "company1_כוס_218")
  final String companyId; // ID компании для изоляции данных
  final String type; // "בביע", "מכסה", "כוס"
  final String number; // "100", "200", etc.
  final double priceBeforeVAT; // Цена до НДС
  final DateTime lastUpdated; // Когда обновлено
  final String updatedBy; // Кто обновил

  Price({
    required this.id,
    required this.companyId,
    required this.type,
    required this.number,
    required this.priceBeforeVAT,
    required this.lastUpdated,
    required this.updatedBy,
  });

  // Создание ID из companyId, типа и номера
  static String generateId(String companyId, String type, String number) {
    return '${companyId}_${type}_$number';
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'type': type,
      'number': number,
      'priceBeforeVAT': priceBeforeVAT,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
    };
  }

  // Создание из Map (Firestore)
  factory Price.fromMap(Map<String, dynamic> map, String id) {
    return Price(
      id: id,
      companyId: map['companyId'] ?? '',
      type: map['type'] ?? '',
      number: map['number'] ?? '',
      priceBeforeVAT: (map['priceBeforeVAT'] is num)
          ? (map['priceBeforeVAT'] as num).toDouble()
          : 0.0,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  // Копирование с изменениями
  Price copyWith({
    double? priceBeforeVAT,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return Price(
      id: id,
      companyId: companyId,
      type: type,
      number: number,
      priceBeforeVAT: priceBeforeVAT ?? this.priceBeforeVAT,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() => '$type $number: ₪${priceBeforeVAT.toStringAsFixed(2)}';
}
