import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/company_settings.dart';
import '../../../services/company_settings_service.dart';

/// Панель закрытия учётного периода — используется в הגדרות и в бухгалтерии.
class AccountingPeriodLockPanel extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;
  final VoidCallback? onSaved;

  const AccountingPeriodLockPanel({
    super.key,
    required this.companyId,
    required this.companySettings,
    this.onSaved,
  });

  @override
  State<AccountingPeriodLockPanel> createState() =>
      _AccountingPeriodLockPanelState();
}

class _AccountingPeriodLockPanelState extends State<AccountingPeriodLockPanel> {
  late DateTime? _lockedUntil;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lockedUntil = widget.companySettings.accountingLockedUntil;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .set({
        'accountingLockedUntil': _lockedUntil != null
            ? Timestamp.fromDate(_lockedUntil!)
            : null,
      }, SetOptions(merge: true));
      await CompanySettingsService(companyId: widget.companyId).saveSettings(
        widget.companySettings.copyWith(accountingLockedUntil: _lockedUntil),
      );
      widget.onSaved?.call();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSettingsSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final lockLabel = _lockedUntil != null
        ? fmt.format(_lockedUntil!)
        : l10n.notSetAllPeriodsOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.accountingPeriodLockDesc, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.accountingPeriodLockSection),
          subtitle: Text(lockLabel),
          trailing: IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _lockedUntil ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _lockedUntil = picked);
            },
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _saving
                  ? null
                  : () {
                      final now = DateTime.now();
                      setState(
                          () => _lockedUntil = DateTime(now.year, now.month, 0));
                    },
              icon: const Icon(Icons.history, size: 18),
              label: Text(l10n.lockPreviousMonthEnd),
            ),
            if (_lockedUntil != null)
              TextButton(
                onPressed:
                    _saving ? null : () => setState(() => _lockedUntil = null),
                child: Text(l10n.unlockAllPeriods),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ],
    );
  }
}
