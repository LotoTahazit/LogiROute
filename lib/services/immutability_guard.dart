import '../models/invoice.dart';

/// חריגת אי-שינוי — נזרקת כשמנסים לשנות שדה מוגן
class ImmutabilityException implements Exception {
  final String field;
  final String invoiceId;
  final String message;

  ImmutabilityException({
    required this.field,
    required this.invoiceId,
    required this.message,
  });

  /// הודעה מקומית בעברית
  String get localizedMessage => message;

  @override
  String toString() => 'ImmutabilityException($field): $message';
}

/// שומר אי-שינוי — UX בלבד!
/// הערבות המשפטית — Firestore Security Rules.
/// Guard זה רק מונע שליחת בקשות שיידחו בצד השרת.
class ImmutabilityGuard {
  ImmutabilityGuard._();
  static final instance = ImmutabilityGuard._();

  /// שדות מוגנים — לא ניתנים לשינוי לאחר סיום
  static const List<String> protectedFields = [
    'companyId',
    'sequentialNumber',
    'clientName',
    'clientNumber',
    'address',
    'driverName',
    'truckNumber',
    'departureTime',
    'items',
    'discount',
    'deliveryDate',
    'paymentDueDate',
    'createdAt',
    'createdBy',
    'documentType',
    'finalizedAt',
    'finalizedBy',
    'immutableSnapshotHash',
    'linkedInvoiceId',
  ];

  /// שדות מותרים לעדכון לאחר סיום (whitelist)
  static const List<String> whitelistFields = [
    'lastViewedAt',
    'printedCount',
    'exportedAt',
    'originalPrinted',
    'copiesPrinted',
    'status', // רק final→cancelled עם linkedCreditNoteId
    'assignmentNumber',
    'assignmentStatus',
    'assignmentRequestedAt',
    'assignmentResponseRaw',
  ];

  /// בודק אם ניתן לשנות שדה. זורק ImmutabilityException אם לא.
  void assertCanModifyField(Invoice invoice, String fieldName) {
    // טיוטות ניתנות לעריכה
    if (invoice.status == InvoiceStatus.draft) return;

    // מסמך לא עבר סיום — ניתן לעריכה
    if (!invoice.isFinalized) return;

    if (protectedFields.contains(fieldName)) {
      throw ImmutabilityException(
        field: fieldName,
        invoiceId: invoice.id,
        message: 'שדה $fieldName לא ניתן לשינוי לאחר אישור המסמך',
      );
    }

    if (whitelistFields.contains(fieldName)) {
      return; // מותר — הקורא צריך לרשום ביומן ביקורת
    }

    throw ImmutabilityException(
      field: fieldName,
      invoiceId: invoice.id,
      message: 'שדה לא מוכר: $fieldName',
    );
  }

  /// בודק אם ניתן למחוק מסמך. תמיד זורק למסמכים שעברו סיום.
  void assertCanDelete(Invoice invoice) {
    throw ImmutabilityException(
      field: '*',
      invoiceId: invoice.id,
      message: 'מחיקת מסמכים חשבונאיים אסורה לפי חוק ניהול ספרים',
    );
  }
}
