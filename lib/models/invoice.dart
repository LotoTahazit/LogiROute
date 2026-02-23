import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceCopyType {
  original, // מקור
  copy, // עותק
  replacesOriginal, // נעימן למקור
}

/// Invoice status for compliance with Israeli tax law
/// חשבונית לא ניתנת למחיקה - רק לביטול
enum InvoiceStatus {
  active, // פעיל - חשבונית תקפה
  cancelled, // מבוטל - חשבונית מבוטלת (סטורנו)
  draft, // טיוטה - לא סופי (אם נדרש)
}

/// Audit log entry for invoice changes
/// נדרש לפי חוק ניהול ספרים
class InvoiceAuditEntry {
  final DateTime timestamp;
  final String action; // created, printed, cancelled, etc.
  final String performedBy;
  final String? details;

  InvoiceAuditEntry({
    required this.timestamp,
    required this.action,
    required this.performedBy,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'action': action,
      'performedBy': performedBy,
      if (details != null) 'details': details,
    };
  }

  factory InvoiceAuditEntry.fromMap(Map<String, dynamic> map) {
    return InvoiceAuditEntry(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      details: map['details'],
    );
  }
}

class InvoiceItem {
  final String
      productCode; // מק"ט - артикул товара (ОБЯЗАТЕЛЬНОЕ) - ПЕРВОЕ ПОЛЕ
  final String type; // "בביע", "מכסה", "כוס"
  final String number; // "100", "200", etc.
  final int quantity; // Количество единиц
  final double pricePerUnit; // Цена за единицу (до НДС)

  InvoiceItem({
    required this.productCode, // מק"ט - ОБЯЗАТЕЛЬНОЕ поле - ПЕРВЫЙ ПАРАМЕТР
    required this.type,
    required this.number,
    required this.quantity,
    required this.pricePerUnit,
  });

  double get totalBeforeVAT => quantity * pricePerUnit;

  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode, // מק"ט - ПЕРВОЕ ПОЛЕ в Map
      'type': type,
      'number': number,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productCode: map['productCode'] ?? '', // מק"ט - ОБЯЗАТЕЛЬНОЕ поле
      type: map['type'] ?? '',
      number: map['number'] ?? '',
      quantity: map['quantity'] ?? 0,
      pricePerUnit: (map['pricePerUnit'] is num)
          ? (map['pricePerUnit'] as num).toDouble()
          : 0.0,
    );
  }
}

class Invoice {
  final String id;
  final int sequentialNumber; // מספר רץ - REQUIRED by Israeli tax law
  final String clientName;
  final String clientNumber;
  final String address;
  final String driverName;
  final String truckNumber;
  final DateTime deliveryDate; // Дата доставки (по умолчанию завтра)
  final DateTime?
      paymentDueDate; // תשלום עד - дата оплаты (если null - используется deliveryDate)
  final DateTime departureTime; // Время выезда (всегда 7:00)
  final List<InvoiceItem> items;
  final double discount; // Скидка в שקלים (не процент!)
  final DateTime createdAt;
  final String createdBy;
  final bool originalPrinted; // Был ли напечатан оригинал
  final int copiesPrinted; // Количество напечатанных копий
  final InvoiceStatus status; // סטטוס חשבונית
  final DateTime? cancelledAt; // מתי בוטל
  final String? cancelledBy; // מי ביטל
  final String? cancellationReason; // סיבת ביטול
  final List<InvoiceAuditEntry> auditLog; // יומן שינויים

  Invoice({
    required this.id,
    required this.sequentialNumber,
    required this.clientName,
    required this.clientNumber,
    required this.address,
    required this.driverName,
    required this.truckNumber,
    required this.deliveryDate,
    this.paymentDueDate, // Опциональное поле
    required this.departureTime,
    required this.items,
    this.discount = 0.0,
    required this.createdAt,
    required this.createdBy,
    this.originalPrinted = false,
    this.copiesPrinted = 0,
    this.status = InvoiceStatus.active,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.auditLog = const [],
  });

  // Константа НДС в Израиле
  static const double VAT_RATE = 0.18;

  // Сумма всех товаров до скидки и НДС
  double get totalBeforeDiscount {
    return items.fold(0.0, (sum, item) => sum + item.totalBeforeVAT);
  }

  // Сумма скидки в шекелях (рассчитывается из процентов)
  double get discountAmount {
    return totalBeforeDiscount * (discount / 100);
  }

  // Сумма до НДС (с учётом скидки)
  double get subtotalBeforeVAT {
    return totalBeforeDiscount - discountAmount;
  }

  // Сумма НДС
  double get vatAmount => subtotalBeforeVAT * VAT_RATE;

  // Итоговая сумма
  double get totalWithVAT => subtotalBeforeVAT + vatAmount;

  /// Check if invoice can be cancelled
  /// חשבונית ניתנת לביטול רק אם היא פעילה
  bool get canBeCancelled => status == InvoiceStatus.active;

  /// Check if invoice is immutable (cannot be modified)
  /// חשבונית לא ניתנת לשינוי לאחר יצירה
  bool get isImmutable => status != InvoiceStatus.draft;

  Map<String, dynamic> toMap() {
    return {
      'sequentialNumber': sequentialNumber,
      'clientName': clientName,
      'clientNumber': clientNumber,
      'address': address,
      'driverName': driverName,
      'truckNumber': truckNumber,
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      if (paymentDueDate != null)
        'paymentDueDate': Timestamp.fromDate(paymentDueDate!),
      'departureTime': Timestamp.fromDate(departureTime),
      'items': items.map((item) => item.toMap()).toList(),
      'discount': discount,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'originalPrinted': originalPrinted,
      'copiesPrinted': copiesPrinted,
      'status': status.name,
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      'auditLog': auditLog.map((entry) => entry.toMap()).toList(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      sequentialNumber: map['sequentialNumber'] ?? 0,
      clientName: map['clientName'] ?? '',
      clientNumber: map['clientNumber'] ?? '',
      address: map['address'] ?? '',
      driverName: map['driverName'] ?? '',
      truckNumber: map['truckNumber'] ?? '',
      deliveryDate: map['deliveryDate'] != null
          ? (map['deliveryDate'] as Timestamp).toDate()
          : DateTime.now(),
      paymentDueDate: map['paymentDueDate'] != null
          ? (map['paymentDueDate'] as Timestamp).toDate()
          : null,
      departureTime: map['departureTime'] != null
          ? (map['departureTime'] as Timestamp).toDate()
          : DateTime.now(),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      discount:
          (map['discount'] is num) ? (map['discount'] as num).toDouble() : 0.0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      originalPrinted: map['originalPrinted'] ?? false,
      copiesPrinted: map['copiesPrinted'] ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.active,
      ),
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancelledBy: map['cancelledBy'],
      cancellationReason: map['cancellationReason'],
      auditLog: (map['auditLog'] as List<dynamic>?)
              ?.map((entry) =>
                  InvoiceAuditEntry.fromMap(entry as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// copyWith - НЕ ИСПОЛЬЗУЕТСЯ для изменения существующих счетов
  /// Только для внутренних операций (например, обновление счетчиков печати)
  /// ⚠️ ВАЖНО: Изменение данных счета после создания ЗАПРЕЩЕНО по закону
  Invoice copyWith({
    String? id,
    int? sequentialNumber,
    String? clientName,
    String? clientNumber,
    String? address,
    String? driverName,
    String? truckNumber,
    DateTime? deliveryDate,
    DateTime? departureTime,
    List<InvoiceItem>? items,
    double? discount,
    DateTime? createdAt,
    String? createdBy,
    bool? originalPrinted,
    int? copiesPrinted,
    InvoiceStatus? status,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    List<InvoiceAuditEntry>? auditLog,
  }) {
    return Invoice(
      id: id ?? this.id,
      sequentialNumber: sequentialNumber ?? this.sequentialNumber,
      clientName: clientName ?? this.clientName,
      clientNumber: clientNumber ?? this.clientNumber,
      address: address ?? this.address,
      driverName: driverName ?? this.driverName,
      truckNumber: truckNumber ?? this.truckNumber,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      departureTime: departureTime ?? this.departureTime,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      originalPrinted: originalPrinted ?? this.originalPrinted,
      copiesPrinted: copiesPrinted ?? this.copiesPrinted,
      status: status ?? this.status,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}
