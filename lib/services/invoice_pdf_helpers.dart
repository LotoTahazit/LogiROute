import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/company_settings.dart';

/// Shared helpers for invoice PDF generation:
/// font loading, text direction, smart text widget, default settings.

// ── Pre-compiled RegExp ─────────────────────────────────────
final RegExp _hebrewRe = RegExp(r'[\u0590-\u05FF]');
final RegExp _latinDigitRe = RegExp(r'[A-Za-z0-9]');

bool _isHebrewChar(int codeUnit) => codeUnit >= 0x0590 && codeUnit <= 0x05FF;

// Cached fonts — loaded once per session
pw.Font? fontHebrewCache;
pw.Font? fontHebrewBoldCache;
pw.Font? fontLatinCache;
Future<void>? _loadFontsFuture;

Future<void> loadPdfFonts() async {
  if (fontHebrewCache != null) return;
  // Prevent parallel loading — reuse the same future
  _loadFontsFuture ??= _doLoadPdfFonts();
  await _loadFontsFuture;
}

Future<void> _doLoadPdfFonts() async {
  try {
    final results = await Future.wait([
      rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSansHebrew-Bold.ttf'),
      rootBundle.load('assets/fonts/Arial.ttf'),
    ]);
    fontHebrewCache = pw.Font.ttf(results[0]);
    fontHebrewBoldCache = pw.Font.ttf(results[1]);
    fontLatinCache = pw.Font.ttf(results[2]);
  } catch (e) {
    _loadFontsFuture = null; // Allow retry on failure
    rethrow;
  }
}

/// Extracts city from address (text after last comma)
String extractCity(String address) {
  final parts = address.split(',');
  if (parts.length > 1) {
    return parts.last.trim();
  }
  return '';
}

/// Determines text direction based on Hebrew characters
pw.TextDirection getTextDirection(String text) {
  return _hebrewRe.hasMatch(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
}

/// Smart text widget that correctly renders digits and English inside Hebrew
pw.Widget smartText(
  String text,
  pw.Font mainFont,
  pw.Font latinFont, {
  double fontSize = 12,
  bool bold = false,
  PdfColor color = PdfColors.black,
  pw.TextAlign? textAlign,
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
    textDirection: getTextDirection(text),
    textAlign: textAlign,
  );
}

/// Creates default CompanySettings when none found in Firestore
CompanySettings defaultCompanySettings(String companyId) {
  return CompanySettings(
    id: 'settings',
    nameHebrew: companyId,
    nameEnglish: companyId,
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
}
