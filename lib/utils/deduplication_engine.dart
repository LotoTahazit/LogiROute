import '../models/product_type.dart';
import '../models/template_product.dart';

/// Утилита для дедупликации товаров при импорте шаблонов.
///
/// Обеспечивает нормализацию имён и проверку дубликатов
/// по productCode и normalizedName + categoryKey.
class DeduplicationEngine {
  /// Нормализация имени: toLowerCase + trim + collapse whitespace.
  ///
  /// Приводит строку к нижнему регистру, удаляет пробелы по краям
  /// и схлопывает множественные пробельные символы в один пробел.
  ///
  /// Примеры:
  /// - `"  Hello World  "` → `"hello world"`
  /// - `"Cup  Large"` → `"cup large"`
  /// - `""` → `""`
  static String normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Проверка дубликата по двухуровневой стратегии:
  /// 1) productCode совпадает → дубликат
  /// 2) normalizedName + categoryKey совпадают → дубликат
  static bool isDuplicate(
      TemplateProduct template, List<ProductType> existing) {
    for (final product in existing) {
      // Primary: совпадение по productCode
      if (product.productCode == template.productCode) {
        return true;
      }
      // Fallback: совпадение по normalizedName + categoryKey
      if (normalizeName(product.name) == normalizeName(template.name) &&
          product.category == template.category) {
        return true;
      }
    }
    return false;
  }

  /// Фильтрация списка шаблонов: разделение на не-дубликаты и дубликаты.
  ///
  /// Каждый товар оценивается независимо через [isDuplicate].
  /// Возвращает record с двумя списками:
  /// - `toImport` — шаблоны, не найденные среди существующих товаров
  /// - `skipped` — шаблоны, являющиеся дубликатами
  ///
  /// Гарантия: `toImport.length + skipped.length == templates.length`
  static ({List<TemplateProduct> toImport, List<TemplateProduct> skipped})
      filterDuplicates(
          List<TemplateProduct> templates, List<ProductType> existing) {
    final toImport = <TemplateProduct>[];
    final skipped = <TemplateProduct>[];

    for (final template in templates) {
      if (isDuplicate(template, existing)) {
        skipped.add(template);
      } else {
        toImport.add(template);
      }
    }

    return (toImport: toImport, skipped: skipped);
  }
}
