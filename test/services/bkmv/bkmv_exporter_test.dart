import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/invoice.dart';
import 'package:logiroute/models/invoice_payment_line.dart';
import 'package:logiroute/services/bkmv/bkmv_exporter.dart';
import 'package:logiroute/services/bkmv/bkmv_records.dart';

Invoice _inv(int n) {
  final d = DateTime(2025, 6, n.clamp(1, 28));
  return Invoice(
    id: 'id$n',
    companyId: 'c1',
    sequentialNumber: 100 + n,
    clientName: 'Client $n',
    clientNumber: '111222333',
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
        pricePerUnit: 50,
        description: 'Line',
        vatRate: 0.18,
      ),
    ],
    createdAt: d,
    createdBy: 'u1',
    documentType: InvoiceDocumentType.invoice,
    status: InvoiceStatus.issued,
  );
}

void main() {
  test('exporter builds zip with expected record counts', () {
    final result = BkmvExporter(
      company: const BkmvCompanyContext(
        vatId: '514123456',
        businessName: 'Test Co',
      ),
    ).build(
      invoices: [_inv(1), _inv(2)],
      fromDate: DateTime(2025, 1, 1),
      toDate: DateTime(2025, 12, 31),
    );

    expect(result.documentCount, 2);
    expect(result.recordCounts['C100'], 2);
    expect(result.recordCounts['D110'], 2);
    expect(result.zipBytes.length, greaterThan(100));
    expect(result.bkmvText, contains('A100'));
    expect(result.bkmvText, contains('C100'));
    expect(result.bkmvText, contains('Z900'));
    expect(result.iniText, contains('A000'));
  });

  test('exporter keeps cancelled issued docs (no gap) but drops drafts', () {
    final cancelled = _inv(4).copyWith(status: InvoiceStatus.cancelled);
    final draft = _inv(5).copyWith(status: InvoiceStatus.draft);
    final result = BkmvExporter(
      company: const BkmvCompanyContext(
        vatId: '514123456',
        businessName: 'Test Co',
      ),
    ).build(
      invoices: [_inv(1), cancelled, draft],
      fromDate: DateTime(2025, 1, 1),
      toDate: DateTime(2025, 12, 31),
    );

    // Выписанный + отменённый остаются (полный רצף), черновик исключён.
    expect(result.documentCount, 2);
    expect(result.recordCounts['C100'], 2);
  });

  test('exporter includes D120 for tax invoice receipt', () {
    final receipt = _inv(3).copyWith(
      documentType: InvoiceDocumentType.taxInvoiceReceipt,
      paymentMethod: 'cash',
    );
    final result = BkmvExporter(
      company: const BkmvCompanyContext(
        vatId: '514123456',
        businessName: 'Test Co',
      ),
    ).build(
      invoices: [receipt],
      fromDate: DateTime(2025, 1, 1),
      toDate: DateTime(2025, 12, 31),
    );

    expect(result.recordCounts['D120'], 1);
    expect(result.bkmvText, contains('D120'));
  });

  test('exporter emits 3 D120 for credit installments', () {
    final due = DateTime(2025, 6, 3);
    final receipt = _inv(3).copyWith(
      documentType: InvoiceDocumentType.taxInvoiceReceipt,
      paymentMethod: 'credit_card 3 תשלומים',
      paymentLines: InvoicePaymentLine.equalInstallments(
        method: 'credit_card',
        total: 59,
        count: 3,
        firstDue: due,
        clearingHouseCode: 1,
        cardName: 'Isracard',
      ),
    );
    final result = BkmvExporter(
      company: const BkmvCompanyContext(
        vatId: '514123456',
        businessName: 'Test Co',
      ),
    ).build(
      invoices: [receipt],
      fromDate: DateTime(2025, 1, 1),
      toDate: DateTime(2025, 12, 31),
    );

    expect(result.recordCounts['D120'], 3);
  });
}
