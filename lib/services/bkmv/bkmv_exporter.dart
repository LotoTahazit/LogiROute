import 'package:archive/archive.dart';

import '../../models/invoice.dart';
import 'bkmv_codec.dart';
import 'bkmv_payment_lines.dart';
import 'bkmv_records.dart';

/// Сборка INI.TXT + BKMVDATA.TXT → ZIP (OPENFRMT).
class BkmvExporter {
  final BkmvCompanyContext company;
  final BkmvSoftwareInfo software;

  BkmvExporter({
    required this.company,
    this.software = const BkmvSoftwareInfo(),
  });

  BkmvExportResult build({
    required List<Invoice> invoices,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    final primaryId = BkmvCodec.newPrimaryId();
    final vatId = company.vatId;
    // Включаем ВСЕ выписанные (seq>0) документы, КРОМЕ черновиков. Отменённые
    // (cancelled/voided) обязаны оставаться в файле с флагом ביטול в C100 —
    // ניהול ספרים запрещает удаление, а пропуск создал бы дыру в רצף המספרים,
    // которую бракует валидатор налоговой. Черновики (ещё без номера) — не
    // бухгалтерские документы, их не выгружаем.
    final issued = invoices
        .where((i) =>
            i.sequentialNumber > 0 && i.status != InvoiceStatus.draft)
        .toList();

    final dataLines = <String>[];
    var recordNo = 0;
    var c100Count = 0;
    var d110Count = 0;
    var d120Count = 0;
    var linkSeq = 1;

    dataLines.add(BkmvRecords.encodeA100(
      recordNumber: ++recordNo,
      vatId: vatId,
      primaryId: primaryId,
    ));

    for (final inv in issued) {
      final linkId = linkSeq++;
      dataLines.add(BkmvRecords.encodeC100(
        recordNumber: ++recordNo,
        vatId: vatId,
        invoice: inv,
        linkId: linkId,
      ));
      c100Count++;

      var lineIdx = 1;
      for (final item in inv.items) {
        dataLines.add(BkmvRecords.encodeD110(
          recordNumber: ++recordNo,
          vatId: vatId,
          invoice: inv,
          item: item,
          lineIndex: lineIdx++,
          linkId: linkId,
        ));
        d110Count++;
      }

      if (BkmvRecords.needsPaymentLines(inv.documentType)) {
        var payIdx = 1;
        for (final pay in resolveBkmvPaymentLines(inv)) {
          dataLines.add(BkmvRecords.encodeD120(
            recordNumber: ++recordNo,
            vatId: vatId,
            invoice: inv,
            paymentLineIndex: payIdx++,
            linkId: linkId,
            payment: pay,
          ));
          d120Count++;
        }
      }
    }

    final totalInFile = recordNo + 1;
    dataLines.add(BkmvRecords.encodeZ900(
      recordNumber: ++recordNo,
      vatId: vatId,
      primaryId: primaryId,
      totalRecordsInFile: totalInFile,
    ));

    final processStart = DateTime.now();
    final iniLines = <String>[
      BkmvRecords.encodeA000(
        vatId: vatId,
        primaryId: primaryId,
        totalBkmvRecords: totalInFile,
        company: company,
        software: software,
        fromDate: fromDate,
        toDate: toDate,
        processStart: processStart,
      ),
      BkmvRecords.encodeIniSummary('A100', 1),
      if (c100Count > 0) BkmvRecords.encodeIniSummary('C100', c100Count),
      if (d110Count > 0) BkmvRecords.encodeIniSummary('D110', d110Count),
      if (d120Count > 0) BkmvRecords.encodeIniSummary('D120', d120Count),
      BkmvRecords.encodeIniSummary('Z900', 1),
    ];

    final bkmvText = dataLines.map(BkmvCodec.line).join();
    final iniText = iniLines.map(BkmvCodec.line).join();

    final iniBytes = BkmvCodec.encodeFile(iniText);
    final bkmvBytes = BkmvCodec.encodeFile(bkmvText);

    final archive = Archive()
      ..addFile(ArchiveFile('INI.TXT', iniBytes.length, iniBytes))
      ..addFile(ArchiveFile('BKMVDATA.TXT', bkmvBytes.length, bkmvBytes));

    final zipBytes = ZipEncoder().encode(archive)!;

    return BkmvExportResult(
      zipBytes: zipBytes,
      iniText: iniText,
      bkmvText: bkmvText,
      primaryId: primaryId,
      recordCounts: {
        'A100': 1,
        'C100': c100Count,
        'D110': d110Count,
        'D120': d120Count,
        'Z900': 1,
      },
      documentCount: c100Count,
    );
  }
}

class BkmvExportResult {
  final List<int> zipBytes;
  final String iniText;
  final String bkmvText;
  final String primaryId;
  final Map<String, int> recordCounts;
  final int documentCount;

  const BkmvExportResult({
    required this.zipBytes,
    required this.iniText,
    required this.bkmvText,
    required this.primaryId,
    required this.recordCounts,
    required this.documentCount,
  });
}
