import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/delivery_point.dart';
import '../models/user_model.dart';

class PrintService {
  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String _formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Определяет направление текста
  static pw.TextDirection _getTextDirection(String text) {
    final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(text);
    return hasHebrew ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  }

  /// Умный текст, корректно отображающий цифры и английский внутри иврита
  static pw.Widget _smartText(
    String text,
    pw.Font mainFont,
    pw.Font latinFont, {
    double fontSize = 12,
    bool bold = false,
    PdfColor color = PdfColors.black,
  }) {
    final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(text);
    final hasLatinOrDigits = RegExp(r'[A-Za-z0-9]').hasMatch(text);

    if (hasHebrew && hasLatinOrDigits) {
      final spans = <pw.InlineSpan>[];
      final buffer = StringBuffer();
      bool currentIsHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(text[0]);

      void flush() {
        if (buffer.isEmpty) return;
        spans.add(pw.TextSpan(
          text: buffer.toString(),
          style: pw.TextStyle(
            font: currentIsHebrew ? mainFont : latinFont,
            fontFallback: [mainFont, latinFont],
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ));
        buffer.clear();
      }

      for (final rune in text.runes) {
        final ch = String.fromCharCode(rune);
        final isHeb = RegExp(r'[\u0590-\u05FF]').hasMatch(ch);
        if (isHeb != currentIsHebrew) {
          flush();
          currentIsHebrew = isHeb;
        }
        buffer.write(ch);
      }
      flush();

      return pw.RichText(
        text: pw.TextSpan(children: spans),
        textDirection: pw.TextDirection.rtl,
      );
    }

    return pw.Text(
      text,
      style: pw.TextStyle(
        font: mainFont,
        fontFallback: [latinFont],
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
      textDirection: _getTextDirection(text),
    );
  }

  static Future<void> printRoute({
    required UserModel driver,
    required List<DeliveryPoint> points,
  }) async {
    if (points.isEmpty) return;

    final sortedPoints = List<DeliveryPoint>.from(points)
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

    // Подключаем шрифты
    final fontHebrewData =
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf');
    final fontHebrewBoldData =
        await rootBundle.load('assets/fonts/NotoSansHebrew-Bold.ttf');
    final fontLatinData = await rootBundle.load('assets/fonts/Arial.ttf');

    final fontHebrew = pw.Font.ttf(fontHebrewData);
    final fontHebrewBold = pw.Font.ttf(fontHebrewBoldData);
    final fontLatin = pw.Font.ttf(fontLatinData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader(driver, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 20),
          _buildRouteTable(sortedPoints, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 20),
          _buildSummary(sortedPoints, fontHebrew, fontHebrewBold, fontLatin),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Route_${driver.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Заголовок
  static pw.Widget _buildHeader(
    UserModel driver,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _smartText(
            'מסלול משלוח',
            fontHebrewBold,
            fontLatin,
            fontSize: 24,
            bold: true,
          ),
          pw.SizedBox(height: 8),
          _smartText(
            'LogiRoute - Logistics Management System',
            fontLatin,
            fontHebrew,
            fontSize: 16,
            color: PdfColors.grey600,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _smartText(
                    'נהג: ${driver.name}',
                    fontHebrewBold,
                    fontLatin,
                  ),
                  _smartText(
                    'קיבולת משאית: ${driver.palletCapacity ?? 0} משטחים',
                    fontHebrew,
                    fontLatin,
                    fontSize: 12,
                  ),
                ],
              ),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  _smartText(
                    'תאריך: ',
                    fontHebrew,
                    fontLatin,
                    fontSize: 12,
                  ),
                  pw.SizedBox(
                      width: 5), // Добавляем отступ между текстом и датой
                  pw.Directionality(
                    textDirection: pw.TextDirection.ltr,
                    child: pw.Text(
                      _formatDate(DateTime.now().toLocal()),
                      style: pw.TextStyle(
                        font: fontLatin,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Таблица маршрута
  static pw.Widget _buildRouteTable(
    List<DeliveryPoint> points,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('מס\'', fontHebrewBold, fontLatin, isHeader: true),
            _buildTableCell('שם לקוח', fontHebrewBold, fontLatin,
                isHeader: true),
            _buildTableCell('כתובת', fontHebrewBold, fontLatin, isHeader: true),
            _buildTableCell('משטחים', fontHebrewBold, fontLatin,
                isHeader: true),
            _buildTableCell('קרטונים', fontHebrewBold, fontLatin,
                isHeader: true),
            _buildTableCell('קופסאות', fontHebrewBold, fontLatin,
                isHeader: true),
            _buildTableCell('סטטוס', fontHebrewBold, fontLatin, isHeader: true),
          ],
        ),
        ...points.map((p) {
          // Форматируем типы коробок для отображения
          final boxTypesText = p.boxTypes != null && p.boxTypes!.isNotEmpty
              ? p.boxTypes!.map((box) => box.toShortString()).join('\n')
              : '-';

          return pw.TableRow(
            children: [
              _buildTableCell('${p.orderInRoute}', fontHebrew, fontLatin),
              _buildTableCell(p.clientName, fontHebrew, fontLatin),
              _buildTableCell(p.address, fontHebrew, fontLatin),
              _buildTableCell('${p.pallets}', fontHebrew, fontLatin),
              _buildTableCell('${p.boxes}', fontHebrew, fontLatin),
              _buildTableCell(boxTypesText, fontHebrew, fontLatin),
              _buildTableCell(
                  _getStatusInHebrew(p.status), fontHebrew, fontLatin),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font mainFont,
    pw.Font latinFont, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: _smartText(
        text,
        mainFont,
        latinFont,
        fontSize: isHeader ? 12 : 10,
        bold: isHeader,
      ),
    );
  }

  /// Сводка
  static pw.Widget _buildSummary(
    List<DeliveryPoint> points,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    final totalPallets = points.fold(0, (sum, p) => sum + p.pallets);
    final totalBoxes = points.fold(0, (sum, p) => sum + p.boxes);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _smartText('סיכום', fontHebrewBold, fontLatin,
              fontSize: 16, bold: true),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _smartText('סך הכל משטחים: $totalPallets', fontHebrew, fontLatin),
              _smartText('סך הכל קרטונים: $totalBoxes', fontHebrew, fontLatin),
            ],
          ),
          pw.SizedBox(height: 5),
          _smartText('מספר נקודות: ${points.length}', fontHebrew, fontLatin),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _smartText(
                'נוצר ב־LogiRoute - ',
                fontHebrew,
                fontLatin,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              pw.SizedBox(width: 5), // Добавляем отступ между текстом и датой
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text(
                  _formatDateTime(DateTime.now().toLocal()),
                  style: pw.TextStyle(
                    font: fontLatin,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _getStatusInHebrew(String status) {
    switch (status) {
      case 'assigned':
        return 'הוקצה';
      case 'in_progress':
        return 'בביצוע';
      case 'completed':
        return 'הושלם';
      case 'cancelled':
        return 'בוטל';
      case 'pending':
        return 'ממתין';
      default:
        return status;
    }
  }
}
