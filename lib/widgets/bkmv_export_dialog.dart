import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/company_settings.dart';
import '../services/bkmv/bkmv_records.dart';
import '../services/bkmv/bkmv_simulator.dart';
import '../services/uniform_export_service.dart';
import '../utils/file_download.dart';

/// Диалог выбора периода и הורדת BKMV (OPENFRMT).
Future<void> showBkmvExportDialog({
  required BuildContext context,
  required String companyId,
  required CompanySettings settings,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _BkmvExportDialog(
      companyId: companyId,
      settings: settings,
    ),
  );
}

class _BkmvExportDialog extends StatefulWidget {
  final String companyId;
  final CompanySettings settings;

  const _BkmvExportDialog({
    required this.companyId,
    required this.settings,
  });

  @override
  State<_BkmvExportDialog> createState() => _BkmvExportDialogState();
}

class _BkmvExportDialogState extends State<_BkmvExportDialog> {
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  BkmvCompanyContext get _companyCtx => BkmvCompanyContext(
        vatId: widget.settings.taxId,
        businessName: widget.settings.nameHebrew.isNotEmpty
            ? widget.settings.nameHebrew
            : widget.settings.nameEnglish,
        street: widget.settings.addressHebrew,
        city: widget.settings.city,
        zipCode: widget.settings.zipCode,
      );

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_fromDate.isAfter(_toDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.settings.taxId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bkmvTaxIdRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
      final to = DateTime(_toDate.year, _toDate.month, _toDate.day);
      final service = UniformExportService(companyId: widget.companyId);
      final result = await service.exportOpenFormat(
        fromDate: from,
        toDate: to,
        exportedBy: uid,
        company: _companyCtx,
        software: BkmvSoftwareInfo(
          registrationNumber:
              widget.settings.bkmvSoftwareRegistrationNumber.padLeft(8, '0')
                  .substring(0, 8),
        ),
      );

      if (!mounted) return;
      if (result.documentCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bkmvExportEmpty),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final sim = BkmvSimulator.validateExport(result);
      if (!sim.ok) {
        await _showSimulatorFailure(l10n, sim);
        return;
      }

      final fileName = UniformExportService.zipFileName(
        widget.settings.taxId,
        to,
      );
      await _deliverZip(result.zipBytes, fileName);

      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = StringBuffer()
        ..writeln(l10n.exportRecordsCount(result.documentCount, fileName))
        ..write(l10n.bkmvSimulatorPassed);
      if (sim.warnings.isNotEmpty) {
        msg
          ..writeln()
          ..write('${l10n.bkmvSimulatorWarnings}: ${sim.warnings.join('; ')}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.toString()),
          backgroundColor: Colors.green,
          duration: Duration(seconds: sim.warnings.isEmpty ? 4 : 7),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportErrorWithDetail(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showSimulatorFailure(
    AppLocalizations l10n,
    BkmvSimulatorResult sim,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: Text(l10n.bkmvSimulatorFailedTitle),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.bkmvSimulatorFailedBody),
                const SizedBox(height: 12),
                ...sim.errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(e)),
                      ],
                    ),
                  ),
                ),
                if (sim.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.bkmvSimulatorWarnings,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  ...sim.warnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('⚠ $w',
                          style: Theme.of(ctx).textTheme.bodySmall),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _deliverZip(List<int> bytes, String name) async {
    if (kIsWeb) {
      downloadFile(bytes, name);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(bytes), mimeType: 'application/zip', name: name)],
      subject: name,
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return AlertDialog(
      title: Text(l10n.downloadBkmv),
      content: SizedBox(
        width: narrow ? double.maxFinite : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.bkmvExportSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(l10n.periodSection,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _pickDate(true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}'),
                ),
                Text(l10n.untilLabel),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _pickDate(false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${_toDate.day}/${_toDate.month}/${_toDate.year}'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _exporting ? null : _export,
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download),
          label: Text(_exporting ? l10n.exporting : l10n.downloadBkmv),
        ),
      ],
    );
  }
}
