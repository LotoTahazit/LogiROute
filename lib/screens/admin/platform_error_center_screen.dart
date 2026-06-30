import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_system_error.dart';
import '../../services/auth_service.dart';
import '../../services/platform_error_service.dart';
import '../../theme/app_theme.dart';
import 'platform_error_detail_screen.dart';

/// Platform Error Center — только super_admin.
class PlatformErrorCenterScreen extends StatefulWidget {
  const PlatformErrorCenterScreen({super.key});

  @override
  State<PlatformErrorCenterScreen> createState() =>
      _PlatformErrorCenterScreenState();
}

class _PlatformErrorCenterScreenState extends State<PlatformErrorCenterScreen> {
  final _service = PlatformErrorService();
  PlatformErrorSeverity? _severity;
  bool _openOnly = true;
  String? _companyFilter;
  static final _fmt = DateFormat('dd.MM.yy HH:mm');

  Color _severityColor(PlatformErrorSeverity s) {
    switch (s) {
      case PlatformErrorSeverity.critical:
        return AppTheme.danger;
      case PlatformErrorSeverity.high:
        return AppTheme.warning;
      case PlatformErrorSeverity.medium:
        return AppTheme.warning;
      case PlatformErrorSeverity.low:
        return AppTheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();

    if (auth.userModel?.isSuperAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.platformErrorCenterTitle)),
        body: Center(child: Text(l10n.demoCompanySuperAdminOnly)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.platformErrorCenterTitle)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.platformErrorFilterOpen),
                  selected: _openOnly,
                  onSelected: (v) => setState(() => _openOnly = v),
                ),
                const SizedBox(width: 6),
                for (final s in PlatformErrorSeverity.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.name),
                      selected: _severity == s,
                      onSelected: (_) => setState(
                        () => _severity = _severity == s ? null : s,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PlatformSystemError>>(
              stream: _service.watchErrors(
                severity: _severity,
                openOnly: _openOnly ? true : null,
                companyId: _companyFilter,
              ),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${l10n.error}: ${snap.error}'));
                }
                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return Center(child: Text(l10n.platformErrorEmpty));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final errorColMax =
                        (constraints.maxWidth * 0.36).clamp(140.0, 320.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(l10n.platformErrorColSeverity)),
                            DataColumn(label: Text(l10n.platformErrorColCount)),
                            DataColumn(label: Text(l10n.companyDetails)),
                            DataColumn(label: Text(l10n.platformErrorColOperation)),
                            DataColumn(label: Text(l10n.error)),
                            DataColumn(label: Text(l10n.platformErrorColFirstSeen)),
                            DataColumn(label: Text(l10n.platformErrorColLastSeen)),
                            DataColumn(label: Text(l10n.status)),
                          ],
                          rows: rows.map((e) {
                            return DataRow(
                              onSelectChanged: (_) => _openDetail(e),
                              cells: [
                                DataCell(
                                  Chip(
                                    label: Text(
                                      severityToString(e.severity),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: _severityColor(e.severity),
                                  ),
                                ),
                                DataCell(Text('${e.occurrences}')),
                                DataCell(Text(e.companyName ?? e.companyId ?? '—')),
                                DataCell(Text(e.operation ?? '—')),
                                DataCell(
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: errorColMax),
                                    child: Text(
                                      e.errorMessage,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppTheme.text,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                  e.firstSeen != null
                                      ? _fmt.format(e.firstSeen!)
                                      : '—',
                                )),
                                DataCell(Text(
                                  e.lastSeen != null
                                      ? _fmt.format(e.lastSeen!)
                                      : '—',
                                )),
                                DataCell(Text(
                                  e.resolved
                                      ? l10n.platformErrorResolved
                                      : l10n.platformErrorOpen,
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(PlatformSystemError error) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformErrorDetailScreen(error: error),
      ),
    );
  }
}
