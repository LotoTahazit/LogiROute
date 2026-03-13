import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../models/company_settings.dart';
import 'invoice_pdf_helpers.dart';

/// All PDF layout builders for invoice printing.
/// Extracted from InvoicePrintService to reduce file size.

/// Builds a complete invoice page
pw.Page buildInvoicePage(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
  InvoiceCopyType copyType,
  CompanySettings companySettings,
) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(20),
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildHeader(invoice, fontHebrew, fontHebrewBold, fontLatin, copyType,
            companySettings),
        pw.SizedBox(height: 5),
        buildInvoiceTitle(
            invoice, fontHebrew, fontHebrewBold, fontLatin, copyType),
        pw.SizedBox(height: 5),
        buildClientInfo(invoice, fontHebrew, fontHebrewBold, fontLatin),
        pw.SizedBox(height: 7),
        if (invoice.documentType == InvoiceDocumentType.delivery)
          buildDeliveryItemsTable(
              invoice, fontHebrew, fontHebrewBold, fontLatin)
        else
          buildItemsTable(invoice, fontHebrew, fontHebrewBold, fontLatin),
        pw.SizedBox(height: 7),
        if (invoice.documentType != InvoiceDocumentType.delivery)
          buildTotals(invoice, fontHebrew, fontHebrewBold, fontLatin),
        pw.Spacer(),
        buildFooter(
            invoice, fontHebrew, fontHebrewBold, fontLatin, companySettings),
      ],
    ),
  );
}

/// Header — company info on both sides
pw.Widget buildHeader(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
  InvoiceCopyType copyType,
  CompanySettings settings,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Left — English name + tax ID
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            settings.nameEnglish,
            style: pw.TextStyle(
              font: fontLatin,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'P.O.B ${settings.poBox}',
            style: pw.TextStyle(font: fontLatin, fontSize: 7),
          ),
          pw.Text(
            settings.addressEnglish,
            style: pw.TextStyle(font: fontLatin, fontSize: 7),
          ),
          pw.Text(
            'TEL. ${settings.phone}  FAX. ${settings.fax}',
            style: pw.TextStyle(font: fontLatin, fontSize: 7),
          ),
          pw.SizedBox(height: 1),
          smartText(
            'אתר  ${settings.website}',
            fontHebrew,
            fontLatin,
            fontSize: 7,
          ),
          smartText(
            'ח.פ  ${settings.taxId}',
            fontHebrew,
            fontLatin,
            fontSize: 7,
            bold: true,
          ),
        ],
      ),
      pw.SizedBox(width: 60),
      // Right — Hebrew name
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          smartText(
            settings.nameHebrew,
            fontHebrewBold,
            fontLatin,
            fontSize: 11,
            bold: true,
          ),
          pw.SizedBox(height: 2),
          smartText(
            'ת.ד. ${settings.poBox}',
            fontHebrew,
            fontLatin,
            fontSize: 7,
          ),
          smartText(
            settings.addressHebrew,
            fontHebrew,
            fontLatin,
            fontSize: 7,
          ),
          smartText(
            'טל: ${settings.phone} פקס: ${settings.fax}',
            fontHebrew,
            fontLatin,
            fontSize: 7,
          ),
        ],
      ),
    ],
  );
}

/// Invoice title with copy type, date, document type
pw.Widget buildInvoiceTitle(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
  InvoiceCopyType copyType,
) {
  String copyTypeText;
  switch (copyType) {
    case InvoiceCopyType.original:
      copyTypeText = 'מקור';
      break;
    case InvoiceCopyType.copy:
      copyTypeText = 'עותק';
      break;
    case InvoiceCopyType.replacesOriginal:
      copyTypeText = 'נעימן למקור';
      break;
  }

  String documentTitle;
  switch (invoice.documentType) {
    case InvoiceDocumentType.invoice:
      documentTitle = 'חשבונית מס';
      break;
    case InvoiceDocumentType.receipt:
      documentTitle = 'קבלה';
      break;
    case InvoiceDocumentType.delivery:
      documentTitle = 'תעודת משלוח';
      break;
    case InvoiceDocumentType.creditNote:
      documentTitle = 'זיכוי';
      break;
    case InvoiceDocumentType.taxInvoiceReceipt:
      documentTitle = 'חשבונית מס / קבלה';
      break;
  }

  final bool isReprint =
      invoice.originalPrinted && copyType != InvoiceCopyType.original;
  final reprintNow = DateTime.now();
  final reprintStr = isReprint
      ? 'הדפסה חוזרת ${reprintNow.day.toString().padLeft(2, '0')}/${reprintNow.month.toString().padLeft(2, '0')}/${reprintNow.year} ${reprintNow.hour.toString().padLeft(2, '0')}:${reprintNow.minute.toString().padLeft(2, '0')}'
      : '';

  final dateStr =
      '${invoice.createdAt.day.toString().padLeft(2, '0')}/${invoice.createdAt.month.toString().padLeft(2, '0')}/${invoice.createdAt.year}';
  final timeStr =
      '${invoice.createdAt.hour.toString().padLeft(2, '0')}:${invoice.createdAt.minute.toString().padLeft(2, '0')}:${invoice.createdAt.second.toString().padLeft(2, '0')}';

  return pw.Column(
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                smartText(
                  copyTypeText,
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 9,
                  bold: true,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                smartText('תאריך', fontHebrew, fontLatin, fontSize: 7),
                pw.Text(dateStr,
                    style: pw.TextStyle(font: fontLatin, fontSize: 7)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                smartText('שעה', fontHebrew, fontLatin, fontSize: 7),
                pw.Text(timeStr,
                    style: pw.TextStyle(font: fontLatin, fontSize: 7)),
              ],
            ),
          ],
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Column(
          children: [
            if (invoice.status == InvoiceStatus.draft)
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const pw.EdgeInsets.only(bottom: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red, width: 1),
                ),
                child: smartText(
                    'טיוטה — לא לשימוש רשמי', fontHebrewBold, fontLatin,
                    fontSize: 9, bold: true, color: PdfColors.red),
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  invoice.sequentialNumber.toString(),
                  style: pw.TextStyle(
                      font: fontLatin,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 3),
                smartText(documentTitle, fontHebrewBold, fontLatin,
                    fontSize: 12, bold: true),
              ],
            ),
            if (isReprint)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: smartText(reprintStr, fontHebrew, fontLatin,
                    fontSize: 7, color: PdfColors.grey700),
              ),
          ],
        ),
      ),
      if (invoice.documentType != InvoiceDocumentType.delivery)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                '${(invoice.paymentDueDate ?? invoice.deliveryDate).day.toString().padLeft(2, '0')}/${(invoice.paymentDueDate ?? invoice.deliveryDate).month.toString().padLeft(2, '0')}/${(invoice.paymentDueDate ?? invoice.deliveryDate).year}',
                style: pw.TextStyle(font: fontLatin, fontSize: 8),
              ),
              pw.SizedBox(width: 5),
              smartText('תשלום עד', fontHebrewBold, fontLatin,
                  fontSize: 8, bold: true),
            ],
          ),
        ),
    ],
  );
}

/// Client info section
pw.Widget buildClientInfo(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.5),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              invoice.clientNumber,
              style: pw.TextStyle(
                  font: fontLatin, fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            smartText(extractCity(invoice.address), fontHebrewBold, fontLatin,
                fontSize: 8, bold: true),
          ],
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              smartText('לקוח', fontHebrewBold, fontLatin,
                  fontSize: 8, bold: true),
              pw.SizedBox(height: 2),
              smartText(invoice.clientName, fontHebrewBold, fontLatin,
                  fontSize: 8, bold: true),
              pw.SizedBox(height: 2),
              smartText('ת.ד', fontHebrew, fontLatin, fontSize: 7),
              pw.SizedBox(height: 2),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: smartText(
                    'טלפון:              פקס:', fontHebrew, fontLatin,
                    fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Table header cell helper
pw.Widget buildTableHeader(
    String text, pw.Font mainFont, pw.Font fallbackFont) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(4),
    alignment: pw.Alignment.center,
    child: smartText(
      text,
      mainFont,
      fallbackFont,
      fontSize: 9,
      bold: true,
    ),
  );
}

/// Table data cell helper
pw.Widget buildTableCell(
  String text,
  pw.Font mainFont,
  pw.Font fallbackFont, {
  pw.Alignment align = pw.Alignment.center,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    alignment: align,
    child: smartText(text, mainFont, fallbackFont, fontSize: 9),
  );
}

/// Items table for invoices
pw.Widget buildItemsTable(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 1),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.5),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(1.5),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(1.5),
      5: const pw.FlexColumnWidth(1.5),
      6: const pw.FlexColumnWidth(3),
      7: const pw.FlexColumnWidth(1.5),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          buildTableHeader('מחיר', fontHebrewBold, fontLatin),
          buildTableHeader('% הנחה', fontHebrewBold, fontLatin),
          buildTableHeader('לקרטון', fontHebrewBold, fontLatin),
          buildTableHeader('סה״כ\nיחידות', fontHebrewBold, fontLatin),
          buildTableHeader('כמות\nבקרטון', fontHebrewBold, fontLatin),
          buildTableHeader('כמות\nקרטונים', fontHebrewBold, fontLatin),
          buildTableHeader('תאור פריט', fontHebrewBold, fontLatin),
          buildTableHeader('מס\' פריט', fontHebrewBold, fontLatin),
        ],
      ),
      ...invoice.items.map((item) {
        return pw.TableRow(
          children: [
            buildTableCell(
              item.totalBeforeVAT.toStringAsFixed(2),
              fontLatin,
              fontHebrew,
              align: pw.Alignment.centerRight,
            ),
            buildTableCell(
              '${invoice.discount.toStringAsFixed(0)}%',
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
            buildTableCell(
              item.pricePerUnit.toStringAsFixed(2),
              fontLatin,
              fontHebrew,
              align: pw.Alignment.centerRight,
            ),
            buildTableCell(
              '${item.quantity}',
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
            buildTableCell(
              '1500',
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
            buildTableCell(
              '30.00',
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
            buildTableCell(
              '${item.type} ${item.number}',
              fontHebrew,
              fontLatin,
              align: pw.Alignment.centerRight,
            ),
            buildTableCell(
              item.productCode,
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
          ],
        );
      }),
    ],
  );
}

/// Delivery items table (no prices)
pw.Widget buildDeliveryItemsTable(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 1),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.5),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(1.5),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          buildTableHeader('כמות', fontHebrewBold, fontLatin),
          buildTableHeader('תאור פריט', fontHebrewBold, fontLatin),
          buildTableHeader('מס\' פריט', fontHebrewBold, fontLatin),
        ],
      ),
      ...invoice.items.map((item) {
        return pw.TableRow(
          children: [
            buildTableCell(
              '${item.quantity}',
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
            buildTableCell(
              '${item.type} ${item.number}',
              fontHebrew,
              fontLatin,
              align: pw.Alignment.center,
            ),
            buildTableCell(
              item.productCode,
              fontLatin,
              fontHebrew,
              align: pw.Alignment.center,
            ),
          ],
        );
      }),
    ],
  );
}

/// Totals section
pw.Widget buildTotals(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  invoice.subtotalBeforeVAT.toStringAsFixed(2),
                  style: pw.TextStyle(font: fontLatin, fontSize: 8),
                ),
                smartText('סה״כ', fontHebrew, fontLatin, fontSize: 8),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '0.00',
                  style: pw.TextStyle(font: fontLatin, fontSize: 8),
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      '0.0%',
                      style: pw.TextStyle(font: fontLatin, fontSize: 8),
                    ),
                    pw.SizedBox(width: 2),
                    smartText('הנחה', fontHebrew, fontLatin, fontSize: 8),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '0.00',
                  style: pw.TextStyle(font: fontLatin, fontSize: 8),
                ),
                smartText(
                  'חיוב/זיכוי/תוספות',
                  fontHebrew,
                  fontLatin,
                  fontSize: 7,
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  invoice.subtotalBeforeVAT.toStringAsFixed(2),
                  style: pw.TextStyle(font: fontLatin, fontSize: 8),
                ),
                smartText(
                  'סה״כ לפני מע״מ',
                  fontHebrew,
                  fontLatin,
                  fontSize: 8,
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  invoice.vatAmount.toStringAsFixed(2),
                  style: pw.TextStyle(font: fontLatin, fontSize: 8),
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      '18%',
                      style: pw.TextStyle(font: fontLatin, fontSize: 8),
                    ),
                    pw.SizedBox(width: 2),
                    smartText('מע״מ', fontHebrew, fontLatin, fontSize: 8),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Divider(color: PdfColors.black, thickness: 1),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  invoice.totalWithVAT.toStringAsFixed(2),
                  style: pw.TextStyle(
                    font: fontLatin,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                smartText(
                  'סה״כ לתשלום',
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 9,
                  bold: true,
                ),
              ],
            ),
            if ((invoice.documentType ==
                        InvoiceDocumentType.taxInvoiceReceipt ||
                    invoice.documentType == InvoiceDocumentType.receipt) &&
                invoice.paymentMethod != null) ...[
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  smartText(
                    invoice.paymentMethod!,
                    fontHebrew,
                    fontLatin,
                    fontSize: 8,
                  ),
                  smartText(
                    'אופן תשלום',
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 8,
                    bold: true,
                  ),
                ],
              ),
            ],
            if (invoice.documentType == InvoiceDocumentType.receipt &&
                invoice.linkedInvoiceId != null) ...[
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  smartText(
                    'עבור חשבונית מס',
                    fontHebrew,
                    fontLatin,
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(width: 200),
    ],
  );
}

/// Footer with signature, payment terms, driver info
pw.Widget buildFooter(
  Invoice invoice,
  pw.Font fontHebrew,
  pw.Font fontHebrewBold,
  pw.Font fontLatin,
  CompanySettings settings,
) {
  final footerLines = settings.invoiceFooterText.split('\n');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 220,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 40),
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                smartText(
                  'חתימה',
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 12,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 7),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: footerLines.map((line) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: smartText(
                line,
                line == footerLines.first ? fontHebrewBold : fontHebrew,
                fontLatin,
                fontSize: 7,
                bold: line == footerLines.first,
              ),
            );
          }).toList(),
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.black, width: 1),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                smartText(
                  invoice.driverName,
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 8,
                  bold: true,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                smartText(
                  'מס\' רכב:',
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 8,
                  bold: true,
                ),
                pw.SizedBox(height: 2),
                smartText(
                  invoice.truckNumber,
                  fontLatin,
                  fontHebrew,
                  fontSize: 8,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                smartText(
                  'שעת יציאה :',
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 8,
                  bold: true,
                ),
                pw.SizedBox(height: 2),
                smartText(
                  '07:00',
                  fontLatin,
                  fontHebrew,
                  fontSize: 8,
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 7),
      pw.Container(
        width: double.infinity,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            smartText(
              'תודה על הקנייה!',
              fontHebrewBold,
              fontLatin,
              fontSize: 7,
              bold: true,
            ),
            pw.SizedBox(height: 2),
            smartText(
              'נשמח לשרת אתכם שוב',
              fontHebrew,
              fontLatin,
              fontSize: 7,
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(top: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ID: ${invoice.id.length > 8 ? invoice.id.substring(0, 8) : invoice.id}',
              style: pw.TextStyle(
                  font: fontLatin, fontSize: 9, color: PdfColors.grey600),
            ),
            smartText(
              'הופק: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              fontHebrew,
              fontLatin,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ],
        ),
      ),
    ],
  );
}
