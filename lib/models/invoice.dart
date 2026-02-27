import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum InvoiceCopyType {
  original, // מקור
  copy, // עותק
  replacesOriginal, // נאמן למקור
}

/// Invoice status for compliance with Israeli tax law
/// חשבונית לא ניתנת למחיקה - רק לביטול
enum InvoiceStatus {
  active, // פעיל - חשבונית תקפה
  cancelled, // מבוטל - חשבונית מבוטלת (סטורנו)
  draft, // טיוטה - לא סופי (אם נדרש)
}

/// סוג מסמך חשבונאי
enum InvoiceDocumentType {
  invoice, // חשבונית מס
  receipt, // קבלה
  delivery, // תעודת משלוח
  creditNote, // זיכוי
  taxInvoiceReceipt, // חשבונית מס / קבלה
}

/// סטטוס מספר הקצאה מרשות המסים
enum AssignmentStatus {
  notRequired, // לא נדרש — מתחת לסף
  pending, // ממתין לתשובה מרשות המסים
  approved, // אושר — מספר הקצאה התקבל
  rejected, // נדחה — סירוב מרשות המסים
  error, // שגיאה טכנית
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
  final String companyId; // ID компании для изоляции данных
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
  final List<InvoiceAuditEntry> auditLog; // יומן שינויים (legacy — массив)
  // === שדות חדשים לפי מסמך עיצוב ===
  final InvoiceDocumentType documentType; // סוג מסמך
  final String? linkedInvoiceId; // לזיכויים: הפניה למקור
  final DateTime? finalizedAt; // תאריך סיום (זמן שרת)
  final String? finalizedBy; // UID של המסיים
  final String? immutableSnapshotHash; // SHA-256 משדות מוגנים ("מנעול" שרת)
  final DateTime? lastViewedAt; // שדה טכני
  final int printedCount; // מונה הדפסות
  final DateTime? exportedAt; // תאריך ייצוא
  // === שדות מספר הקצאה (חשבוניות ישראל) ===
  final String? assignmentNumber; // מספר הקצאה מרשות המסים
  final AssignmentStatus assignmentStatus; // סטטוס הקצאה
  final DateTime? assignmentRequestedAt; // מתי נשלחה הבקשה
  final String? assignmentResponseRaw; // תשובה גולמית מה-API
  final String?
      deliveryPointId; // ID точки доставки — для предотвращения дублей
  final String? paymentMethod; // אופן תשלום (для taxInvoiceReceipt)

  Invoice({
    required this.id,
    required this.companyId,
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
    this.documentType = InvoiceDocumentType.invoice,
    this.linkedInvoiceId,
    this.finalizedAt,
    this.finalizedBy,
    this.immutableSnapshotHash,
    this.lastViewedAt,
    this.printedCount = 0,
    this.exportedAt,
    this.assignmentNumber,
    this.assignmentStatus = AssignmentStatus.notRequired,
    this.assignmentRequestedAt,
    this.assignmentResponseRaw,
    this.deliveryPointId,
    this.paymentMethod,
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
  /// חשבונית לא ניתנת לשינוי לאחר סיום
  bool get isImmutable => finalizedAt != null;

  /// Check if invoice is finalized
  bool get isFinalized => finalizedAt != null;

  /// בדיקה אם נדרש מספר הקצאה — לפי סף וסוג מסמך
  bool get requiresAssignment {
    // רק חשבוניות מס דורשות מספר הקצאה
    if (documentType != InvoiceDocumentType.invoice &&
        documentType != InvoiceDocumentType.taxInvoiceReceipt) return false;
    final threshold = _getAssignmentThreshold(DateTime.now());
    return subtotalBeforeVAT >= threshold;
  }

  /// סף מספר הקצאה לפי תאריך (סכום לפני מע״מ)
  static double _getAssignmentThreshold(DateTime date) {
    // 01.06.2026 ואילך: 5,000 ₪
    if (date.isAfter(DateTime(2026, 6, 1)) ||
        date.isAtSameMomentAs(DateTime(2026, 6, 1))) {
      return 5000.0;
    }
    // 01.01.2026 ואילך: 10,000 ₪
    if (date.isAfter(DateTime(2026, 1, 1)) ||
        date.isAtSameMomentAs(DateTime(2026, 1, 1))) {
      return 10000.0;
    }
    // 2025: 20,000 ₪
    return 20000.0;
  }

  /// בדיקה אם ניתן להדפיס מקור — חסימה אם ממתין/נדחה מספר הקצאה
  bool get canPrintOriginal {
    if (!requiresAssignment) return true;
    return assignmentStatus == AssignmentStatus.approved ||
        assignmentStatus == AssignmentStatus.notRequired;
  }

  /// חישוב SHA-256 hash משדות מוגנים + סכומים — "מנעול" שרת
  /// כולל: כל שדות מוגנים + totalBeforeVAT + vatAmount + totalWithVAT
  String computeSnapshotHash() {
    final buffer = StringBuffer();
    buffer.write(companyId);
    buffer.write(sequentialNumber);
    buffer.write(clientName);
    buffer.write(clientNumber);
    buffer.write(address);
    buffer.write(driverName);
    buffer.write(truckNumber);
    buffer.write(departureTime.toIso8601String());
    for (final item in items) {
      buffer.write(item.productCode);
      buffer.write(item.type);
      buffer.write(item.number);
      buffer.write(item.quantity);
      buffer.write(item.pricePerUnit);
    }
    buffer.write(discount);
    buffer.write(deliveryDate.toIso8601String());
    if (paymentDueDate != null) {
      buffer.write(paymentDueDate!.toIso8601String());
    }
    buffer.write(createdAt.toIso8601String());
    buffer.write(createdBy);
    buffer.write(documentType.name);
    if (linkedInvoiceId != null) {
      buffer.write(linkedInvoiceId!);
    }
    // סכומים — קריטי למס
    buffer.write(subtotalBeforeVAT.toStringAsFixed(2));
    buffer.write(vatAmount.toStringAsFixed(2));
    buffer.write(totalWithVAT.toStringAsFixed(2));
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
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
      'documentType': documentType.name,
      if (linkedInvoiceId != null) 'linkedInvoiceId': linkedInvoiceId,
      if (finalizedAt != null) 'finalizedAt': Timestamp.fromDate(finalizedAt!),
      if (finalizedBy != null) 'finalizedBy': finalizedBy,
      if (immutableSnapshotHash != null)
        'immutableSnapshotHash': immutableSnapshotHash,
      if (lastViewedAt != null)
        'lastViewedAt': Timestamp.fromDate(lastViewedAt!),
      'printedCount': printedCount,
      if (exportedAt != null) 'exportedAt': Timestamp.fromDate(exportedAt!),
      if (assignmentNumber != null) 'assignmentNumber': assignmentNumber,
      'assignmentStatus': assignmentStatus.name,
      if (assignmentRequestedAt != null)
        'assignmentRequestedAt': Timestamp.fromDate(assignmentRequestedAt!),
      if (assignmentResponseRaw != null)
        'assignmentResponseRaw': assignmentResponseRaw,
      if (deliveryPointId != null) 'deliveryPointId': deliveryPointId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      companyId: map['companyId'] ?? '',
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
      documentType: InvoiceDocumentType.values.firstWhere(
        (e) => e.name == map['documentType'],
        orElse: () => InvoiceDocumentType.invoice,
      ),
      linkedInvoiceId: map['linkedInvoiceId'],
      finalizedAt: map['finalizedAt'] != null
          ? (map['finalizedAt'] as Timestamp).toDate()
          : null,
      finalizedBy: map['finalizedBy'],
      immutableSnapshotHash: map['immutableSnapshotHash'],
      lastViewedAt: map['lastViewedAt'] != null
          ? (map['lastViewedAt'] as Timestamp).toDate()
          : null,
      printedCount: map['printedCount'] ?? 0,
      exportedAt: map['exportedAt'] != null
          ? (map['exportedAt'] as Timestamp).toDate()
          : null,
      assignmentNumber: map['assignmentNumber'],
      assignmentStatus: AssignmentStatus.values.firstWhere(
        (e) => e.name == map['assignmentStatus'],
        orElse: () => AssignmentStatus.notRequired,
      ),
      assignmentRequestedAt: map['assignmentRequestedAt'] != null
          ? (map['assignmentRequestedAt'] as Timestamp).toDate()
          : null,
      assignmentResponseRaw: map['assignmentResponseRaw'],
      deliveryPointId: map['deliveryPointId'],
      paymentMethod: map['paymentMethod'],
    );
  }

  /// copyWith - НЕ ИСПОЛЬЗУЕТСЯ для изменения существующих счетов
  /// Только для внутренних операций (например, обновление счетчиков печати)
  /// ⚠️ ВАЖНО: Изменение данных счета после создания ЗАПРЕЩЕНО по закону
  Invoice copyWith({
    String? id,
    String? companyId,
    int? sequentialNumber,
    String? clientName,
    String? clientNumber,
    String? address,
    String? driverName,
    String? truckNumber,
    DateTime? deliveryDate,
    DateTime? paymentDueDate,
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
    InvoiceDocumentType? documentType,
    String? linkedInvoiceId,
    DateTime? finalizedAt,
    String? finalizedBy,
    String? immutableSnapshotHash,
    DateTime? lastViewedAt,
    int? printedCount,
    DateTime? exportedAt,
    String? assignmentNumber,
    AssignmentStatus? assignmentStatus,
    DateTime? assignmentRequestedAt,
    String? assignmentResponseRaw,
    String? deliveryPointId,
    String? paymentMethod,
  }) {
    return Invoice(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      sequentialNumber: sequentialNumber ?? this.sequentialNumber,
      clientName: clientName ?? this.clientName,
      clientNumber: clientNumber ?? this.clientNumber,
      address: address ?? this.address,
      driverName: driverName ?? this.driverName,
      truckNumber: truckNumber ?? this.truckNumber,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
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
      documentType: documentType ?? this.documentType,
      linkedInvoiceId: linkedInvoiceId ?? this.linkedInvoiceId,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      immutableSnapshotHash:
          immutableSnapshotHash ?? this.immutableSnapshotHash,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      printedCount: printedCount ?? this.printedCount,
      exportedAt: exportedAt ?? this.exportedAt,
      assignmentNumber: assignmentNumber ?? this.assignmentNumber,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      assignmentRequestedAt:
          assignmentRequestedAt ?? this.assignmentRequestedAt,
      assignmentResponseRaw:
          assignmentResponseRaw ?? this.assignmentResponseRaw,
      deliveryPointId: deliveryPointId ?? this.deliveryPointId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
