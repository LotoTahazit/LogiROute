import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/invoice.dart';
import 'package:logiroute/models/invoice_payment_line.dart';
import 'package:logiroute/services/bkmv/bkmv_exporter.dart';
import 'package:logiroute/services/bkmv/bkmv_records.dart';
import 'package:logiroute/services/bkmv/bkmv_simulator.dart';

Invoice _inv({
  required int seq,
  required InvoiceDocumentType type,
  List<InvoicePaymentLine> paymentLines = const [],
  String? paymentMethod,
}) {
  final d = DateTime(2025, 6, 15);
  return Invoice(
    id: 'id$seq',
    companyId: 'c1',
    sequentialNumber: seq,
    clientName: 'Client',
    clientNumber: '514123456',
    address: 'Addr',
    driverName: '',
    truckNumber: '',
    deliveryDate: d,
    departureTime: d,
    items: [
      InvoiceItem(
        productCode: 'P',
        type: 'box',
        number: '1',
        quantity: 1,
        piecesPerBox: 1,
        pricePerUnit: 100,
        description: 'Item',
        vatRate: 0.18,
      ),
    ],
    createdAt: d,
    createdBy: 'u1',
    documentType: type,
    status: InvoiceStatus.issued,
    paymentMethod: paymentMethod,
    paymentLines: paymentLines,
  );
}

void main() {
  test('simulator passes realistic mixed export', () {
    final export = BkmvExporter(
      company: const BkmvCompanyContext(
        vatId: '514123456',
        businessName: 'Test Co',
      ),
    ).build(
      invoices: [
        _inv(seq: 101, type: InvoiceDocumentType.invoice),
        _inv(
          seq: 102,
          type: InvoiceDocumentType.taxInvoiceReceipt,
          paymentMethod: 'cash',
        ),
        _inv(
          seq: 103,
          type: InvoiceDocumentType.receipt,
          paymentLines: [
            InvoicePaymentLine(
              method: 'cheque',
              amount: 118,
              bankNumber: '12',
              branchNumber: '345',
              accountNumber: '6789012',
              chequeNumber: '55',
              dueDate: DateTime(2025, 7, 1),
            ),
          ],
        ),
        _inv(
          seq: 104,
          type: InvoiceDocumentType.creditNote,
        ),
      ],
      fromDate: DateTime(2025, 1, 1),
      toDate: DateTime(2025, 12, 31),
    );

    final fromExport = BkmvSimulator.validateExport(export);
    expect(fromExport.ok, isTrue, reason: fromExport.errors.join('; '));
    expect(fromExport.errors, isEmpty);

    final fromZip = BkmvSimulator.validateZip(export.zipBytes);
    expect(fromZip.ok, isTrue, reason: fromZip.errors.join('; '));
    expect(fromZip.recordCounts['C100'], 4);
    expect(fromZip.recordCounts['D120'], greaterThanOrEqualTo(2));
  });

  test('simulator rejects tampered record length', () {
    final export = BkmvExporter(
      company: const BkmvCompanyContext(
        vatId: '514123456',
        businessName: 'Test Co',
      ),
    ).build(
      invoices: [_inv(seq: 1, type: InvoiceDocumentType.invoice)],
      fromDate: DateTime(2025, 1, 1),
      toDate: DateTime(2025, 12, 31),
    );
    final broken = export.bkmvText.replaceFirst('C100', 'C100X');
    final result = BkmvSimulator.validateExport(
      BkmvExportResult(
        zipBytes: export.zipBytes,
        iniText: export.iniText,
        bkmvText: broken,
        primaryId: export.primaryId,
        recordCounts: export.recordCounts,
        documentCount: export.documentCount,
      ),
    );
    expect(result.ok, isFalse);
    expect(result.errors.any((e) => e.contains('C100')), isTrue);
  });
}
