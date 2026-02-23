import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../models/company_settings.dart';
import '../services/company_settings_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicePrintService {
  /// Извлекает город из адреса (текст после последней запятой)
  static String _extractCity(String address) {
    // Адрес обычно в формате: "улица номер, город"
    // Например: "בעל שם טוב 22, בת ים" или "רחוב הרצל 5, תל אביב"
    final parts = address.split(',');
    if (parts.length > 1) {
      // Берем все после последней запятой и убираем лишние пробелы
      return parts.last.trim();
    }
    // Если нет запятой, возвращаем пустую строку
    return '';
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
    pw.TextAlign? textAlign,
  }) {
    final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(text);
    final hasLatinOrDigits = RegExp(r'[A-Za-z0-9]').hasMatch(text);

    if (hasHebrew && hasLatinOrDigits) {
      final spans = <pw.InlineSpan>[];
      final buffer = StringBuffer();
      bool currentIsHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(text[0]);

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
        textAlign: textAlign ?? pw.TextAlign.right,
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
      textAlign: textAlign,
    );
  }

  /// Печать חשבונית
  static Future<void> printInvoice(
    Invoice invoice, {
    InvoiceCopyType? copyType,
  }) async {
    // Загружаем настройки компании
    final companySettings = await CompanySettingsService().getSettings();
    if (companySettings == null) {
      throw Exception(
          'Настройки компании не найдены. Настройте их в админ-панели.');
    }

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
              companySettings,
            ),
            pw.SizedBox(height: 10),
            _buildInvoiceTitle(
              invoice,
              fontHebrew,
              fontHebrewBold,
              fontLatin,
              actualCopyType,
            ),
            pw.SizedBox(height: 10),
            _buildClientInfo(invoice, fontHebrew, fontHebrewBold, fontLatin),
            pw.SizedBox(height: 15),
            _buildItemsTable(invoice, fontHebrew, fontHebrewBold, fontLatin),
            pw.SizedBox(height: 15),
            _buildTotals(invoice, fontHebrew, fontHebrewBold, fontLatin),
            pw.Spacer(),
            _buildFooter(
                fontHebrew, fontHebrewBold, fontLatin, companySettings),
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
        '⚠️ [InvoicePrint] Cannot update print counters: invoice ID is empty',
      );
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
      await docRef.update({'copiesPrinted': FieldValue.increment(1)});
    }
  }

  /// Заголовок - точная копия формата с фото
  static pw.Widget _buildHeader(
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
        // Левая часть - название компании на английском
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              settings.nameEnglish,
              style: pw.TextStyle(
                font: fontLatin,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'P.O.B ${settings.poBox}',
              style: pw.TextStyle(font: fontLatin, fontSize: 10),
            ),
            pw.Text(
              settings.addressEnglish,
              style: pw.TextStyle(font: fontLatin, fontSize: 10),
            ),
            pw.Text(
              'TEL. ${settings.phone}  FAX. ${settings.fax}',
              style: pw.TextStyle(font: fontLatin, fontSize: 9),
            ),
            pw.SizedBox(height: 2),
            _smartText(
              'אתר ${settings.website}',
              fontHebrew,
              fontLatin,
              fontSize: 9,
            ),
            _smartText(
              'ח.פ ${settings.taxId}',
              fontHebrew,
              fontLatin,
              fontSize: 9,
            ),
          ],
        ),
        // Центр - логотип (пропускаем как сказано)
        pw.SizedBox(width: 100),
        // Правая часть - название на иврите
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _smartText(
              settings.nameHebrew,
              fontHebrewBold,
              fontLatin,
              fontSize: 18,
              bold: true,
            ),
            pw.SizedBox(height: 4),
            _smartText(
              'ת.ד. ${settings.poBox}',
              fontHebrew,
              fontLatin,
              fontSize: 10,
            ),
            _smartText(
              settings.addressHebrew,
              fontHebrew,
              fontLatin,
              fontSize: 10,
            ),
            _smartText(
              'טל: ${settings.phone} פקס: ${settings.fax}',
              fontHebrew,
              fontLatin,
              fontSize: 9,
            ),
          ],
        ),
      ],
    );
  }

  /// Заголовок счёта с автоматическим определением типа копии
  static pw.Widget _buildInvoiceTitle(
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

    // Форматируем дату как на фото: 24/02/2026
    final dateStr =
        '${invoice.createdAt.day.toString().padLeft(2, '0')}/${invoice.createdAt.month.toString().padLeft(2, '0')}/${invoice.createdAt.year}';
    final timeStr =
        '${invoice.createdAt.hour.toString().padLeft(2, '0')}:${invoice.createdAt.minute.toString().padLeft(2, '0')}:${invoice.createdAt.second.toString().padLeft(2, '0')}';

    return pw.Column(
      children: [
        // Верхняя строка - тип копии, תאריך, שעה (БЕЗ מובייל)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Тип копии (מקור/עותק/נעימן למקור) - КРУПНЕЕ (БЕЗ ЦИФР ПОД НИМ)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _smartText(
                    copyTypeText,
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 14,
                    bold: true,
                  ),
                ],
              ),
              // תאריך ושעה
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _smartText(
                    'תאריך',
                    fontHebrew,
                    fontLatin,
                    fontSize: 9,
                  ),
                  pw.Text(
                    dateStr,
                    style: pw.TextStyle(font: fontLatin, fontSize: 9),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _smartText(
                    'שעה',
                    fontHebrew,
                    fontLatin,
                    fontSize: 9,
                  ),
                  pw.Text(
                    timeStr,
                    style: pw.TextStyle(font: fontLatin, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        // חשבונית מס + номер (номер ПОСЛЕ текста)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          alignment: pw.Alignment.center,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                invoice.sequentialNumber.toString(),
                style: pw.TextStyle(
                  font: fontLatin,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 5),
              _smartText(
                'חשבונית מס',
                fontHebrewBold,
                fontLatin,
                fontSize: 20,
                bold: true,
              ),
            ],
          ),
        ),
        // Дата оплаты (תשלום עד) - используем paymentDueDate или deliveryDate
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
                style: pw.TextStyle(font: fontLatin, fontSize: 12),
              ),
              pw.SizedBox(width: 10),
              _smartText(
                'תשלום עד',
                fontHebrewBold,
                fontLatin,
                fontSize: 12,
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Информация о клиенте - точная копия с фото
  static pw.Widget _buildClientInfo(
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
          // Левая часть - номер клиента (БОЛЬШОЙ) и город
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                invoice.clientNumber,
                style: pw.TextStyle(
                  font: fontLatin,
                  fontSize: 14, // Уменьшено с 24 до 14
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              _smartText(
                _extractCity(invoice.address),
                fontHebrewBold,
                fontLatin,
                fontSize: 12, // Увеличено с 11 до 12
                bold: true,
              ),
            ],
          ),
          // Правая часть - основная информация
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // לקוח
                _smartText(
                  'לקוח',
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 12,
                  bold: true,
                ),
                pw.SizedBox(height: 3),
                // Имя клиента
                _smartText(
                  invoice.clientName,
                  fontHebrewBold,
                  fontLatin,
                  fontSize: 11,
                  bold: true,
                ),
                pw.SizedBox(height: 3),
                // Адрес
                _smartText(
                  invoice.address,
                  fontHebrew,
                  fontLatin,
                  fontSize: 10,
                ),
                pw.SizedBox(height: 3),
                // ת.ד
                _smartText(
                  'ת.ד',
                  fontHebrew,
                  fontLatin,
                  fontSize: 10,
                ),
                pw.SizedBox(height: 3),
                // טלפון פקס - НА ИВРИТЕ, НО СЛЕВА НАПРАВО (LTR)
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: _smartText(
                    'טלפון 02-5631092 פקס',
                    fontHebrew,
                    fontLatin,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Таблица товаров - точная копия формата с фото
  static pw.Widget _buildItemsTable(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5), // מחיר
        1: const pw.FlexColumnWidth(1), // % הנחה
        2: const pw.FlexColumnWidth(1.5), // לקרטון
        3: const pw.FlexColumnWidth(1.5), // סה"כ יחידות
        4: const pw.FlexColumnWidth(1.5), // כמות בקרטון
        5: const pw.FlexColumnWidth(1.5), // כמות קרטונים
        6: const pw.FlexColumnWidth(3), // תאור פריט
        7: const pw.FlexColumnWidth(1.5), // מס' פריט
      },
      children: [
        // Заголовок
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('מחיר', fontHebrewBold, fontLatin),
            _buildTableHeader('% הנחה', fontHebrewBold, fontLatin),
            _buildTableHeader('לקרטון', fontHebrewBold, fontLatin),
            _buildTableHeader('סה״כ\nיחידות', fontHebrewBold, fontLatin),
            _buildTableHeader('כמות\nבקרטון', fontHebrewBold, fontLatin),
            _buildTableHeader('כמות\nקרטונים', fontHebrewBold, fontLatin),
            _buildTableHeader('תאור פריט', fontHebrewBold, fontLatin),
            _buildTableHeader('מס\' פריט', fontHebrewBold, fontLatin),
          ],
        ),
        // Строки товаров
        ...invoice.items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(
                item.totalBeforeVAT.toStringAsFixed(2),
                fontLatin,
                fontHebrew,
                align: pw.Alignment.centerRight,
              ),
              _buildTableCell(
                '${invoice.discount.toStringAsFixed(0)}%',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                item.pricePerUnit.toStringAsFixed(2),
                fontLatin,
                fontHebrew,
                align: pw.Alignment.centerRight,
              ),
              _buildTableCell(
                '${item.quantity}',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                '1500',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                '30.00',
                fontLatin,
                fontHebrew,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                '${item.type} ${item.number}',
                fontHebrew,
                fontLatin,
                align: pw.Alignment.centerRight,
              ),
              _buildTableCell(
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

  static pw.Widget _buildTableHeader(
      String text, pw.Font mainFont, pw.Font fallbackFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: _smartText(
        text,
        mainFont,
        fallbackFont,
        fontSize: 12,
        bold: true,
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
      child: _smartText(
        text,
        mainFont,
        fallbackFont,
        fontSize: 11,
      ),
    );
  }

  /// Итоги - точная копия с фото
  static pw.Widget _buildTotals(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Левая часть - итоги
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // סה"כ ב מע"מ
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoice.subtotalBeforeVAT.toStringAsFixed(2),
                    style: pw.TextStyle(font: fontLatin, fontSize: 11),
                  ),
                  _smartText(
                    'סה״כ',
                    fontHebrew,
                    fontLatin,
                    fontSize: 11,
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              // הנחה
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '0.00',
                    style: pw.TextStyle(font: fontLatin, fontSize: 11),
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        '0.0%',
                        style: pw.TextStyle(font: fontLatin, fontSize: 11),
                      ),
                      pw.SizedBox(width: 3),
                      _smartText(
                        'הנחה',
                        fontHebrew,
                        fontLatin,
                        fontSize: 11,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              // חיוב/זיכוי/תוספות
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '0.00',
                    style: pw.TextStyle(font: fontLatin, fontSize: 11),
                  ),
                  _smartText(
                    'חיוב/זיכוי/תוספות',
                    fontHebrew,
                    fontLatin,
                    fontSize: 10,
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              // סה"כ לפני מע"מ
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoice.subtotalBeforeVAT.toStringAsFixed(2),
                    style: pw.TextStyle(font: fontLatin, fontSize: 11),
                  ),
                  _smartText(
                    'סה״כ לפני מע״מ',
                    fontHebrew,
                    fontLatin,
                    fontSize: 11,
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              // מע"מ 18%
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoice.vatAmount.toStringAsFixed(2),
                    style: pw.TextStyle(font: fontLatin, fontSize: 11),
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        '18%',
                        style: pw.TextStyle(font: fontLatin, fontSize: 11),
                      ),
                      pw.SizedBox(width: 3),
                      _smartText(
                        'מע״מ',
                        fontHebrew,
                        fontLatin,
                        fontSize: 11,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 5),
              // סה"כ לתשלום
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    invoice.totalWithVAT.toStringAsFixed(2),
                    style: pw.TextStyle(
                      font: fontLatin,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  _smartText(
                    'סה״כ לתשלום',
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 14,
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Правая часть - пустое место
        pw.SizedBox(width: 200),
      ],
    );
  }

  /// Подпись и условия внизу - точная копия с фото
  static pw.Widget _buildFooter(
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
    CompanySettings settings,
  ) {
    // Разбиваем текст футера на строки
    final footerLines = settings.invoiceFooterText.split('\n');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Условия оплаты
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: footerLines.map((line) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: _smartText(
                  line,
                  line == footerLines.first ? fontHebrewBold : fontHebrew,
                  fontLatin,
                  fontSize: line == footerLines.first ? 10 : 9,
                  bold: line == footerLines.first,
                ),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 10),
        // חתימה (Signature field)
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _smartText(
                'חתימה',
                fontHebrewBold,
                fontLatin,
                fontSize: 11,
                bold: true,
              ),
              pw.SizedBox(height: 30), // Space for signature
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        // יבגני section
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Водитель
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _smartText(
                    settings.driverName,
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 11,
                    bold: true,
                  ),
                  pw.SizedBox(height: 3),
                  _smartText(
                    settings.driverPhone,
                    fontLatin,
                    fontHebrew,
                    fontSize: 11,
                  ),
                ],
              ),
              // מס' רכב
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _smartText(
                    'מס\' רכב:',
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 11,
                    bold: true,
                  ),
                ],
              ),
              // שעת יציאה
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _smartText(
                    'שעת יציאה :',
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 11,
                    bold: true,
                  ),
                  pw.SizedBox(height: 3),
                  _smartText(
                    settings.departureTime,
                    fontLatin,
                    fontHebrew,
                    fontSize: 12,
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
