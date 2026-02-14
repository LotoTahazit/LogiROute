import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicePrintService {
  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Печать חשבונית
  static Future<void> printInvoice(
    Invoice invoice, {
    InvoiceCopyType? copyType,
  }) async {
    // Определяем тип копии
    InvoiceCopyType actualCopyType;
    if (copyType != null) {
      actualCopyType = copyType;
    } else if (!invoice.originalPrinted) {
      actualCopyType = InvoiceCopyType.original;
    } else {
      actualCopyType = InvoiceCopyType.copy;
    }

    // Подключаем шрифты
    final fontHebrewData = await rootBundle.load(
      'assets/fonts/NotoSansHebrew-Regular.ttf',
    );
    final fontHebrewBoldData = await rootBundle.load(
      'assets/fonts/NotoSansHebrew-Bold.ttf',
    );
    final fontLatinData = await rootBundle.load('assets/fonts/Arial.ttf');

    final fontHebrew = pw.Font.ttf(fontHebrewData);
    final fontHebrewBold = pw.Font.ttf(fontHebrewBoldData);
    final fontLatin = pw.Font.ttf(fontLatinData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(
              invoice,
              fontHebrew,
              fontHebrewBold,
              fontLatin,
              actualCopyType,
            ),
            pw.SizedBox(height: 30),
            _buildClientInfo(invoice, fontHebrew, fontHebrewBold, fontLatin),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, fontHebrew, fontHebrewBold, fontLatin),
            pw.SizedBox(height: 20),
            _buildTotals(invoice, fontHebrew, fontHebrewBold, fontLatin),
            pw.Spacer(),
            _buildSignature(fontHebrew, fontHebrewBold, fontLatin),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    // Обновляем счетчики в Firestore только если ID не пустой
    if (invoice.id.isNotEmpty) {
      await _updatePrintCounters(invoice.id, actualCopyType);
    } else {
      print(
          '⚠️ [InvoicePrint] Cannot update print counters: invoice ID is empty');
    }
  }

  /// Обновление счетчиков печати
  static Future<void> _updatePrintCounters(
    String invoiceId,
    InvoiceCopyType copyType,
  ) async {
    final docRef =
        FirebaseFirestore.instance.collection('invoices').doc(invoiceId);

    if (copyType == InvoiceCopyType.original ||
        copyType == InvoiceCopyType.replacesOriginal) {
      await docRef.update({'originalPrinted': true});
    } else {
      await docRef.update({
        'copiesPrinted': FieldValue.increment(1),
      });
    }
  }

  /// Заголовок
  static pw.Widget _buildHeader(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
    InvoiceCopyType copyType,
  ) {
    // Определяем текст типа копии
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

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Y.C PLAST',
                style: pw.TextStyle(
                  font: fontLatin,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'י.כ פלסט בע"מ',
                style: pw.TextStyle(
                  font: fontHebrewBold,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  pw.Text(
                    'חשבונית',
                    style: pw.TextStyle(
                      font: fontHebrewBold,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '($copyTypeText)',
                    style: pw.TextStyle(
                      font: fontHebrewBold,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: copyType == InvoiceCopyType.replacesOriginal
                          ? PdfColors.red
                          : PdfColors.black,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'שירות לקוחות',
                style: pw.TextStyle(font: fontHebrew, fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  '04-6288547',
                  style: pw.TextStyle(
                    font: fontLatin,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                'תאריך:',
                style: pw.TextStyle(font: fontHebrew, fontSize: 12),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  _formatDate(invoice.createdAt),
                  style: pw.TextStyle(font: fontLatin, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Информация о клиенте и доставке
  static pw.Widget _buildClientInfo(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'לקוח:',
            invoice.clientName,
            fontHebrew,
            fontHebrewBold,
            fontLatin,
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'מספר לקוח:',
            invoice.clientNumber,
            fontHebrew,
            fontHebrewBold,
            fontLatin,
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'כתובת:',
            invoice.address,
            fontHebrew,
            fontHebrewBold,
            fontLatin,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          _buildInfoRow(
            'נהג:',
            invoice.driverName,
            fontHebrew,
            fontHebrewBold,
            fontLatin,
          ),
          pw.SizedBox(height: 5),
          _buildInfoRow(
            'משאית:',
            invoice.truckNumber,
            fontHebrew,
            fontHebrewBold,
            fontLatin,
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(
                'תאריך אספקה: ',
                style: pw.TextStyle(
                  font: fontHebrewBold,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  _formatDate(invoice.deliveryDate),
                  style: pw.TextStyle(font: fontLatin, fontSize: 12),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(
                'שעת יציאה: ',
                style: pw.TextStyle(
                  font: fontHebrewBold,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  _formatTime(invoice.departureTime),
                  style: pw.TextStyle(font: fontLatin, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Row(
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            font: fontHebrewBold,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontHebrew,
            fontFallback: [fontLatin],
            fontSize: 12,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  /// Таблица товаров
  static pw.Widget _buildItemsTable(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Заголовок
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('פריט', fontHebrewBold),
            _buildTableHeader('קרטונים', fontHebrewBold),
            _buildTableHeader('מחיר ליח\'', fontHebrewBold),
            _buildTableHeader('סה"כ', fontHebrewBold),
          ],
        ),
        // Строки товаров
        ...invoice.items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(
                '${item.type} ${item.number}',
                fontHebrew,
                fontLatin,
              ),
              _buildTableCell(
                '${item.quantity}',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                '₪${item.pricePerUnit.toStringAsFixed(2)}',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.centerRight,
              ),
              _buildTableCell(
                '₪${item.totalBeforeVAT.toStringAsFixed(2)}',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.centerRight,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font mainFont,
    pw.Font fallbackFont, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: mainFont,
          fontFallback: [fallbackFont],
          fontSize: 11,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  /// Итоги
  static pw.Widget _buildTotals(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        children: [
          // Скидка (только если есть)
          if (invoice.discount > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'הנחה ${invoice.discount.toStringAsFixed(0)}%:',
                  style: pw.TextStyle(font: fontHebrew, fontSize: 14),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.Text(
                  '-₪${invoice.discountAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: fontLatin, fontSize: 14),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
          // Сумма до НДС
          _buildTotalRow(
            'סה"כ לפני מע"מ:',
            '₪${invoice.subtotalBeforeVAT.toStringAsFixed(2)}',
            fontHebrew,
            fontLatin,
          ),
          pw.SizedBox(height: 8),
          // НДС
          _buildTotalRow(
            'מע"מ (18%):',
            '₪${invoice.vatAmount.toStringAsFixed(2)}',
            fontHebrew,
            fontLatin,
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 8),
          // Итого
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'סה"כ לתשלום:',
                style: pw.TextStyle(
                  font: fontHebrewBold,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                '₪${invoice.totalWithVAT.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  font: fontLatin,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value,
    pw.Font fontHebrew,
    pw.Font fontLatin,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontHebrew, fontSize: 14),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(value, style: pw.TextStyle(font: fontLatin, fontSize: 14)),
      ],
    );
  }

  /// Подпись
  static pw.Widget _buildSignature(
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'חתימת הלקוח:',
            style: pw.TextStyle(
              font: fontHebrewBold,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 30),
          pw.Container(height: 1, width: 200, color: PdfColors.black),
          pw.SizedBox(height: 5),
          pw.Text(
            'תאריך: _______________',
            style: pw.TextStyle(font: fontHebrew, fontSize: 10),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
