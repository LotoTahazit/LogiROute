import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../features/owner_dashboard/models/audit_event.dart';
import '../../features/owner_dashboard/repositories/audit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../services/access_log_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/cross_module_audit_service.dart';
import '../../utils/file_download_stub.dart'
    if (dart.library.html) '../../utils/file_download_web.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/logi_route_tab_bar.dart';

enum _ActivityPeriod { h24, h48, week }

extension on _ActivityPeriod {
  Duration get duration => switch (this) {
        _ActivityPeriod.h24 => const Duration(hours: 24),
        _ActivityPeriod.h48 => const Duration(hours: 48),
        _ActivityPeriod.week => const Duration(days: 7),
      };

  String label(AppLocalizations l10n) => switch (this) {
        _ActivityPeriod.h24 => l10n.period24h,
        _ActivityPeriod.h48 => l10n.period48h,
        _ActivityPeriod.week => l10n.periodWeek,
      };
}

class _ActivityItem {
  final String actorName;
  final String description;
  final DateTime? timestamp;
  final IconData icon;
  final Color color;
  final String source;

  const _ActivityItem({
    required this.actorName,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.source,
  });
}

/// Admin activity log — who did what and when (24h / 48h / week).
class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  _ActivityPeriod _period = _ActivityPeriod.h24;
  String _search = '';
  bool _isExporting = false;
  Map<String, String> _userNames = {};
  late AuditRepository _auditRepo;
  late AccessLogService _accessLog;
  String? _companyId;
  Future<List<_ActivityItem>>? _itemsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId == _companyId) return;
    _companyId = companyId;
    _itemsFuture = null;
    _auditRepo = AuditRepository(companyId: companyId);
    _accessLog = AccessLogService(companyId: companyId);
    _loadUserNames();
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid != null && companyId.isNotEmpty) {
      _accessLog.logAccess(
        actorUid: uid,
        eventType: AccessEventType.adminAction,
        actorName: auth.userModel?.name,
        metadata: {'action': 'view_activity_log'},
      );
    }
  }

  Future<void> _loadUserNames() async {
    final users = await context.read<AuthService>().getAllUsers();
    if (!mounted) return;
    setState(() {
      _userNames = {for (final u in users) u.uid: u.name};
    });
  }

  DateTime get _fromDate => DateTime.now().subtract(_period.duration);

  Future<List<_ActivityItem>> _loadItems() =>
      _itemsFuture ??= _fetchItems();

  Future<List<_ActivityItem>> _fetchItems() async {
    if (_companyId == null || _companyId!.isEmpty) return [];

    final from = _fromDate;
    final filter = AuditFilter(from: from);

    final results = await Future.wait([
      _auditRepo.getAuditLog(filter: filter, limit: 500),
      _accessLog.getAccessLog(fromDate: from, limit: 500),
    ]);

    final auditEvents = results[0] as List<CrossModuleAuditEvent>;
    final accessLogs = results[1] as List<Map<String, dynamic>>;
    final l10n = AppLocalizations.of(context)!;

    final items = <_ActivityItem>[
      ...auditEvents.map((e) => _fromAudit(e, l10n)),
      ...accessLogs.map((e) => _fromAccess(e, l10n)),
    ];
    items.sort((a, b) {
      final ta = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return items;
  }

  List<_ActivityItem> _filterItems(List<_ActivityItem> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((i) =>
            i.actorName.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q))
        .toList();
  }

  _ActivityItem _fromAudit(CrossModuleAuditEvent e, AppLocalizations l10n) {
    final name = _userNames[e.createdBy] ?? e.createdBy;
    return _ActivityItem(
      actorName: name,
      description: _auditTypeLabel(e.type, l10n),
      timestamp: e.createdAt,
      icon: _auditIcon(e.type),
      color: Colors.indigo,
      source: 'audit',
    );
  }

  _ActivityItem _fromAccess(Map<String, dynamic> log, AppLocalizations l10n) {
    final typeName = log['eventType'] as String? ?? '';
    final type = AccessEventType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => AccessEventType.adminAction,
    );
    final uid = log['actorUid'] as String? ?? '';
    final name = (log['actorName'] as String?)?.trim();
    return _ActivityItem(
      actorName: (name != null && name.isNotEmpty) ? name : (_userNames[uid] ?? uid),
      description: _accessTypeLabel(type, l10n, log),
      timestamp: log['timestamp'] is Timestamp
          ? (log['timestamp'] as Timestamp).toDate()
          : null,
      icon: _accessIcon(type),
      color: Colors.teal,
      source: 'access',
    );
  }

  String _auditTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case CrossModuleAuditService.typeReceiptCreated:
        return l10n.eventReceiptCreated;
      case CrossModuleAuditService.typeCreditNoteCreated:
        return l10n.eventCreditNoteCreated;
      case CrossModuleAuditService.typeDocumentVoided:
        return l10n.eventDocumentVoided;
      case CrossModuleAuditService.typeInvoiceVoided:
        return l10n.eventInvoiceVoided;
      case CrossModuleAuditService.typeBillingStatusChanged:
        return l10n.eventBillingStatusChanged;
      case CrossModuleAuditService.typeTrialUntilChanged:
        return l10n.eventTrialUntilChanged;
      case CrossModuleAuditService.typeAccountingLockedUntilChanged:
        return l10n.eventAccountingLockedUntilChanged;
      default:
        return type;
    }
  }

  IconData _auditIcon(String type) {
    if (type.contains('void') || type.contains('cancel')) {
      return Icons.cancel_outlined;
    }
    if (type.contains('billing') || type.contains('trial') || type.contains('lock')) {
      return Icons.payments;
    }
    if (type.contains('credit')) return Icons.receipt_long;
    return Icons.description_outlined;
  }

  String _accessTypeLabel(
    AccessEventType type,
    AppLocalizations l10n,
    Map<String, dynamic> log,
  ) {
    final base = switch (type) {
      AccessEventType.login => l10n.accessEventLogin,
      AccessEventType.logout => l10n.accessEventLogout,
      AccessEventType.viewDocument => l10n.accessEventViewDocument,
      AccessEventType.printDocument => l10n.accessEventPrintDocument,
      AccessEventType.exportData => l10n.accessEventExportData,
      AccessEventType.createDocument => l10n.accessEventCreateDocument,
      AccessEventType.cancelDocument => l10n.accessEventCancelDocument,
      AccessEventType.viewAuditLog => l10n.accessEventViewAuditLog,
      AccessEventType.viewReport => l10n.accessEventViewReport,
      AccessEventType.adminAction => l10n.accessEventAdminAction,
    };
    final target = log['targetEntityType'] as String?;
    final id = log['targetEntityId'] as String?;
    if (target != null && id != null) return '$base ($target #$id)';
    return base;
  }

  IconData _accessIcon(AccessEventType type) => switch (type) {
        AccessEventType.login => Icons.login,
        AccessEventType.logout => Icons.logout,
        AccessEventType.viewDocument => Icons.visibility,
        AccessEventType.printDocument => Icons.print,
        AccessEventType.exportData => Icons.download,
        AccessEventType.createDocument => Icons.add_circle_outline,
        AccessEventType.cancelDocument => Icons.block,
        AccessEventType.viewAuditLog => Icons.history,
        AccessEventType.viewReport => Icons.assessment,
        AccessEventType.adminAction => Icons.admin_panel_settings,
      };

  Future<void> _exportCsv(List<_ActivityItem> items) async {
    setState(() => _isExporting = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      const t = '\t';
      final buffer = StringBuffer()
        ..writeln(
            '${l10n.activityCsvUser}$t${l10n.activityCsvAction}$t${l10n.activityCsvWhen}$t${l10n.activityCsvSource}');
      for (final i in items) {
        final when =
            i.timestamp != null ? _dateFmt.format(i.timestamp!) : '';
        buffer.writeln('${i.actorName}$t${i.description}$t$when$t${i.source}');
      }
      final csv = buffer.toString();
      if (kIsWeb) {
        downloadCsv(csv, 'activity_log.xls');
      } else {
        await Clipboard.setData(ClipboardData(text: csv));
        if (mounted) SnackbarHelper.showSuccess(context, l10n.csvCopiedToClipboard);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          AppLocalizations.of(context)!.auditExportError('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildListBody(
    AppLocalizations l10n,
    AsyncSnapshot<List<_ActivityItem>> snapshot,
    List<_ActivityItem> items,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Text('${l10n.auditLogLoadError}: ${snapshot.error}'),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noActivityEvents,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _itemsFuture = null);
        await _loadItems();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final ts = item.timestamp;
          final timeStr = ts != null ? _dateFmt.format(ts) : '—';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: item.color.withValues(alpha: 0.15),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            title: Text(
              item.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${item.actorName} • $timeStr',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Tooltip(
              message: item.source == 'audit'
                  ? l10n.auditSourceLabel
                  : l10n.accessSourceLabel,
              child: Icon(
                item.source == 'audit'
                    ? Icons.verified_user
                    : Icons.fingerprint,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthService>();
    final isRtl = Localizations.localeOf(context).languageCode == 'he';

    if (auth.userModel?.isAdmin != true) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.adminActivityLog)),
          body: Center(child: Text(l10n.noPermissionToEdit)),
        ),
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: FutureBuilder<List<_ActivityItem>>(
        future: _loadItems(),
        builder: (context, snapshot) {
          final items = _filterItems(snapshot.data ?? []);
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.adminActivityLog),
              backgroundColor: Colors.blue,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LogiRoutePillSelector(
                        labels: _ActivityPeriod.values
                            .map((p) => p.label(l10n))
                            .toList(),
                        selectedIndex: _ActivityPeriod.values.indexOf(_period),
                        onSelected: (i) => setState(() {
                          _period = _ActivityPeriod.values[i];
                          _itemsFuture = null;
                        }),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: l10n.searchActivityHint,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildListBody(l10n, snapshot, items)),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _isExporting || items.isEmpty
                  ? null
                  : () => _exportCsv(items),
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting ? l10n.exporting : l10n.exportCsv,
              ),
            ),
          );
        },
      ),
    );
  }
}
