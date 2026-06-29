import 'warehouse_structure.dart';

/// Терминология и настройки компании
class CompanyTerminology {
  final String companyId;
  final String unitName; // יחידות, קופסאות, בקבוקים
  final String unitNamePlural; // יחידות, קופסאות, בקבוקים
  final String palletName; // משטחים, קרטונים
  final String palletNamePlural; // משטחים, קרטונים
  final bool usesPallets; // Использует ли паллеты
  final String capacityCalculation; // 'units', 'weight', 'volume'
  final String
      businessType; // 'packaging', 'food', 'clothing', 'construction', 'custom'
  final WarehouseStructure warehouseStructure;

  CompanyTerminology({
    required this.companyId,
    this.unitName = 'יחידה',
    this.unitNamePlural = 'יחידות',
    this.palletName = 'משטח',
    this.palletNamePlural = 'משטחים',
    this.usesPallets = true,
    this.capacityCalculation = 'units',
    this.businessType = 'custom',
    this.warehouseStructure = const WarehouseStructure(),
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'unitName': unitName,
      'unitNamePlural': unitNamePlural,
      'palletName': palletName,
      'palletNamePlural': palletNamePlural,
      'usesPallets': usesPallets,
      'capacityCalculation': capacityCalculation,
      'businessType': businessType,
      'warehouseStructure': warehouseStructure.toMap(),
    };
  }

  factory CompanyTerminology.fromMap(Map<String, dynamic> map) {
    return CompanyTerminology(
      companyId: map['companyId'] ?? '',
      unitName: map['unitName'] ?? 'יחידה',
      unitNamePlural: map['unitNamePlural'] ?? 'יחידות',
      palletName: map['palletName'] ?? 'משטח',
      palletNamePlural: map['palletNamePlural'] ?? 'משטחים',
      usesPallets: map['usesPallets'] ?? true,
      capacityCalculation: map['capacityCalculation'] ?? 'units',
      businessType: map['businessType'] ?? 'custom',
      warehouseStructure: WarehouseStructure.fromMap(
        map['warehouseStructure'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Шаблоны по отраслям
  static CompanyTerminology getTemplate(String businessType, String companyId) {
    switch (businessType) {
      case 'packaging':
        return CompanyTerminology(
          companyId: companyId,
          unitName: 'קופסה',
          unitNamePlural: 'קופסאות',
          palletName: 'משטח',
          palletNamePlural: 'משטחים',
          usesPallets: true,
          capacityCalculation: 'units',
          businessType: 'packaging',
        );
      case 'food':
        return CompanyTerminology(
          companyId: companyId,
          unitName: 'יחידה',
          unitNamePlural: 'יחידות',
          palletName: 'קרטון',
          palletNamePlural: 'קרטונים',
          usesPallets: true,
          capacityCalculation: 'weight',
          businessType: 'food',
        );
      case 'clothing':
        return CompanyTerminology(
          companyId: companyId,
          unitName: 'פריט',
          unitNamePlural: 'פריטים',
          palletName: 'קרטון',
          palletNamePlural: 'קרטונים',
          usesPallets: false,
          capacityCalculation: 'units',
          businessType: 'clothing',
        );
      case 'construction':
        return CompanyTerminology(
          companyId: companyId,
          unitName: 'יחידה',
          unitNamePlural: 'יחידות',
          palletName: 'משטח',
          palletNamePlural: 'משטחים',
          usesPallets: true,
          capacityCalculation: 'weight',
          businessType: 'construction',
        );
      default:
        return CompanyTerminology(
          companyId: companyId,
          businessType: 'custom',
        );
    }
  }

  CompanyTerminology copyWith({
    String? companyId,
    String? unitName,
    String? unitNamePlural,
    String? palletName,
    String? palletNamePlural,
    bool? usesPallets,
    String? capacityCalculation,
    String? businessType,
    WarehouseStructure? warehouseStructure,
  }) {
    return CompanyTerminology(
      companyId: companyId ?? this.companyId,
      unitName: unitName ?? this.unitName,
      unitNamePlural: unitNamePlural ?? this.unitNamePlural,
      palletName: palletName ?? this.palletName,
      palletNamePlural: palletNamePlural ?? this.palletNamePlural,
      usesPallets: usesPallets ?? this.usesPallets,
      capacityCalculation: capacityCalculation ?? this.capacityCalculation,
      businessType: businessType ?? this.businessType,
      warehouseStructure: warehouseStructure ?? this.warehouseStructure,
    );
  }
}
