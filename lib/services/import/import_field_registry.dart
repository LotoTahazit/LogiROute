import '../../l10n/app_localizations.dart';
import '../../models/import_wizard_type.dart';
import '../../widgets/column_mapping_dialog.dart';
import '../client_import_service.dart';
import '../delivery_point_import_service.dart';

/// Реестр полей импорта с расширенными синонимами (he/en/ru).
class ImportFieldRegistry {
  static List<TargetField> fieldsFor(
    ImportWizardType type,
    AppLocalizations l10n,
  ) {
    switch (type) {
      case ImportWizardType.clients:
        return _clientsFields(l10n);
      case ImportWizardType.products:
        return _productsFields(l10n);
      case ImportWizardType.deliveryPoints:
        return _deliveryPointsFields(l10n);
    }
  }

  static List<TargetField> _clientsFields(AppLocalizations l10n) {
    final base = ClientImportService.getTargetFields(l10n);
    return base.map((f) {
      final extra = _clientSynonyms[f.key] ?? const <String>[];
      return TargetField(
        key: f.key,
        label: f.label,
        required: f.required,
        aliases: [...f.aliases, ...extra],
      );
    }).toList();
  }

  static List<TargetField> _productsFields(AppLocalizations l10n) => [
        TargetField(
          key: 'productCode',
          label: l10n.colProductCode,
          required: true,
          aliases: _productSynonyms['productCode']!,
        ),
        TargetField(
          key: 'productName',
          label: l10n.productName,
          required: true,
          aliases: _productSynonyms['productName']!,
        ),
        TargetField(
          key: 'quantity',
          label: l10n.colQuantity,
          aliases: _productSynonyms['quantity']!,
        ),
        TargetField(
          key: 'barcode',
          label: l10n.barcodeScanFieldLabel,
          aliases: _productSynonyms['barcode']!,
        ),
        TargetField(
          key: 'unitsPerBox',
          label: l10n.unitsPerBox,
          aliases: _productSynonyms['unitsPerBox']!,
        ),
        TargetField(
          key: 'piecesPerBox',
          label: l10n.colPiecesPerBox,
          aliases: _productSynonyms['piecesPerBox']!,
        ),
        TargetField(
          key: 'category',
          label: l10n.category,
          aliases: _productSynonyms['category']!,
        ),
        TargetField(
          key: 'volume',
          label: l10n.colVolume,
          aliases: _productSynonyms['volume']!,
        ),
        TargetField(
          key: 'weight',
          label: l10n.weight,
          aliases: _productSynonyms['weight']!,
        ),
      ];

  static List<TargetField> _deliveryPointsFields(AppLocalizations l10n) {
    final base = DeliveryPointImportService.getTargetFields(l10n);
    final keys = base.map((f) => f.key).toSet();
    final merged = base.map((f) {
      final extra = _deliverySynonyms[f.key] ?? const <String>[];
      return TargetField(
        key: f.key,
        label: f.label,
        required: f.key == 'clientName' || f.key == 'address' ? false : f.required,
        aliases: [...f.aliases, ...extra],
      );
    }).toList();

    for (final entry in _deliverySynonyms.entries) {
      if (keys.contains(entry.key)) continue;
      merged.add(TargetField(
        key: entry.key,
        label: _deliveryLabel(l10n, entry.key),
        aliases: entry.value,
      ));
    }
    return merged;
  }

  static String _deliveryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'deliveryAddressOverride':
        return l10n.deliveryAddressOverrideLabel;
      case 'deliveryAddressOverrideLat':
        return l10n.colLatitude;
      case 'deliveryAddressOverrideLng':
        return l10n.colLongitude;
      case 'requestedDate':
        return l10n.columnDate;
      case 'phone':
        return l10n.colPhone;
      case 'contactName':
        return l10n.colContactPerson;
      default:
        return key;
    }
  }

  static const _clientSynonyms = <String, List<String>>{
    'name': [
      'client', 'customer', 'customer name', 'client name', 'company', 'business',
      'account', 'שם לקוח', 'לקוח', 'שם', 'חברה', 'עסק', 'клиент', 'название',
      'название клиента', 'компания', 'CustomerName', 'CustName', 'Client_Name',
    ],
    'address': [
      'full address', 'shipping address', 'delivery address', 'כתובת מלאה',
      'כתובת משלוח', 'адрес', 'полный адрес', 'адрес доставки',
    ],
    'phone': [
      'mobile', 'telephone', 'tel', 'נייד', 'телефон', 'мобильный',
      'Phone1', 'MobilePhone',
    ],
    'vatId': [
      'vat', 'vat id', 'tax id', 'חפ', 'עוסק מורשה', 'номер налогоплательщика', 'инн',
    ],
    'clientNumber': [
      'client number', 'customer id', 'account number', 'מספר לקוח', 'код клиента',
      'номер клиента', 'CustCode',
    ],
  };

  static const _productSynonyms = <String, List<String>>{
    'productCode': [
      'sku', 'product code', 'item code', 'item no', 'מק"ט', 'מקט', 'קוד פריט',
      'код товара', 'артикул', 'ProductCode', 'ItemNo', 'PARTNAME',
    ],
    'productName': [
      'product name', 'item name', 'description', 'name', 'שם מוצר', 'שם פריט',
      'תיאור', 'товар', 'название товара', 'описание', 'PARTDES',
    ],
    'quantity': [
      'qty', 'stock', 'inventory', 'מלאי', 'כמות', 'количество', 'остаток',
    ],
    'barcode': ['ברקוד', 'штрихкод', 'EAN', 'UPC'],
    'unitsPerBox': ['units per box', 'יחידות בקופסה', 'единиц в коробке'],
    'piecesPerBox': ['pieces per box', 'יחידות', 'штук в коробке'],
    'category': ['cat', 'קטגוריה', 'категория', 'type'],
    'volume': ['vol', 'נפח', 'объём', 'литр'],
    'weight': ['wt', 'משקל', 'вес', 'кг'],
  };

  static const _deliverySynonyms = <String, List<String>>{
    'clientName': [
      'client', 'customer', 'client name', 'customer name', 'שם לקוח', 'לקוח', 'клиент',
      'CustName', 'CustomerName',
    ],
    'clientNumber': [
      'client number', 'customer id', 'מספר לקוח', 'код клиента',
    ],
    'address': ['address', 'כתובת', 'адрес', 'ADDR'],
    'deliveryAddressOverride': [
      'delivery address', 'shipping address', 'dropoff address', 'unload address',
      'כתובת פריקה', 'адрес разгрузки', 'разовый адрес',
    ],
    'taskNote': [
      'note', 'notes', 'comment', 'comments', 'הערה', 'הערות', 'примечание', 'комментарий',
    ],
    'boxes': ['cartons', 'ארגזים', 'קרטונים', 'коробки'],
    'pallets': ['משטחים', 'паллеты'],
    'requestedDate': [
      'date', 'delivery date', 'requested date', 'תאריך', 'תאריך משלוח', 'дата',
      'дата доставки',
    ],
    'phone': ['phone', 'mobile', 'טלפון', 'телефон'],
    'contactName': ['contact', 'איש קשר', 'контакт'],
  };
}
