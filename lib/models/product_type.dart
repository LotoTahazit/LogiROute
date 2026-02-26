import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип товара (настраиваемый для каждой компании)
class ProductType {
  final String id;
  final String companyId;
  final String name; // Название товара (גביע 100, חולצה M)
  final String productCode; // מק"ט
  final String category; // Категория для группировки
  final int unitsPerBox; // Единиц в коробке
  final int boxesPerPallet; // Коробок на паллете
  final double? weight; // Вес единицы (опционально)
  final double? volume; // Объём единицы (опционально)
  final bool isActive; // Активен ли товар
  final DateTime createdAt;
  final String createdBy;

  ProductType({
    required this.id,
    required this.companyId,
    required this.name,
    required this.productCode,
    this.category = 'general',
    required this.unitsPerBox,
    required this.boxesPerPallet,
    this.weight,
    this.volume,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  /// Общее количество единиц на паллете
  int get unitsPerPallet => unitsPerBox * boxesPerPallet;

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'productCode': productCode,
      'category': category,
      'unitsPerBox': unitsPerBox,
      'boxesPerPallet': boxesPerPallet,
      if (weight != null) 'weight': weight,
      if (volume != null) 'volume': volume,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory ProductType.fromMap(Map<String, dynamic> map, String id) {
    return ProductType(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      productCode: map['productCode'] ?? '',
      category: map['category'] ?? 'general',
      unitsPerBox: map['unitsPerBox'] ?? 1,
      boxesPerPallet: map['boxesPerPallet'] ?? 1,
      weight: map['weight']?.toDouble(),
      volume: map['volume']?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  ProductType copyWith({
    String? id,
    String? companyId,
    String? name,
    String? productCode,
    String? category,
    int? unitsPerBox,
    int? boxesPerPallet,
    double? weight,
    double? volume,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ProductType(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      productCode: productCode ?? this.productCode,
      category: category ?? this.category,
      unitsPerBox: unitsPerBox ?? this.unitsPerBox,
      boxesPerPallet: boxesPerPallet ?? this.boxesPerPallet,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
