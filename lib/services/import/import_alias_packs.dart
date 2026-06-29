import 'import_header_intelligence.dart';

/// ERP / источник файла — определяет дополнительные синонимы колонок.
enum ImportAliasPack {
  priority,
  sapBusinessOne,
  iCount,
  hashavshevet,
  rivhit,
  excelGeneric,
}

/// Словари синонимов по ERP (fieldKey → aliases).
class ImportAliasPacks {
  static const packLabels = {
    ImportAliasPack.priority: 'Priority',
    ImportAliasPack.sapBusinessOne: 'SAP Business One',
    ImportAliasPack.iCount: 'iCount',
    ImportAliasPack.hashavshevet: 'Hashavshevet',
    ImportAliasPack.rivhit: 'Rivhit',
    ImportAliasPack.excelGeneric: 'Excel Generic',
  };

  /// Авто-определение ERP по заголовкам (макс. совпадений с пакетом).
  static ImportAliasPack detectPack(List<String> headers) {
    if (headers.isEmpty) return ImportAliasPack.excelGeneric;
    final normalized = headers.map(ImportHeaderIntelligence.normalize).toList();
    var best = ImportAliasPack.excelGeneric;
    var bestScore = 0;
    for (final pack in ImportAliasPack.values) {
      if (pack == ImportAliasPack.excelGeneric) continue;
      var score = 0;
      for (final sig in _signatures[pack] ?? const []) {
        if (normalized.any((h) => h == sig || h.contains(sig))) score += 5;
      }
      for (final h in normalized) {
        if (h.isEmpty) continue;
        for (final aliases in _packs[pack]!.values) {
          for (final a in aliases) {
            final na = ImportHeaderIntelligence.normalize(a);
            if (h == na) {
              score += 2;
              break;
            }
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = pack;
      }
    }
    return bestScore >= 4 ? best : ImportAliasPack.excelGeneric;
  }

  static const _signatures = {
    ImportAliasPack.priority: ['custcode', 'custname', 'partname', 'partdes'],
    ImportAliasPack.sapBusinessOne: ['cardcode', 'cardname', 'itemcode', 'itemname'],
    ImportAliasPack.iCount: ['clientid', 'clientname', 'productsku'],
    ImportAliasPack.hashavshevet: ['מספרלקוח', 'שםלקוח', 'מקט'],
    ImportAliasPack.rivhit: ['customerid', 'accnumber', 'accname'],
  };

  static List<String> aliasesFor(ImportAliasPack pack, String fieldKey) {
    return [
      ...?_packs[pack]?[fieldKey],
      ...?_packs[ImportAliasPack.excelGeneric]?[fieldKey],
    ];
  }

  static const _packs = {
    ImportAliasPack.priority: {
      'clientNumber': ['CustCode', 'CUSTCODE', 'מספר לקוח', 'קוד לקוח'],
      'name': ['CustName', 'CUSTNAME', 'שם לקוח'],
      'clientName': ['CustName', 'CUSTNAME', 'שם לקוח'],
      'address': ['ADDR', 'Address', 'כתובת'],
      'phone': ['Phone1', 'PHONE1', 'טלפון'],
      'vatId': ['VATNUM', 'ח.פ.', 'ע.מ.'],
      'productCode': ['PARTNAME', 'PART', 'מק"ט', 'מקט'],
      'productName': ['PARTDES', 'Description', 'תיאור'],
      'quantity': ['QTY', 'Balance', 'יתרה'],
      'boxes': ['Cartons', 'קרטונים'],
    },
    ImportAliasPack.sapBusinessOne: {
      'clientNumber': ['CardCode', 'CARDCODE', 'BpCode'],
      'name': ['CardName', 'CARDNAME', 'BpName'],
      'clientName': ['CardName', 'CARDNAME'],
      'address': ['Address', 'Street', 'ShipToAddress'],
      'phone': ['Phone1', 'Cellular'],
      'vatId': ['LicTradNum', 'FederalTaxID', 'VatRegNum'],
      'productCode': ['ItemCode', 'ITEMCODE', 'ItemNo'],
      'productName': ['ItemName', 'ITEMNAME', 'Dscription'],
      'quantity': ['Quantity', 'OnHand', 'InStock'],
      'barcode': ['BarCode', 'CodeBars'],
      'category': ['ItmsGrpNam'],
    },
    ImportAliasPack.iCount: {
      'clientNumber': ['client_id', 'client_number', 'מספר לקוח'],
      'name': ['client_name', 'name', 'שם לקוח'],
      'clientName': ['client_name', 'name'],
      'address': ['address', 'full_address', 'כתובת'],
      'phone': ['phone', 'mobile', 'טלפון'],
      'vatId': ['vat_id', 'company_id', 'ח.פ.'],
      'productCode': ['sku', 'product_sku', 'מק"ט'],
      'productName': ['product_name', 'description'],
      'quantity': ['quantity', 'stock'],
    },
    ImportAliasPack.hashavshevet: {
      'clientNumber': ['מס\' לקוח', 'מספר לקוח', 'קוד לקוח'],
      'name': ['שם לקוח', 'שם חשבון'],
      'clientName': ['שם לקוח'],
      'address': ['כתובת', 'כתובת למשלוח'],
      'phone': ['טלפון', 'נייד'],
      'vatId': ['ח.פ.', 'ע.מ.', 'מספר עוסק'],
      'productCode': ['מק"ט', 'מקט', 'קוד פריט'],
      'productName': ['שם פריט', 'תיאור פריט'],
      'quantity': ['כמות', 'יתרה'],
    },
    ImportAliasPack.rivhit: {
      'clientNumber': ['CustomerID', 'AccNumber', 'מספר לקוח'],
      'name': ['CustomerName', 'AccName', 'שם לקוח'],
      'clientName': ['CustomerName', 'AccName'],
      'address': ['Address', 'Street', 'כתובת'],
      'phone': ['Phone', 'Mobile'],
      'vatId': ['OsekNum', 'CompanyID', 'ח.פ.'],
      'productCode': ['ItemID', 'CatalogID', 'מק"ט'],
      'productName': ['ItemName', 'Description'],
    },
    ImportAliasPack.excelGeneric: {
      'clientNumber': [
        'client number', 'customer id', 'account number', 'код клиента',
        'номер клиента', 'מספר לקוח',
      ],
      'name': [
        'client', 'customer', 'customer name', 'company', 'клиент', 'название',
        'компания', 'שם לקוח', 'לקוח',
      ],
      'clientName': ['client name', 'customer name', 'שם לקוח', 'клиент'],
      'address': [
        'address', 'full address', 'shipping address', 'адрес', 'כתובת',
      ],
      'phone': ['phone', 'mobile', 'tel', 'телефон', 'טלפון'],
      'vatId': ['vat', 'tax id', 'vat id', 'инн', 'ח.פ.'],
      'productCode': ['sku', 'product code', 'item code', 'артикул', 'מקט'],
      'productName': ['product name', 'item name', 'description', 'товар'],
      'quantity': ['qty', 'quantity', 'stock', 'количество', 'כמות'],
      'barcode': ['barcode', 'ean', 'upc', 'штрихкод'],
      'boxes': ['boxes', 'cartons', 'коробки', 'קרטונים'],
      'deliveryAddressOverride': [
        'delivery address', 'shipping address', 'כתובת פריקה',
      ],
      'requestedDate': ['date', 'delivery date', 'תאריך', 'дата'],
      'contactName': ['contact', 'contact person', 'איש קשר'],
      'taskNote': ['note', 'notes', 'comment', 'הערה', 'примечание'],
    },
  };
}
