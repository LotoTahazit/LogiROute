/// Глобальный шаблон товара из коллекции /product_templates/.
/// Не привязан к компании, содержит businessType.
class TemplateProduct {
  final String id;
  final String name;
  final String productCode;
  final String category; // categoryKey
  final int unitsPerBox;
  final int boxesPerPallet;
  final double? weight;
  final double? volume;
  final String businessType;

  TemplateProduct({
    required this.id,
    required this.name,
    required this.productCode,
    required this.category,
    required this.unitsPerBox,
    required this.boxesPerPallet,
    this.weight,
    this.volume,
    required this.businessType,
  });

  /// Создание из Firestore документа.
  /// Возвращает null если отсутствует обязательное поле.
  static TemplateProduct? fromMap(Map<String, dynamic> map, String id) {
    final name = map['name'];
    final productCode = map['productCode'];
    final category = map['category'];
    final unitsPerBox = map['unitsPerBox'];
    final boxesPerPallet = map['boxesPerPallet'];
    final businessType = map['businessType'];

    if (name == null ||
        productCode == null ||
        category == null ||
        unitsPerBox == null ||
        boxesPerPallet == null ||
        businessType == null) {
      return null;
    }

    return TemplateProduct(
      id: id,
      name: name as String,
      productCode: productCode as String,
      category: category as String,
      unitsPerBox:
          (unitsPerBox is int) ? unitsPerBox : (unitsPerBox as num).toInt(),
      boxesPerPallet: (boxesPerPallet is int)
          ? boxesPerPallet
          : (boxesPerPallet as num).toInt(),
      weight: (map['weight'] as num?)?.toDouble(),
      volume: (map['volume'] as num?)?.toDouble(),
      businessType: businessType as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'productCode': productCode,
      'category': category,
      'unitsPerBox': unitsPerBox,
      'boxesPerPallet': boxesPerPallet,
      if (weight != null) 'weight': weight,
      if (volume != null) 'volume': volume,
      'businessType': businessType,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          productCode == other.productCode &&
          category == other.category &&
          unitsPerBox == other.unitsPerBox &&
          boxesPerPallet == other.boxesPerPallet &&
          weight == other.weight &&
          volume == other.volume &&
          businessType == other.businessType;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        productCode,
        category,
        unitsPerBox,
        boxesPerPallet,
        weight,
        volume,
        businessType,
      );

  @override
  String toString() =>
      'TemplateProduct($name, $productCode, $category, $businessType)';
}
