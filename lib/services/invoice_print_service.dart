import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../models/audit_event.dart';
import '../models/company_settings.dart';
import '../services/company_settings_service.dart';
import '../services/audit_log_service.dart';
import '../services/print_event_service.dart';
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

  /// Печать חשבונית - генерирует PDF с несколькими копиями
  /// log-before-action: сначала лог, потом PDF
  static Future<void> printInvoice(
    Invoice invoice, {
    InvoiceCopyType? copyType,
    int copies = 1,
    String? actorUid,
    String? actorName,
  }) async {
    // Загружаем настройки компании
    final companySettings =
        await CompanySettingsService(companyId: invoice.companyId)
                .getSettings() ??
            CompanySettings(
              id: 'settings',
              nameHebrew: invoice.companyId,
              nameEnglish: invoice.companyId,
              taxId: '',
              addressHebrew: '',
              addressEnglish: '',
              poBox: '',
              city: '',
              zipCode: '',
              phone: '',
              fax: '',
              email: '',
              website: '',
              invoiceFooterText: 'תודה על הקנייה!',
              paymentTerms: 'תשלום עד 30 יום',
              bankDetails: '',
              driverName: '',
              driverPhone: '',
              departureTime: '07:00',
            );

    // Определяем тип копии
    InvoiceCopyType actualCopyType;
    if (copyType != null) {
      actualCopyType = copyType;
    } else if (!invoice.originalPrinted) {
      actualCopyType = InvoiceCopyType.original;
    } else {
      actualCopyType = InvoiceCopyType.copy;
    }

    // Защита: מקור нельзя печатать повторно (по израильскому закону)
    if (invoice.originalPrinted && actualCopyType == InvoiceCopyType.original) {
      actualCopyType = InvoiceCopyType.copy;
    }

    // חסימת הדפסת מקור ללא מספר הקצאה (לחשבוניות מעל הסף)
    if (actualCopyType == InvoiceCopyType.original &&
        invoice.requiresAssignment &&
        invoice.assignmentStatus != AssignmentStatus.approved) {
      throw Exception('לא ניתן להדפיס מקור — ממתין למספר הקצאה מרשות המסים');
    }

    // log-before-action: רישום לפני יצירת PDF
    if (actorUid != null && invoice.id.isNotEmpty) {
      final auditService = AuditLogService(companyId: invoice.companyId);
      await auditService.logEvent(
        entityId: invoice.id,
        entityType: invoice.documentType.name,
        eventType: AuditEventType.printed,
        actorUid: actorUid,
        actorName: actorName,
        metadata: {
          'copyType': actualCopyType.name,
          'copies': copies,
          'isOriginal': actualCopyType == InvoiceCopyType.original,
        },
      );
      // רישום אירוע הדפסה מפורט
      final printEventService = PrintEventService(companyId: invoice.companyId);
      await printEventService.recordPrintEvent(
        documentId: invoice.id,
        printedBy: actorUid,
        printedByName: actorName,
        mode: actualCopyType,
        copiesCount: copies,
      );
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

    for (int i = 0; i < copies; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice, fontHebrew, fontHebrewBold, fontLatin,
                  actualCopyType, companySettings),
              pw.SizedBox(height: 10),
              _buildInvoiceTitle(invoice, fontHebrew, fontHebrewBold, fontLatin,
                  actualCopyType),
              pw.SizedBox(height: 10),
              _buildClientInfo(invoice, fontHebrew, fontHebrewBold, fontLatin),
              pw.SizedBox(height: 15),
              _buildItemsTable(invoice, fontHebrew, fontHebrewBold, fontLatin),
              pw.SizedBox(height: 15),
              _buildTotals(invoice, fontHebrew, fontHebrewBold, fontLatin),
              pw.SizedBox(height: 20),
              _buildFooter(invoice, fontHebrew, fontHebrewBold, fontLatin,
                  companySettings),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    // Обновляем счетчики
    if (invoice.id.isNotEmpty) {
      await _updatePrintCounters(invoice.id, invoice.companyId, actualCopyType);
    }
  }

  /// Первая печать: 1 מקור + 2 העתק в одном PDF
  /// log-before-action: сначала лог, потом PDF
  static Future<void> printFirstTime(Invoice invoice,
      {String? actorUid, String? actorName}) async {
    final companySettings =
        await CompanySettingsService(companyId: invoice.companyId)
                .getSettings() ??
            CompanySettings(
              id: 'settings',
              nameHebrew: invoice.companyId,
              nameEnglish: invoice.companyId,
              taxId: '',
              addressHebrew: '',
              addressEnglish: '',
              poBox: '',
              city: '',
              zipCode: '',
              phone: '',
              fax: '',
              email: '',
              website: '',
              invoiceFooterText: 'תודה על הקנייה!',
              paymentTerms: 'תשלום עד 30 יום',
              bankDetails: '',
              driverName: '',
              driverPhone: '',
              departureTime: '07:00',
            );

    final fontHebrewData =
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf');
    final fontHebrewBoldData =
        await rootBundle.load('assets/fonts/NotoSansHebrew-Bold.ttf');
    final fontLatinData = await rootBundle.load('assets/fonts/Arial.ttf');

    final fontHebrew = pw.Font.ttf(fontHebrewData);
    final fontHebrewBold = pw.Font.ttf(fontHebrewBoldData);
    final fontLatin = pw.Font.ttf(fontLatinData);

    final pdf = pw.Document();

    // log-before-action: רישום לפני יצירת PDF
    if (actorUid != null && invoice.id.isNotEmpty) {
      // חסימת הדפסת מקור ללא מספר הקצאה — מדפיסים עותק במקום
      if (invoice.requiresAssignment &&
          invoice.assignmentStatus != AssignmentStatus.approved) {
        // מדפיסים עותק זמני — מקור יודפס לאחר קבלת מספר הקצאה
        final auditService = AuditLogService(companyId: invoice.companyId);
        await auditService.logEvent(
          entityId: invoice.id,
          entityType: invoice.documentType.name,
          eventType: AuditEventType.printed,
          actorUid: actorUid,
          actorName: actorName,
          metadata: {
            'copyType': 'copy_pending_assignment',
            'copies': 3,
            'isFirstPrint': true,
            'note': 'printed as copy — awaiting assignment number',
          },
        );
        final printEventService =
            PrintEventService(companyId: invoice.companyId);
        await printEventService.recordPrintEvent(
          documentId: invoice.id,
          printedBy: actorUid,
          printedByName: actorName,
          mode: InvoiceCopyType.copy,
          copiesCount: 3,
        );
        // מדפיסים 3 עותקים (לא מקור) עד קבלת מספר הקצאה
        for (int i = 0; i < 3; i++) {
          pdf.addPage(_buildInvoicePage(invoice, fontHebrew, fontHebrewBold,
              fontLatin, InvoiceCopyType.copy, companySettings));
        }
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name:
              'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        return;
      }
      final auditService = AuditLogService(companyId: invoice.companyId);
      await auditService.logEvent(
        entityId: invoice.id,
        entityType: invoice.documentType.name,
        eventType: AuditEventType.printed,
        actorUid: actorUid,
        actorName: actorName,
        metadata: {
          'copyType': 'original',
          'copies': 3,
          'isFirstPrint': true,
        },
      );
      final printEventService = PrintEventService(companyId: invoice.companyId);
      await printEventService.recordPrintEvent(
        documentId: invoice.id,
        printedBy: actorUid,
        printedByName: actorName,
        mode: InvoiceCopyType.original,
        copiesCount: 3,
      );
    }

    // 1 экземпляр מקור (по закону — только один оригинал)
    pdf.addPage(_buildInvoicePage(invoice, fontHebrew, fontHebrewBold,
        fontLatin, InvoiceCopyType.original, companySettings));
    // 2 экземпляра העתק
    for (int i = 0; i < 2; i++) {
      pdf.addPage(_buildInvoicePage(invoice, fontHebrew, fontHebrewBold,
          fontLatin, InvoiceCopyType.copy, companySettings));
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Invoice_${invoice.clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (invoice.id.isNotEmpty) {
      await _updatePrintCounters(
          invoice.id, invoice.companyId, InvoiceCopyType.original);
    }
  }

  /// Печать всех חשבוניות маршрута в одном PDF
  /// log-before-action: сначала лог, потом PDF
  static Future<void> printAllRouteInvoices(List<Invoice> invoices,
      {String? actorUid, String? actorName}) async {
    if (invoices.isEmpty) return;

    final fontHebrewData =
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf');
    final fontHebrewBoldData =
        await rootBundle.load('assets/fonts/NotoSansHebrew-Bold.ttf');
    final fontLatinData = await rootBundle.load('assets/fonts/Arial.ttf');

    final fontHebrew = pw.Font.ttf(fontHebrewData);
    final fontHebrewBold = pw.Font.ttf(fontHebrewBoldData);
    final fontLatin = pw.Font.ttf(fontLatinData);

    // Кешируем настройки по companyId
    final Map<String, CompanySettings> settingsCache = {};

    final pdf = pw.Document();

    for (final invoice in invoices) {
      if (!settingsCache.containsKey(invoice.companyId)) {
        settingsCache[invoice.companyId] =
            await CompanySettingsService(companyId: invoice.companyId)
                    .getSettings() ??
                CompanySettings(
                  id: 'settings',
                  nameHebrew: invoice.companyId,
                  nameEnglish: invoice.companyId,
                  taxId: '',
                  addressHebrew: '',
                  addressEnglish: '',
                  poBox: '',
                  city: '',
                  zipCode: '',
                  phone: '',
                  fax: '',
                  email: '',
                  website: '',
                  invoiceFooterText: 'תודה על הקנייה!',
                  paymentTerms: '',
                  bankDetails: '',
                  driverName: '',
                  driverPhone: '',
                  departureTime: '07:00',
                );
      }
      final settings = settingsCache[invoice.companyId]!;

      // log-before-action: רישום לפני יצירת PDF
      if (actorUid != null && invoice.id.isNotEmpty) {
        // חסימת הדפסת מקור ללא מספר הקצאה
        if (invoice.requiresAssignment &&
            invoice.assignmentStatus != AssignmentStatus.approved) {
          print(
              '⚠️ [Print] Skipping invoice ${invoice.id} — pending assignment');
          continue;
        }
        final auditService = AuditLogService(companyId: invoice.companyId);
        await auditService.logEvent(
          entityId: invoice.id,
          entityType: invoice.documentType.name,
          eventType: AuditEventType.printed,
          actorUid: actorUid,
          actorName: actorName,
          metadata: {
            'copyType': 'original',
            'copies': 3,
            'isRoutePrint': true,
          },
        );
        final printEventService =
            PrintEventService(companyId: invoice.companyId);
        await printEventService.recordPrintEvent(
          documentId: invoice.id,
          printedBy: actorUid,
          printedByName: actorName,
          mode: InvoiceCopyType.original,
          copiesCount: 3,
        );
      }

      // 1 מקור + 2 העתק для каждого счёта (по закону — только один оригинал)
      pdf.addPage(_buildInvoicePage(invoice, fontHebrew, fontHebrewBold,
          fontLatin, InvoiceCopyType.original, settings));
      for (int i = 0; i < 2; i++) {
        pdf.addPage(_buildInvoicePage(invoice, fontHebrew, fontHebrewBold,
            fontLatin, InvoiceCopyType.copy, settings));
      }

      if (invoice.id.isNotEmpty) {
        await _updatePrintCounters(
            invoice.id, invoice.companyId, InvoiceCopyType.original);
      }
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Route_Invoices_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Построить одну страницу счёта
  static pw.Page _buildInvoicePage(
    Invoice invoice,
    pw.Font fontHebrew,
    pw.Font fontHebrewBold,
    pw.Font fontLatin,
    InvoiceCopyType copyType,
    CompanySettings companySettings,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(invoice, fontHebrew, fontHebrewBold, fontLatin, copyType,
              companySettings),
          pw.SizedBox(height: 10),
          _buildInvoiceTitle(
              invoice, fontHebrew, fontHebrewBold, fontLatin, copyType),
          pw.SizedBox(height: 10),
          _buildClientInfo(invoice, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 15),
          _buildItemsTable(invoice, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 15),
          _buildTotals(invoice, fontHebrew, fontHebrewBold, fontLatin),
          pw.SizedBox(height: 20),
          _buildFooter(
              invoice, fontHebrew, fontHebrewBold, fontLatin, companySettings),
        ],
      ),
    );
  }

  /// Обновление счетчиков печати
  static Future<void> _updatePrintCounters(
    String invoiceId,
    String companyId,
    InvoiceCopyType copyType,
  ) async {
    // ✅ Используем companyId из параметра
    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('invoices')
        .doc(invoiceId);

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
        // Левая часть - название компании на английском + ח.פ
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
              'אתר  ${settings.website}',
              fontHebrew,
              fontLatin,
              fontSize: 9,
            ),
            _smartText(
              'ח.פ  ${settings.taxId}',
              fontHebrew,
              fontLatin,
              fontSize: 10,
              bold: true,
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
  /// כולל: סוג מסמך, סימון טיוטה, סימון הדפסה חוזרת
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

    // שם המסמך לפי סוג
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
    }

    // הדפסה חוזרת — אם המקור כבר הודפס וזו לא הדפסה ראשונה
    final bool isReprint =
        invoice.originalPrinted && copyType != InvoiceCopyType.original;
    final reprintNow = DateTime.now();
    final reprintStr = isReprint
        ? 'הדפסה חוזרת ${reprintNow.day.toString().padLeft(2, '0')}/${reprintNow.month.toString().padLeft(2, '0')}/${reprintNow.year} ${reprintNow.hour.toString().padLeft(2, '0')}:${reprintNow.minute.toString().padLeft(2, '0')}'
        : '';

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
        // חשבונית מס / קבלה / תעודת משלוח / זיכוי + номер
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          alignment: pw.Alignment.center,
          child: pw.Column(
            children: [
              // סימון טיוטה
              if (invoice.status == InvoiceStatus.draft)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: _smartText(
                    'טיוטה — לא לשימוש רשמי',
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 14,
                    bold: true,
                    color: PdfColors.red,
                  ),
                ),
              pw.Row(
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
                    documentTitle,
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 20,
                    bold: true,
                  ),
                ],
              ),
              // סימון הדפסה חוזרת
              if (isReprint)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: _smartText(
                    reprintStr,
                    fontHebrew,
                    fontLatin,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
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
    Invoice invoice,
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
        // Информация о водителе и машине
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
                    invoice.driverName,
                    fontHebrewBold,
                    fontLatin,
                    fontSize: 11,
                    bold: true,
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
                  pw.SizedBox(height: 3),
                  _smartText(
                    invoice.truckNumber,
                    fontLatin,
                    fontHebrew,
                    fontSize: 11,
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
                    '07:00',
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
        pw.SizedBox(height: 15),
        // Подпись внизу
        pw.Container(
          width: double.infinity,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _smartText(
                'תודה על הקנייה!',
                fontHebrewBold,
                fontLatin,
                fontSize: 10,
                bold: true,
              ),
              pw.SizedBox(height: 3),
              _smartText(
                'נשמח לשרת אתכם שוב',
                fontHebrew,
                fontLatin,
                fontSize: 9,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        // מטא-נתונים: תאריך הפקה, מזהה מסמך
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
                    font: fontLatin, fontSize: 7, color: PdfColors.grey600),
              ),
              _smartText(
                'הופק: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                fontHebrew,
                fontLatin,
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
