import '../models/product_type.dart';
import '../models/box_type.dart';

/// Адаптер для конвертации ProductType в BoxType (обратная совместимость)
class ProductTypeAdapter {
  /// Конвертирует ProductType в BoxType
  static BoxType toBoxType(ProductType productType, int quantity) {
    return BoxType(
      type: productType.category,
      number: productType.name,
      quantity: quantity,
      productCode: productType.productCode,
      volumeMl: 0,
      companyId: productType.companyId,
    );
  }

  /// Конвертирует список ProductType в BoxType
  static List<BoxType> toBoxTypes(
      List<ProductType> productTypes, Map<String, int> quantities) {
    return productTypes.map((pt) {
      final quantity = quantities[pt.id] ?? 1;
      return toBoxType(pt, quantity);
    }).toList();
  }

  /// Получает название для отображения (category + name)
  static String getDisplayName(ProductType productType) {
    return '${productType.name} (${productType.productCode})';
  }
}
