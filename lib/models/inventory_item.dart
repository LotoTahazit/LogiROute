import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id; // Уникальный ID (type_number)
  final String type; // "בביע", "מכסה", "כוס"
  final String number; // "100", "200", etc.
  final int? volumeMl; // Объём в мл (необязательное)
  final int quantity; // Текущий остаток (в штуках)
  final int quantityPerPallet; // Количество на миштахе (обязательное)
  final DateTime lastUpdated; // Когда обновлено
  final String updatedBy; // Кто обновил (имя пользователя)
  final String? diameter; // Диаметр (קוטר) - необязательное
  final String? volume; // Объем (נפח) - необязательное
  final int? piecesPerBox; // Количество штук в коробке (ארוז) - необязательное
  final String? additionalInfo; // Дополнительные данные - необязательное

  InventoryItem({
    required this.id,
    required this.type,
    required this.number,
    this.volumeMl,
    required this.quantity,
    required this.quantityPerPallet,
    required this.lastUpdated,
    required this.updatedBy,
    this.diameter,
    this.volume,
    this.piecesPerBox,
    this.additionalInfo,
  });

  // Вычисляемые поля
  int get numberOfPallets =>
      quantityPerPallet > 0 ? (quantity / quantityPerPallet).ceil() : 0;
  int get numberOfBoxes => piecesPerBox != null && piecesPerBox! > 0
      ? (quantity / piecesPerBox!).ceil()
      : 0;

  // Создание ID из типа и номера
  static String generateId(String type, String number) {
    return '${type}_$number';
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'number': number,
      if (volumeMl != null) 'volumeMl': volumeMl,
      'quantity': quantity,
      'quantityPerPallet': quantityPerPallet,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
      if (diameter != null) 'diameter': diameter,
      if (volume != null) 'volume': volume,
      if (piecesPerBox != null) 'piecesPerBox': piecesPerBox,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }

  // Создание из Map (Firestore)
  factory InventoryItem.fromMap(Map<String, dynamic> map, String id) {
    return InventoryItem(
      id: id,
      type: map['type'] ?? '',
      number: map['number'] ?? '',
      volumeMl: (map['volumeMl'] is num)
          ? (map['volumeMl'] as num).toInt()
          : int.tryParse(map['volumeMl']?.toString() ?? ''),
      quantity: map['quantity'] ?? 0,
      quantityPerPallet: (map['quantityPerPallet'] is num)
          ? (map['quantityPerPallet'] as num).toInt()
          : (int.tryParse(map['quantityPerPallet']?.toString() ?? '') ?? 1),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      diameter: map['diameter']?.toString(),
      volume: map['volume']?.toString(),
      piecesPerBox: (map['piecesPerBox'] is num)
          ? (map['piecesPerBox'] as num).toInt()
          : int.tryParse(map['piecesPerBox']?.toString() ?? ''),
      additionalInfo: map['additionalInfo']?.toString(),
    );
  }

  // Текстовое представление
  String toDisplayString() {
    final volumeStr = volumeMl != null ? '($volumeMl מל)' : '';
    return '$type $number $volumeStr - $quantity יח\'';
  }

  // Краткое представление
  String toShortString() {
    return '$type $number: $quantity יח\'';
  }

  // Копирование с изменениями
  InventoryItem copyWith({
    int? volumeMl,
    int? quantity,
    int? quantityPerPallet,
    DateTime? lastUpdated,
    String? updatedBy,
    String? diameter,
    String? volume,
    int? piecesPerBox,
    String? additionalInfo,
  }) {
    return InventoryItem(
      id: id,
      type: type,
      number: number,
      volumeMl: volumeMl ?? this.volumeMl,
      quantity: quantity ?? this.quantity,
      quantityPerPallet: quantityPerPallet ?? this.quantityPerPallet,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      diameter: diameter ?? this.diameter,
      volume: volume ?? this.volume,
      piecesPerBox: piecesPerBox ?? this.piecesPerBox,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() => toDisplayString();
}
