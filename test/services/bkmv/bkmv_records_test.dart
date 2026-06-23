import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/models/invoice.dart';
import 'package:logiroute/models/invoice_payment_line.dart';
import 'package:logiroute/services/bkmv/bkmv_codec.dart';
import 'package:logiroute/services/bkmv/bkmv_records.dart';

Invoice _sampleInvoice() {
  final now = DateTime(2025, 3, 15, 10, 30);
  return Invoice(
    id: 'inv1',
    companyId: 'c1',
    sequentialNumber: 260,
    clientName: 'Test Client',
    clientNumber: '514123456',
    address: 'Herzl 1 Tel Aviv',
    driverName: '',
    truckNumber: '',
    deliveryDate: now,
    departureTime: now,
    items: [
      InvoiceItem(
        productCode: 'A',
        type: 'box',
        number: '1',
        quantity: 2,
        piecesPerBox: 1,
        pricePerUnit: 100,
        description: 'Item A',
        vatRate: 0.18,
      ),
    ],
    createdAt: now,
    createdBy: 'user1',
    documentType: InvoiceDocumentType.invoice,
    status: InvoiceStatus.issued,
  );
}

void main() {
  test('amount15 encodes agorot with sign', () {
    expect(BkmvCodec.amount15(1245.65), '+00000000124565');
    expect(BkmvCodec.amount15(-10), '-00000000001000');
  });

  test('record lengths match horaot 1.31', () {
    const vat = '514123456';
    const primary = '123456789012345';
    final inv = _sampleInvoice();

    expect(
      BkmvRecords.encodeA100(
              recordNumber: 1, vatId: vat, primaryId: primary)
          .length,
      BkmvRecords.lenA100,
    );
    expect(
      BkmvRecords.encodeZ900(
        recordNumber: 5,
        vatId: vat,
        primaryId: primary,
        totalRecordsInFile: 5,
      ).length,
      BkmvRecords.lenZ900,
    );
    expect(
      BkmvRecords.encodeC100(
        recordNumber: 2,
        vatId: vat,
        invoice: inv,
        linkId: 1,
      ).length,
      BkmvRecords.lenC100,
    );
    expect(
      BkmvRecords.encodeD110(
        recordNumber: 3,
        vatId: vat,
        invoice: inv,
        item: inv.items.first,
        lineIndex: 1,
        linkId: 1,
      ).length,
      BkmvRecords.lenD110,
    );
    final receipt = inv.copyWith(
      documentType: InvoiceDocumentType.taxInvoiceReceipt,
      paymentMethod: 'cash',
    );
    expect(
      BkmvRecords.encodeD120(
        recordNumber: 4,
        vatId: vat,
        invoice: receipt,
        paymentLineIndex: 1,
        linkId: 1,
        payment: const InvoicePaymentLine(method: 'cash', amount: 236),
      ).length,
      BkmvRecords.lenD120,
    );
    expect(BkmvRecords.paymentMeansCode('cash'), 1);
    expect(BkmvRecords.paymentMeansCode('מזומן'), 1);
    expect(BkmvRecords.paymentMeansCode('credit_card'), 3);
    expect(
      BkmvRecords.encodeA000(
        vatId: vat,
        primaryId: primary,
        totalBkmvRecords: 5,
        company: const BkmvCompanyContext(
          vatId: vat,
          businessName: 'LogiRoute Ltd',
        ),
        software: const BkmvSoftwareInfo(),
        fromDate: DateTime(2025, 1, 1),
        toDate: DateTime(2025, 12, 31),
        processStart: DateTime(2025, 6, 1, 9, 0),
      ).length,
      BkmvRecords.lenA000,
    );
  });

  test('D120 cheque fills bank fields 1307-1310', () {
    final inv = _sampleInvoice().copyWith(
      documentType: InvoiceDocumentType.receipt,
      paymentLines: [
        InvoicePaymentLine(
          method: 'cheque',
          amount: 118,
          bankNumber: '12',
          branchNumber: '345',
          accountNumber: '6789012',
          chequeNumber: '998877',
          dueDate: DateTime(2025, 4, 1),
        ),
      ],
    );
    final line = BkmvRecords.encodeD120(
      recordNumber: 1,
      vatId: '514123456',
      invoice: inv,
      paymentLineIndex: 1,
      linkId: 1,
      payment: inv.paymentLines.first,
    );
    expect(line.length, BkmvRecords.lenD120);
    expect(line.substring(49, 50), '2'); // means המחאה
    expect(line.substring(50, 60), '0000000012'); // bank
    expect(line.substring(60, 70), '0000000345'); // branch
    expect(line.substring(70, 85), '000000006789012'); // account
    expect(line.substring(85, 95), '0000998877'); // cheque
  });

  test('D120 credit card fills clearing and deal type', () {
    final pay = InvoicePaymentLine(
      method: 'credit_card',
      amount: 500,
      dueDate: DateTime(2025, 3, 15),
      clearingHouseCode: 2,
      cardName: 'Visa Cal',
      creditDealType: 2,
    );
    final inv = _sampleInvoice().copyWith(
      documentType: InvoiceDocumentType.taxInvoiceReceipt,
      paymentLines: [pay],
    );
    final line = BkmvRecords.encodeD120(
      recordNumber: 1,
      vatId: '514123456',
      invoice: inv,
      paymentLineIndex: 1,
      linkId: 1,
      payment: pay,
    );
    expect(line.substring(49, 50), '3');
    expect(line.substring(118, 119), '2'); // clearing כאל
    expect(line.contains('Visa Cal'), isTrue);
    expect(line.substring(139, 140), '2'); // תשלומים
  });

  test('C100 starts with code and doc type 305', () {
    final line = BkmvRecords.encodeC100(
      recordNumber: 2,
      vatId: '514123456',
      invoice: _sampleInvoice(),
      linkId: 42,
    );
    expect(line.substring(0, 4), 'C100');
    expect(line.substring(22, 25), '305');
  });
}
