import '../../models/import_wizard_type.dart';
import '../client_import_service.dart';
import '../delivery_point_import_service.dart';
import '../product_import_service.dart';

/// Унифицированный парсинг строк импорта по типу и mapping.
class ImportRowParser {
  static List<dynamic> parseRows({
    required ImportWizardType type,
    required List<List<String>> rows,
    required Map<String, int> mapping,
  }) {
    switch (type) {
      case ImportWizardType.clients:
        return ClientImportService.parseWithMapping(rows, mapping);
      case ImportWizardType.products:
        return ProductImportService.parseWithMapping(rows, mapping);
      case ImportWizardType.deliveryPoints:
        return DeliveryPointImportService.parseWithMapping(rows, mapping);
    }
  }

  static bool rowIsValid(dynamic row) {
    if (row is ParsedClientRow) return row.isValid;
    if (row is ParsedProductRow) return row.isValid;
    if (row is ParsedDeliveryPointRow) return row.isValid;
    return false;
  }

  static int rowIndex(dynamic row) {
    if (row is ParsedClientRow) return row.rowIndex;
    if (row is ParsedProductRow) return row.rowIndex;
    if (row is ParsedDeliveryPointRow) return row.rowIndex;
    return 0;
  }

  static List<String> rowErrors(dynamic row) {
    if (row is ParsedClientRow) return row.errors;
    if (row is ParsedProductRow) return row.errors;
    if (row is ParsedDeliveryPointRow) return row.errors;
    return const [];
  }
}
