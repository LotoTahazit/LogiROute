import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/delivery_point.dart';
import '../models/user_model.dart';

class PrintService {
  // ── Cached fonts ──────────────────────────────────────────
  static pw.Font? _cachedHebrew;
  static pw.Font? _cachedHebrewBold;
  static pw.Font? _cachedLatin;

  static Future<({pw.Font hebrew, pw.Font hebrewBold, pw.Font latin})>
      _loadFonts() async {
    _cachedHebrew ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'));
    _cachedHebrewBold ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansHebrew-Bold.ttf'));
    _cachedLatin ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Arial.ttf'));
    return (
      hebrew: _cachedHebrew!,
      hebrewBold: _cachedHebrewBold!,
      latin: _cachedLatin!
    );
  }

  // ── Pre-compiled RegExp (avoid re-creation per call) ──────
  static final RegExp _hebrewRe = RegExp(r'[\u0590-\u05FF]');
  static final RegExp _latinDigitRe = RegExp(r'[A-Za-z0-9]');

  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String _formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Определяет направление текста
  static pw.TextDirection _getTextDirection(String text) {
    return _hebrewRe.hasMatch(text)
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
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
    final hasHebrew = _hebrewRe.hasMatch(text);
    final hasLatinOrDigits = _latinDigitRe.hasMatch(text);

    if (hasHebrew && hasLatinOrDigits) {
      final spans = <pw.InlineSpan>[];
      final buffer = StringBuffer();
      bool currentIsHebrew = _isHebrewChar(text.codeUnitAt(0));

      void flush() {
        if (buffer.isEmpty) return;
        spans.add(
          pw.TextSpan(
            text: buffer.toString(),
            style: pw.TextStyle(
              font: currentIsHebrew ? mainFont : latinFont,
              fontFallback: [mainFont, latinFont],
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        );
        buffer.clear();
      }

      for (int i = 0; i < text.length; i++) {
        final isHeb = _isHebrewChar(text.codeUnitAt(i));
        if (isHeb != currentIsHebrew) {
          flush();
          currentIsHebrew = isHeb;
        }
        buffer.writeCharCode(text.codeUnitAt(i));
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

  /// Fast Hebrew char check without RegExp
  static bool _isHebrewChar(int codeUnit) =>
      codeUnit >= 0x0590 && codeUnit <= 0x05FF;

  static Future<void> printRoute({
    required UserModel driver,
    required List<DeliveryPoint> points,
  }) async {
    if (points.isEmpty) return;

    final sortedPoints = List<DeliveryPoint>.from(points)
      ..sort((a, b) => a.orderInRoute.compareTo(b.orderInRoute));

    final fonts = await _loadFonts();
    final fontHebrew = fonts.hebrew;
    final fontHebrewBold = fonts.hebrewBold;
    final fontLatin = fonts.latin;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          _buildHeader(driver, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 10),
          _buildRouteTable(sortedPoints, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 10),
          _buildSummary(sortedPoints, fontHebrew, fontHebrewBold, fontLatin),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Route_${driver.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Заголовок — компактный
  static pw.Widget _buildHeader(
    UserModel driver,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              _smartText('מסלול משלוח', fontHebrewBold, fontLatin,
                  fontSize: 12, bold: true),
              pw.SizedBox(width: 12),
              _smartText('נהג: ${driver.name}', fontHebrew, fontLatin,
                  fontSize: 9),
              pw.SizedBox(width: 8),
              _smartText('קיבולת: ${driver.palletCapacity ?? 0}', fontHebrew,
                  fontLatin,
                  fontSize: 9),
            ],
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              _formatDate(DateTime.now().toLocal()),
              style: pw.TextStyle(font: fontLatin, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  /// Таблица маршрута — блоки по клиентам (компактные)
  static pw.Widget _buildRouteTable(
    List<DeliveryPoint> points,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Column(
      children: points.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        final orderNumber = index + 1;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Заголовок клиента — компактный
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey700, width: 1),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue700,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '$orderNumber',
                          style: pw.TextStyle(
                            font: fontLatin,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    _smartText(
                      point.clientNumber ?? '',
                      fontHebrewBold,
                      fontLatin,
                      fontSize: 8,
                      bold: true,
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _smartText(
                        point.clientName,
                        fontHebrewBold,
                        fontLatin,
                        fontSize: 8,
                        bold: true,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: _smartText(
                        point.address,
                        fontHebrew,
                        fontLatin,
                        fontSize: 7,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    _smartText(
                      '${point.pallets} משט\'',
                      fontHebrewBold,
                      fontLatin,
                      fontSize: 8,
                      bold: true,
                    ),
                  ],
                ),
              ),
              // Таблица товаров
              if (point.boxTypes != null && point.boxTypes!.isNotEmpty)
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableCell('כמות', fontHebrewBold, fontLatin,
                            isHeader: true),
                        _buildTableCell('תאור פריט', fontHebrewBold, fontLatin,
                            isHeader: true),
                        _buildTableCell('מק"ט', fontHebrewBold, fontLatin,
                            isHeader: true),
                      ],
                    ),
                    ...point.boxTypes!.map((box) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                              '${box.quantity}', fontLatin, fontHebrew),
                          _buildTableCell('${box.type} ${box.number}',
                              fontHebrew, fontLatin),
                          _buildTableCell(
                              box.productCode, fontLatin, fontHebrew),
                        ],
                      );
                    }),
                  ],
                ),
              // Итого — компактная строка
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    _smartText(
                      'סה"כ: ${point.boxes} יח\'',
                      fontHebrewBold,
                      fontLatin,
                      fontSize: 7,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font mainFont,
    pw.Font latinFont, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: pw.Alignment.center,
      child: _smartText(
        text,
        mainFont,
        latinFont,
        fontSize: isHeader ? 8 : 8,
        bold: isHeader,
      ),
    );
  }

  /// Сводка — компактная
  static pw.Widget _buildSummary(
    List<DeliveryPoint> points,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    final totalPallets = points.fold(0, (sum, p) => sum + p.pallets);
    final totalBoxes = points.fold(0, (sum, p) => sum + p.boxes);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _smartText('סה"כ: $totalBoxes יח\'', fontHebrewBold, fontLatin,
              fontSize: 9, bold: true),
          _smartText('משטחים: $totalPallets', fontHebrewBold, fontLatin,
              fontSize: 9, bold: true),
          _smartText('נקודות: ${points.length}', fontHebrew, fontLatin,
              fontSize: 9),
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              'LogiRoute ${_formatDateTime(DateTime.now().toLocal())}',
              style: pw.TextStyle(
                font: fontLatin,
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // תעודת ליקוט — Picking List (лист сборки для склада)
  // =========================================================

  static Future<void> printPickingList({
    required List<DeliveryPoint> points,
    String? driverName,
  }) async {
    if (points.isEmpty) return;

    final fonts = await _loadFonts();
    final fontHebrew = fonts.hebrew;
    final fontHebrewBold = fonts.hebrewBold;
    final fontLatin = fonts.latin;

    final pdf = pw.Document();
    final dateStr = _formatDate(DateTime.now().toLocal());
    final dateTimeStr = _formatDateTime(DateTime.now().toLocal());

    // Каждый заказ — отдельная страница
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final products = point.boxTypes ?? [];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _smartText('תעודת ליקוט', fontHebrewBold, fontLatin,
                        fontSize: 14, bold: true),
                    _smartText(
                        '${i + 1} / ${points.length}', fontLatin, fontHebrew,
                        fontSize: 9),
                    if (driverName != null)
                      _smartText('נהג: $driverName', fontHebrew, fontLatin,
                          fontSize: 9),
                    pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        dateStr,
                        style: pw.TextStyle(font: fontLatin, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              // Блок клиента
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700, width: 1),
                ),
                child: pw.Column(
                  children: [
                    // Заголовок клиента
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(color: PdfColors.grey700, width: 1),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 28,
                            height: 28,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.blue700,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '${i + 1}',
                                style: pw.TextStyle(
                                  font: fontLatin,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: _smartText(
                              point.clientName,
                              fontHebrewBold,
                              fontLatin,
                              fontSize: 14,
                              bold: true,
                            ),
                          ),
                          _smartText(
                            '${point.pallets} משטחים',
                            fontHebrew,
                            fontLatin,
                            fontSize: 11,
                          ),
                        ],
                      ),
                    ),
                    // Таблица товаров
                    if (products.isNotEmpty)
                      pw.Table(
                        border: pw.TableBorder.all(
                            color: PdfColors.grey400, width: 0.5),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(70),
                          1: const pw.FlexColumnWidth(3),
                          2: const pw.FixedColumnWidth(60),
                          3: const pw.FixedColumnWidth(40),
                        },
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                                color: PdfColors.grey100),
                            children: [
                              _buildPickingCell(
                                  'מק"ט', fontHebrewBold, fontLatin,
                                  isHeader: true),
                              _buildPickingCell(
                                  'תאור פריט', fontHebrewBold, fontLatin,
                                  isHeader: true),
                              _buildPickingCell(
                                  'כמות', fontHebrewBold, fontLatin,
                                  isHeader: true),
                              _buildPickingCell('✓', fontLatin, fontHebrew,
                                  isHeader: true),
                            ],
                          ),
                          ...products.map((box) {
                            return pw.TableRow(
                              children: [
                                _buildPickingCell(
                                    box.productCode, fontLatin, fontHebrew),
                                _buildPickingCell('${box.type} ${box.number}',
                                    fontHebrew, fontLatin),
                                _buildPickingCell(
                                    '${box.quantity}', fontLatin, fontHebrew),
                                _buildPickingCell('', fontLatin, fontHebrew),
                              ],
                            );
                          }),
                        ],
                      ),
                    // Итого
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey100),
                      child: pw.Row(
                        children: [
                          _smartText(
                            'סה"כ: ${point.boxes} יח\'',
                            fontHebrewBold,
                            fontLatin,
                            fontSize: 10,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              // Футер
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _smartText(
                      'סה"כ במסלול: ${points.length} לקוחות',
                      fontHebrew,
                      fontLatin,
                      fontSize: 8,
                    ),
                    pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        'LogiRoute $dateTimeStr',
                        style: pw.TextStyle(
                          font: fontLatin,
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'PickingList_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildPickingCell(
    String text,
    pw.Font mainFont,
    pw.Font latinFont, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      alignment: pw.Alignment.center,
      child: _smartText(
        text,
        mainFont,
        latinFont,
        fontSize: 9,
        bold: isHeader,
      ),
    );
  }
}
