/// Профиль упаковки склада компании (опросник при онбординге).
class WarehouseStructure {
  static const loose = 'loose';
  static const boxed = 'boxed';
  static const mixedUnits = 'both';

  static const noPallets = 'none';
  static const palletized = 'pallets';
  static const mixedPallets = 'both';

  final String unitPackaging;
  final String boxPalletMode;
  final int defaultUnitsPerBox;
  final int defaultBoxesPerPallet;
  final bool configured;

  const WarehouseStructure({
    this.unitPackaging = mixedUnits,
    this.boxPalletMode = palletized,
    this.defaultUnitsPerBox = 1,
    this.defaultBoxesPerPallet = 16,
    this.configured = false,
  });

  bool get usesLooseUnits =>
      unitPackaging == loose || unitPackaging == mixedUnits;
  bool get usesBoxes => unitPackaging == boxed || unitPackaging == mixedUnits;
  bool get usesPallets =>
      boxPalletMode == palletized || boxPalletMode == mixedPallets;
  bool get askUnitsPerBox => usesBoxes;
  bool get askBoxesPerPallet => usesBoxes && usesPallets;

  Map<String, dynamic> toMap() => {
        'unitPackaging': unitPackaging,
        'boxPalletMode': boxPalletMode,
        'defaultUnitsPerBox': defaultUnitsPerBox,
        'defaultBoxesPerPallet': defaultBoxesPerPallet,
        'configured': configured,
      };

  factory WarehouseStructure.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const WarehouseStructure();
    return WarehouseStructure(
      unitPackaging: map['unitPackaging'] as String? ?? mixedUnits,
      boxPalletMode: map['boxPalletMode'] as String? ?? palletized,
      defaultUnitsPerBox: (map['defaultUnitsPerBox'] as num?)?.toInt() ?? 1,
      defaultBoxesPerPallet:
          (map['defaultBoxesPerPallet'] as num?)?.toInt() ?? 16,
      configured: map['configured'] == true,
    );
  }

  WarehouseStructure copyWith({
    String? unitPackaging,
    String? boxPalletMode,
    int? defaultUnitsPerBox,
    int? defaultBoxesPerPallet,
    bool? configured,
  }) {
    return WarehouseStructure(
      unitPackaging: unitPackaging ?? this.unitPackaging,
      boxPalletMode: boxPalletMode ?? this.boxPalletMode,
      defaultUnitsPerBox: defaultUnitsPerBox ?? this.defaultUnitsPerBox,
      defaultBoxesPerPallet:
          defaultBoxesPerPallet ?? this.defaultBoxesPerPallet,
      configured: configured ?? this.configured,
    );
  }
}
