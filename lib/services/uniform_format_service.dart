import 'dart:convert';

import '../models/invoice.dart';
import '../models/company_settings.dart';

/// מבנה אחיד (openformat / BKMVDATA) — экспорт для רשות המסים.
///
/// Производит ДВА файла фиксированного формата:
///   • BKMVDATA.txt — записи: A100 (открытие) → C100 (шапка документа) +
///     D110 (строка товара) [+ D120 (строка оплаты)] → … → Z900 (закрытие);
///   • INI.txt — сводка (A000 + счётчики по типам записей).
///
/// ⚠️⚠️ ВАЖНО: ШИРИНЫ/ПОЗИЦИИ ПОЛЕЙ ниже — это BEST-EFFORT реконструкция
/// מבנה אחיד v1.31. ПЕРЕД боевым использованием ОБЯЗАТЕЛЬНО сверить с
/// официальной спекой (gov.il «הוראות להפקת קבצים במבנה אחיד», horaot-131)
/// и прогнать через валидатор רשות המסים (בודק מבנה אחיד), поправив длины.
/// Плумбинг (структура файлов, порядок записей, нумерация, INI) — рабочий;
/// корректируются только длины/коды полей в одном месте — в билдерах записей.
class UniformFormatService {
  UniformFormatService({
    required this.companyId,
    required this.settings,
  });

  final String companyId;
  final CompanySettings settings;

  /// Внутренний счётчик порядкового номера записи (общий для всех записей
  /// BKMVDATA — требование формата: сквозная нумерация).
  int _recCounter = 0;

  String _vatId() => settings.taxId;

  // ───────────────────────── низкоуровневые поля ──────────────────────────

  /// Текстовое поле: слева, добивка пробелами, обрезка по [width].
  String _t(String? value, int width) {
    final v = (value ?? '').replaceAll(RegExp(r'[\r\n]'), ' ');
    if (v.length >= width) return v.substring(0, width);
    return v.padRight(width);
  }

  /// Числовое поле: целое, справа, добивка нулями слева, обрезка по [width].
  String _n(num value, int width) {
    final s = value.round().abs().toString();
    if (s.length >= width) return s.substring(s.length - width);
    return s.padLeft(width, '0');
  }

  /// Денежное поле: агорот (×100), целое, со знаком в первом символе.
  /// [width] включает знак. ⚠️ сверить формат знака/длины со спекой.
  String _money(num shekels, int width) {
    final agorot = (shekels * 100).round();
    final sign = agorot < 0 ? '-' : '+';
    final digits = agorot.abs().toString().padLeft(width - 1, '0');
    return '$sign${digits.substring(digits.length - (width - 1))}';
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';

  /// Код типа документа в מבנה אחיד. ⚠️ сверить коды со спекой
  /// (320=חשבונית מס, 305=חשבונית מס/קבלה, 400=קבלה, 330=זיכוי, 100=הזמנה…).
  int _docTypeCode(InvoiceDocumentType t) {
    switch (t) {
      case InvoiceDocumentType.invoice:
        return 320;
      case InvoiceDocumentType.taxInvoiceReceipt:
        return 305;
      case InvoiceDocumentType.receipt:
        return 400;
      case InvoiceDocumentType.creditNote:
        return 330;
      case InvoiceDocumentType.delivery:
        return 100;
    }
  }

  // ───────────────────────────── записи ───────────────────────────────────

  /// A100 — запись открытия файла.
  String _a100(String primaryId) {
    _recCounter++;
    return [
      'A100', // код записи
      _n(_recCounter, 9), // сквозной номер записи
      _t(_vatId(), 9), // מספר עוסק / ח.פ
      _t(primaryId, 15), // מזהה ראשי (уникальный id выгрузки)
      _t('&OF1.31&', 8), // версия формата (маркер)
      _t('', 50), // резерв
    ].join();
  }

  /// C100 — шапка документа.
  String _c100(Invoice inv, _Amounts a) {
    _recCounter++;
    return [
      'C100',
      _n(_recCounter, 9),
      _t(_vatId(), 9),
      _n(_docTypeCode(inv.documentType), 3), // סוג מסמך
      _t(inv.sequentialNumber.toString(), 20), // מספר מסמך
      _date(inv.deliveryDate), // תאריך מסמך
      _t(inv.clientName, 50), // שם לקוח
      _t(inv.clientNumber, 9), // ח.פ לקוח
      _money(a.subtotal, 15), // סכום לפני מע״מ
      _money(a.vat, 15), // סכום מע״מ
      _money(a.total, 15), // סכום כולל
      if (inv.assignmentNumber != null)
        _t(inv.assignmentNumber, 20) // מספר הקצאה
      else
        _t('', 20),
    ].join();
  }

  /// D110 — строка товара/услуги документа.
  String _d110(Invoice inv, InvoiceItem item, int lineNo) {
    _recCounter++;
    return [
      'D110',
      _n(_recCounter, 9),
      _t(_vatId(), 9),
      _n(_docTypeCode(inv.documentType), 3),
      _t(inv.sequentialNumber.toString(), 20),
      _n(lineNo, 4), // מספר שורה
      _t(item.productCode, 20), // מק"ט
      _t(item.displayText, 50), // תאור
      _money(item.quantity.toDouble(), 15), // כמות
      _money(item.pricePerUnit, 15), // מחיר יחידה
      _money(item.totalBeforeVAT, 15), // סה״כ שורה לפני מע״מ
    ].join();
  }

  /// D120 — строка оплаты (для קבלה / חשבונית מס/קבלה).
  String _d120(Invoice inv, InvoicePaymentLineLike pay, int lineNo) {
    _recCounter++;
    return [
      'D120',
      _n(_recCounter, 9),
      _t(_vatId(), 9),
      _t(inv.sequentialNumber.toString(), 20),
      _n(lineNo, 4),
      _n(pay.methodCode, 1), // אמצעי תשלום (1=מזומן,2=צ׳ק,3=אשראי,4=העברה…) ⚠️ сверить
      _money(pay.amount, 15),
    ].join();
  }

  /// Z900 — запись закрытия файла (итоговое число записей).
  String _z900(String primaryId, int totalRecords) {
    _recCounter++;
    return [
      'Z900',
      _n(_recCounter, 9),
      _t(_vatId(), 9),
      _t(primaryId, 15),
      _n(totalRecords + 1, 15), // включая саму Z900
      _t('', 50),
    ].join();
  }

  // ───────────────────────────── генерация ────────────────────────────────

  /// Строит BKMVDATA.txt из «живых» (issued/active) счетов за период.
  /// Возвращает (содержимое, число записей по типам) для INI.
  ({String data, Map<String, int> counts}) buildBkmvData(
    List<Invoice> invoices,
  ) {
    _recCounter = 0;
    final lines = <String>[];
    final counts = <String, int>{
      'A100': 0,
      'C100': 0,
      'D110': 0,
      'D120': 0,
      'Z900': 0,
    };
    final primaryId =
        '${_vatId()}${_date(DateTime.now())}${_time(DateTime.now())}';

    lines.add(_a100(primaryId));
    counts['A100'] = 1;

    for (final inv in invoices) {
      if (!inv.isLive) continue;
      final a = _Amounts.of(inv);
      lines.add(_c100(inv, a));
      counts['C100'] = counts['C100']! + 1;

      var lineNo = 0;
      for (final item in inv.items) {
        lineNo++;
        lines.add(_d110(inv, item, lineNo));
        counts['D110'] = counts['D110']! + 1;
      }

      // D120 — оплата (только для קבלה / חשבונית מס/קבלה).
      if (inv.documentType == InvoiceDocumentType.receipt ||
          inv.documentType == InvoiceDocumentType.taxInvoiceReceipt) {
        lines.add(_d120(
          inv,
          InvoicePaymentLineLike(methodCode: 1, amount: a.total),
          1,
        ));
        counts['D120'] = counts['D120']! + 1;
      }
    }

    lines.add(_z900(primaryId, _recCounter));
    counts['Z900'] = 1;

    return (data: '${lines.join('\r\n')}\r\n', counts: counts);
  }

  /// Строит INI.txt — сводку по типам записей.
  /// ⚠️ Точный формат INI (поля A000) сверить со спекой.
  String buildIni(Map<String, int> counts) {
    final primaryId =
        '${_vatId()}${_date(DateTime.now())}${_time(DateTime.now())}';
    final total = counts.values.fold<int>(0, (s, v) => s + v);
    final lines = <String>[
      [
        'A000',
        _n(total, 15), // общее число записей в BKMVDATA
        _t(_vatId(), 9),
        _t(primaryId, 15),
        _t('&OF1.31&', 8),
      ].join(),
    ];
    // По одной строке-счётчику на тип записи.
    counts.forEach((code, n) {
      if (n > 0) lines.add('$code${_n(n, 15)}');
    });
    return '${lines.join('\r\n')}\r\n';
  }

  /// Готовые байты обоих файлов (UTF-8). ⚠️ некоторые валидаторы требуют
  /// кодировку Windows-1255 — уточнить по спеке/валидатору.
  ({List<int> bkmvData, List<int> ini}) buildFilesBytes(
    List<Invoice> invoices,
  ) {
    final bkmv = buildBkmvData(invoices);
    final ini = buildIni(bkmv.counts);
    return (
      bkmvData: utf8.encode(bkmv.data),
      ini: utf8.encode(ini),
    );
  }
}

class _Amounts {
  final double subtotal;
  final double vat;
  final double total;
  const _Amounts(this.subtotal, this.vat, this.total);

  factory _Amounts.of(Invoice inv) =>
      _Amounts(inv.subtotalBeforeVAT, inv.vatAmount, inv.totalWithVAT);
}

/// Лёгкая модель строки оплаты для D120 (чтобы не тянуть зависимость).
class InvoicePaymentLineLike {
  final int methodCode;
  final double amount;
  const InvoicePaymentLineLike({required this.methodCode, required this.amount});
}
