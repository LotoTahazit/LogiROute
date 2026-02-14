class BoxType {
  final String type; // "בביע", "מכסה", "כוס"
  final String number; // "100", "250", "500"
  final int volumeMl; // автоматически определяется по номеру
  final int quantity; // количество единиц
  final double? price; // цена за единицу (опционально)

  BoxType({
    required this.type,
    required this.number,
    required this.volumeMl,
    required this.quantity,
    this.price,
  });

  // Справочник: номер -> объём в мл (больше не используется, данные из Firebase)
  static int getVolumeMl(String number) {
    // Этот метод больше не нужен, объём берётся из Firebase
    return 0;
  }

  // Доступные типы товаров (больше не фиксированные, загружаются из Firebase)
  static List<String> get availableTypes => [];

  // Доступные номера (больше не фиксированные, загружаются из Firebase)
  static List<String> get availableNumbers => [];

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'number': number,
      'volumeMl': volumeMl,
      'quantity': quantity,
    };
  }

  // Создание из Map (Firestore)
  factory BoxType.fromMap(Map<String, dynamic> map) {
    return BoxType(
      type: map['type'] ?? '',
      number: map['number'] ?? '',
      volumeMl: map['volumeMl'] ?? 0,
      quantity: map['quantity'] ?? 0,
    );
  }

  // Текстовое представление для отображения
  String toDisplayString() {
    return '$type $number ($volumeMl מל) x $quantity יח\'';
  }

  // Краткое представление для печати (с правильным RTL форматированием)
  String toShortString() {
    // Формат: כוס 218 x 120 (с пробелами для правильного RTL отображения)
    return '$type $number x $quantity';
  }

  @override
  String toString() => toDisplayString();
}
