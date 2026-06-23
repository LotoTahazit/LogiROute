import '../../models/invoice.dart';
import '../../models/invoice_payment_line.dart';
import 'bkmv_codec.dart';

/// Параметры ПО для INI (horaot 1.31).
class BkmvSoftwareInfo {
  final String registrationNumber;
  final String name;
  final String version;
  final String manufacturerTaxId;
  final String manufacturerName;

  const BkmvSoftwareInfo({
    this.registrationNumber = '00000000',
    this.name = 'LogiRoute',
    this.version = '1.0.0',
    this.manufacturerTaxId = '000000000',
    this.manufacturerName = 'LogiRoute',
  });
}

/// Контекст компании для BKMV.
class BkmvCompanyContext {
  final String vatId;
  final String businessName;
  final String street;
  final String city;
  final String zipCode;

  const BkmvCompanyContext({
    required this.vatId,
    required this.businessName,
    this.street = '',
    this.city = '',
    this.zipCode = '',
  });
}

/// horaot 1.31 — длины строк фиксированы (без CRLF).
class BkmvRecords {
  BkmvRecords._();

  static const int lenA100 = 95;
  static const int lenC100 = 444;
  static const int lenD110 = 339;
  static const int lenD120 = 222;
  static const int lenZ900 = 110;
  static const int lenA000 = 466;
  static const int lenIniSummary = 19;

  static int invoiceDocTypeCode(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
        return 305;
      case InvoiceDocumentType.taxInvoiceReceipt:
        return 320;
      case InvoiceDocumentType.receipt:
        return 400;
      case InvoiceDocumentType.creditNote:
        return 330;
      case InvoiceDocumentType.delivery:
        return 200;
    }
  }

  static String encodeA100({
    required int recordNumber,
    required String vatId,
    required String primaryId,
  }) {
    final b = StringBuffer()
      ..write(BkmvCodec.alpha('A100', 4))
      ..write(BkmvCodec.numericInt(recordNumber, 9))
      ..write(BkmvCodec.vatId9(vatId))
      ..write(BkmvCodec.numeric(primaryId, 15))
      ..write(BkmvCodec.alpha(BkmvCodec.ofVersion, 8))
      ..write(BkmvCodec.alpha('', 50));
    final s = b.toString();
    BkmvCodec.assertLength(s, lenA100, 'A100');
    return s;
  }

  static String encodeZ900({
    required int recordNumber,
    required String vatId,
    required String primaryId,
    required int totalRecordsInFile,
  }) {
    final b = StringBuffer()
      ..write(BkmvCodec.alpha('Z900', 4))
      ..write(BkmvCodec.numericInt(recordNumber, 9))
      ..write(BkmvCodec.vatId9(vatId))
      ..write(BkmvCodec.numeric(primaryId, 15))
      ..write(BkmvCodec.alpha(BkmvCodec.ofVersion, 8))
      ..write(BkmvCodec.numericInt(totalRecordsInFile, 15))
      ..write(BkmvCodec.alpha('', 50));
    final s = b.toString();
    BkmvCodec.assertLength(s, lenZ900, 'Z900');
    return s;
  }

  static String encodeC100({
    required int recordNumber,
    required String vatId,
    required Invoice invoice,
    required int linkId,
  }) {
    final docType = invoiceDocTypeCode(invoice.documentType);
    final docNum = invoice.sequentialNumber > 0
        ? invoice.sequentialNumber.toString()
        : (invoice.id.length > 8 ? invoice.id.substring(0, 8) : invoice.id);
    final issueDate = invoice.finalizedAt ?? invoice.createdAt;
    final docDate = invoice.deliveryDate;
    final net = invoice.subtotalBeforeVAT;
    final vat = invoice.vatAmount;
    final gross = invoice.totalWithVAT;
    final sign = invoice.documentType == InvoiceDocumentType.creditNote ? -1.0 : 1.0;
    final allocation = invoice.assignmentNumber ?? '';

    final b = StringBuffer()
      ..write(BkmvCodec.alpha('C100', 4))
      ..write(BkmvCodec.numericInt(recordNumber, 9))
      ..write(BkmvCodec.vatId9(vatId))
      ..write(BkmvCodec.numericInt(docType, 3))
      ..write(BkmvCodec.alpha(docNum, 20))
      ..write(BkmvCodec.dateYmd(issueDate))
      ..write(BkmvCodec.timeHm(issueDate))
      ..write(BkmvCodec.alpha(invoice.clientName, 50))
      ..write(BkmvCodec.alpha(invoice.address, 50))
      ..write(BkmvCodec.alpha('', 10))
      ..write(BkmvCodec.alpha('', 30))
      ..write(BkmvCodec.alpha('', 8))
      ..write(BkmvCodec.alpha('', 30))
      ..write(BkmvCodec.alpha('', 2))
      ..write(BkmvCodec.alpha(allocation, 15))
      ..write(BkmvCodec.vatId9(invoice.clientNumber))
      ..write(BkmvCodec.dateYmd(docDate))
      ..write(BkmvCodec.alpha('', 15))
      ..write(BkmvCodec.alpha('ILS', 3))
      ..write(BkmvCodec.amount15(net * sign))
      ..write(BkmvCodec.amount15(0))
      ..write(BkmvCodec.amount15(net * sign))
      ..write(BkmvCodec.amount15(vat * sign))
      ..write(BkmvCodec.amount15(gross * sign))
      ..write(BkmvCodec.amount12(0))
      ..write(BkmvCodec.alpha(invoice.clientNumber, 15))
      ..write(BkmvCodec.alpha('', 10))
      ..write(BkmvCodec.alpha(
          (invoice.status == InvoiceStatus.cancelled ||
                  invoice.status == InvoiceStatus.voided)
              ? '1'
              : ' ',
          1))
      ..write(BkmvCodec.dateYmd(docDate))
      ..write(BkmvCodec.alpha('', 7))
      ..write(BkmvCodec.alpha(invoice.createdBy, 9))
      ..write(BkmvCodec.numericInt(linkId, 7))
      ..write(BkmvCodec.alpha('', 13));
    final s = b.toString();
    BkmvCodec.assertLength(s, lenC100, 'C100');
    return s;
  }

  static bool needsPaymentLines(InvoiceDocumentType type) =>
      type == InvoiceDocumentType.taxInvoiceReceipt ||
      type == InvoiceDocumentType.receipt;

  /// 1306: 1 מזומן, 2 המחאה, 3 כ.אשראי, 4 העברה בנקאית, 9 אחר.
  static int paymentMeansCode(String? method) {
    final m = (method ?? '').toLowerCase();
    if (m.contains('cash') || m.contains('מזומן')) return 1;
    if (m.contains('cheque') || m.contains('check') || m.contains('המחא')) {
      return 2;
    }
    if (m.contains('credit') || m.contains('אשראי')) return 3;
    if (m.contains('bank') || m.contains('העבר')) return 4;
    if (m.isEmpty) return 1;
    return 9;
  }

  static String encodeD120({
    required int recordNumber,
    required String vatId,
    required Invoice invoice,
    required int paymentLineIndex,
    required int linkId,
    required InvoicePaymentLine payment,
  }) {
    final docType = invoiceDocTypeCode(invoice.documentType);
    final docNum = invoice.sequentialNumber > 0
        ? invoice.sequentialNumber.toString()
        : invoice.id;
    final docDate = invoice.deliveryDate;
    final means = paymentMeansCode(payment.method);
    final isCheque = means == 2;
    final isCredit = means == 3;
    final isBank = means == 4;
    final due = payment.dueDate ?? invoice.paymentDueDate ?? docDate;
    final dueDate = (isCheque || isCredit)
        ? BkmvCodec.dateYmd(due)
        : BkmvCodec.numericInt(0, 8);
    final bankFields = isCheque || isBank;

    final b = StringBuffer()
      ..write(BkmvCodec.alpha('D120', 4))
      ..write(BkmvCodec.numericInt(recordNumber, 9))
      ..write(BkmvCodec.vatId9(vatId))
      ..write(BkmvCodec.numericInt(docType, 3))
      ..write(BkmvCodec.alpha(docNum, 20))
      ..write(BkmvCodec.numericInt(paymentLineIndex, 4))
      ..write(BkmvCodec.numericInt(means, 1))
      ..write(BkmvCodec.numeric(
          bankFields ? payment.bankNumber : null, 10))
      ..write(BkmvCodec.numeric(
          bankFields ? payment.branchNumber : null, 10))
      ..write(BkmvCodec.numeric(
          bankFields ? payment.accountNumber : null, 15))
      ..write(BkmvCodec.numeric(
          isCheque ? payment.chequeNumber : null, 10))
      ..write(dueDate)
      ..write(BkmvCodec.amount15(payment.amount))
      ..write(BkmvCodec.numericInt(
          isCredit ? (payment.clearingHouseCode ?? 0) : 0, 1))
      ..write(BkmvCodec.alpha(isCredit ? (payment.cardName ?? '') : '', 20))
      ..write(BkmvCodec.numericInt(
          isCredit ? payment.creditDealType : 0, 1))
      ..write(BkmvCodec.alpha('', 7))
      ..write(BkmvCodec.dateYmd(docDate))
      ..write(BkmvCodec.numericInt(linkId, 7))
      ..write(BkmvCodec.alpha('', 60));
    final s = b.toString();
    BkmvCodec.assertLength(s, lenD120, 'D120');
    return s;
  }

  static String encodeD110({
    required int recordNumber,
    required String vatId,
    required Invoice invoice,
    required InvoiceItem item,
    required int lineIndex,
    required int linkId,
  }) {
    final docType = invoiceDocTypeCode(invoice.documentType);
    final docNum = invoice.sequentialNumber > 0
        ? invoice.sequentialNumber.toString()
        : invoice.id;
    final docDate = invoice.deliveryDate;
    final qty = item.quantity.toDouble();
    final unitNet = item.pricePerUnit;
    final rate = item.vatRate ?? Invoice.vatRate;
    final lineNet = item.totalBeforeVAT * (invoice.documentType == InvoiceDocumentType.creditNote ? -1 : 1);
    final desc = item.description?.isNotEmpty == true
        ? item.description!
        : item.displayText;

    final b = StringBuffer()
      ..write(BkmvCodec.alpha('D110', 4))
      ..write(BkmvCodec.numericInt(recordNumber, 9))
      ..write(BkmvCodec.vatId9(vatId))
      ..write(BkmvCodec.numericInt(docType, 3))
      ..write(BkmvCodec.alpha(docNum, 20))
      ..write(BkmvCodec.numericInt(lineIndex, 4))
      ..write(BkmvCodec.numericInt(0, 3))
      ..write(BkmvCodec.alpha('', 20))
      ..write(BkmvCodec.numericInt(2, 1))
      ..write(BkmvCodec.alpha('', 20))
      ..write(BkmvCodec.alpha(desc, 30))
      ..write(BkmvCodec.alpha('', 50))
      ..write(BkmvCodec.alpha('', 30))
      ..write(BkmvCodec.alpha('יחידה', 20))
      ..write(BkmvCodec.quantity17(qty))
      ..write(BkmvCodec.amount15(unitNet))
      ..write(BkmvCodec.amount15(0))
      ..write(BkmvCodec.amount15(lineNet))
      ..write(BkmvCodec.vatRate4(rate))
      ..write(BkmvCodec.alpha('', 7))
      ..write(BkmvCodec.dateYmd(docDate))
      ..write(BkmvCodec.numericInt(linkId, 7))
      ..write(BkmvCodec.alpha('', 7))
      ..write(BkmvCodec.alpha('', 21));
    final s = b.toString();
    BkmvCodec.assertLength(s, lenD110, 'D110');
    return s;
  }

  static String encodeA000({
    required String vatId,
    required String primaryId,
    required int totalBkmvRecords,
    required BkmvCompanyContext company,
    required BkmvSoftwareInfo software,
    required DateTime fromDate,
    required DateTime toDate,
    required DateTime processStart,
  }) {
    final taxYear = fromDate.year;
    final b = StringBuffer()
      ..write(BkmvCodec.alpha('A000', 4))
      ..write(BkmvCodec.alpha('', 5))
      ..write(BkmvCodec.numericInt(totalBkmvRecords, 15))
      ..write(BkmvCodec.vatId9(vatId))
      ..write(BkmvCodec.numeric(primaryId, 15))
      ..write(BkmvCodec.alpha(BkmvCodec.ofVersion, 8))
      ..write(BkmvCodec.numeric(software.registrationNumber, 8))
      ..write(BkmvCodec.alpha(software.name, 20))
      ..write(BkmvCodec.alpha(software.version, 20))
      ..write(BkmvCodec.vatId9(software.manufacturerTaxId))
      ..write(BkmvCodec.alpha(software.manufacturerName, 20))
      ..write(BkmvCodec.numericInt(2, 1))
      ..write(BkmvCodec.alpha('', 50))
      ..write(BkmvCodec.numericInt(0, 1))
      ..write(BkmvCodec.numericInt(0, 1))
      ..write(BkmvCodec.numeric('', 9))
      ..write(BkmvCodec.numeric('', 9))
      ..write(BkmvCodec.alpha('', 10))
      ..write(BkmvCodec.alpha(company.businessName, 50))
      ..write(BkmvCodec.alpha(company.street, 50))
      ..write(BkmvCodec.alpha('', 10))
      ..write(BkmvCodec.alpha(company.city, 30))
      ..write(BkmvCodec.alpha(company.zipCode, 8))
      ..write(BkmvCodec.numericInt(taxYear, 4))
      ..write(BkmvCodec.dateYmd(fromDate))
      ..write(BkmvCodec.dateYmd(toDate))
      ..write(BkmvCodec.dateYmd(processStart))
      ..write(BkmvCodec.timeHm(processStart))
      ..write(BkmvCodec.numericInt(0, 1))
      ..write(BkmvCodec.numericInt(1, 1))
      ..write(BkmvCodec.alpha('', 20))
      ..write(BkmvCodec.alpha('ILS', 3))
      ..write(BkmvCodec.numericInt(0, 1))
      ..write(BkmvCodec.alpha('', 46));
    final s = b.toString();
    BkmvCodec.assertLength(s, lenA000, 'A000');
    return s;
  }

  static String encodeIniSummary(String recordCode, int count) {
    final s = BkmvCodec.alpha(recordCode, 4) +
        BkmvCodec.numericInt(count, 15);
    BkmvCodec.assertLength(s, lenIniSummary, 'INI summary $recordCode');
    return s;
  }
}
