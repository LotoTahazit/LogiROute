import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../utils/file_download_stub.dart'
    if (dart.library.html) '../../../../utils/file_download_web.dart';

import '../../../../core/navigation/document_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/cross_module_audit_service.dart';
import '../../models/audit_event.dart';
import '../../models/member_with_user.dart';
import '../../repositories/audit_repository.dart';
import '../../repositories/members_repository.dart';

/// Секция «Аудит и соответствие» Owner Dashboard.
///
/// Отображает:
/// - Журнал аудита в хронологическом порядке (новые сверху)
/// - Фильтрация: по модулю, типу события, пользователю, диапазону дат
/// - Для каждой записи: тип, модуль, пользователь, дата/время, сущность
/// - Визуальное выделение immutable-полей (createdAt, createdBy)
/// - Кнопка экспорта в CSV
/// - Read-only: owner не может редактировать/удалять записи
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7
class AuditSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const AuditSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<AuditSection> createState() => _AuditSectionState();
}

class _AuditSectionState extends State<AuditSection> {
  late final AuditRepository _auditRepository;
  late final MembersRepository _membersRepository;

  // Filter state
  String? _selectedModule;
  String? _selectedType;
  String? _selectedUser; // UID
  DateTimeRange? _dateRange;

  List<MemberWithUser> _auditableMembers = [];
  bool _isExporting = false;

  // Roles that actually generate audit events (no driver, no super_admin)
  static const _auditableRoles = {
    'admin',
    'owner',
    'dispatcher',
    'accountant',
    'warehouse_keeper',
  };

  static const _moduleOptions = [
    'logistics',
    'warehouse',
    'accounting',
    'dispatcher',
  ];

  String _moduleLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'logistics':
        return l10n.moduleLogistics;
      case 'warehouse':
        return l10n.moduleWarehouse;
      case 'accounting':
        return l10n.moduleAccounting;
      case 'dispatcher':
        return l10n.moduleDispatcher;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _auditRepository = AuditRepository(companyId: widget.companyId);
    _membersRepository = MembersRepository(companyId: widget.companyId);
    _membersRepository.watchMembers().listen((members) {
      if (mounted) {
        setState(() {
          _auditableMembers = members
              .where((m) => _auditableRoles.contains(m.role.value))
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
        });
      }
    });
  }

  AuditFilter get _currentFilter => AuditFilter(
        moduleKey: _selectedModule,
        type: _selectedType,
        createdBy: _selectedUser,
        from: _dateRange?.start,
        to: _dateRange?.end,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filters bar
        _buildFiltersBar(context),
        const Divider(height: 1),
        // Audit log list
        Expanded(child: _buildAuditLog(context)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filters — Requirement 8.2
  // ---------------------------------------------------------------------------

  Widget _buildFiltersBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.of(context).size.width < 400;
    final padding = EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 16, vertical: narrow ? 8 : 12);

    final moduleDropdown = DropdownButtonFormField<String>(
      value: _selectedModule,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.moduleFilter,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.all)),
        ..._moduleOptions.map((m) => DropdownMenuItem(
              value: m,
              child:
                  Text(_moduleLabel(m, l10n), overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedModule = v),
    );

    final typeDropdown = DropdownButtonFormField<String>(
      value: _selectedType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.eventTypeFilter,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.all)),
        ...CrossModuleAuditService.allTypes.map((t) => DropdownMenuItem(
              value: t,
              child: Text(_typeLabel(t, l10n), overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedType = v),
    );

    final userDropdown = DropdownButtonFormField<String>(
      value: _selectedUser,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.userFilter,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.all)),
        ..._auditableMembers.map((m) => DropdownMenuItem(
              value: m.uid,
              child: Text(
                m.displayName.isNotEmpty ? m.displayName : m.email,
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: (v) => setState(() => _selectedUser = v),
    );

    final dateChip = ActionChip(
      avatar: const Icon(Icons.date_range, size: 18),
      label: Text(
        _dateRange != null
            ? '${DateFormat('dd/MM').format(_dateRange!.start)} — ${DateFormat('dd/MM').format(_dateRange!.end)}'
            : l10n.dateRange,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () => _pickDateRange(context),
    );

    final exportBtn = FilledButton.icon(
      onPressed: _isExporting ? null : () => _exportCsv(context),
      icon: _isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download, size: 18),
      label: Text(_isExporting ? l10n.exporting : l10n.exportCsv),
    );

    if (narrow) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            moduleDropdown,
            const SizedBox(height: 8),
            typeDropdown,
            const SizedBox(height: 8),
            userDropdown,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: dateChip),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: l10n.clearDateRange,
                    onPressed: () => setState(() => _dateRange = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            exportBtn,
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 160, child: moduleDropdown),
          SizedBox(width: 200, child: typeDropdown),
          SizedBox(width: 200, child: userDropdown),
          dateChip,
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: l10n.clearDateRange,
              onPressed: () => setState(() => _dateRange = null),
            ),
          exportBtn,
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      initialDateRange: _dateRange,
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final csv = await _auditRepository.exportToCsv(_currentFilter);
      if (kIsWeb) {
        final filename =
            'audit_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.csv';
        downloadCsv(csv, filename);
      } else {
        await Clipboard.setData(ClipboardData(text: csv));
      }
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.csvCopiedToClipboard)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.auditExportError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Audit Log — Requirements 8.1, 8.3, 8.4, 8.6, 8.7
  // ---------------------------------------------------------------------------

  Widget _buildAuditLog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<CrossModuleAuditEvent>>(
      stream: _auditRepository.watchAuditLog(filter: _currentFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(l10n.auditLogLoadError,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 56, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(l10n.noAuditRecords,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          );
        }

        // Build UID → display name map for human-readable user names
        final userNames = <String, String>{};
        for (final m in _auditableMembers) {
          userNames[m.uid] = m.displayName;
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _AuditEventTile(
            event: events[index],
            userNames: userNames,
            companyId: widget.companyId,
          ),
        );
      },
    );
  }

  static String _typeLabel(String type, AppLocalizations l10n) {
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
      case 'invoice_issued':
        return l10n.eventInvoiceIssued;
      case 'invoice_printed':
        return l10n.eventInvoicePrinted;
      case 'inventory_adjusted':
        return l10n.eventInventoryAdjusted;
      case 'inventory_count_completed':
        return l10n.eventInventoryCountCompleted;
      case 'inventory_count_approved':
        return l10n.eventInventoryCountApproved;
      case 'route_published':
        return l10n.eventRoutePublished;
      case 'delivery_point_status_changed':
        return l10n.eventDeliveryPointStatusChanged;
      case 'manual_assignment':
        return l10n.eventManualAssignment;
      case 'payment_received':
        return l10n.eventPaymentReceived;
      case 'module_changed':
        return l10n.eventModuleChanged;
      case 'plan_changed':
        return l10n.eventPlanChanged;
      case 'backup_recorded':
        return l10n.eventBackupRecorded;
      case 'retention_checked':
        return l10n.eventRetentionChecked;
      default:
        return type;
    }
  }
}

// =============================================================================
// Private widgets
// =============================================================================

/// Строка аудит-лога с визуальным выделением immutable-полей.
///
/// Immutable поля (createdAt, createdBy) выделены цветом и иконкой замка (Req 8.4).
/// Кликабельна — показывает диалог с полными деталями события.
/// [userNames] — map UID → отображаемое имя пользователя.
class _AuditEventTile extends StatelessWidget {
  final CrossModuleAuditEvent event;
  final Map<String, String> userNames;
  final String companyId;
  const _AuditEventTile({
    required this.event,
    required this.userNames,
    required this.companyId,
  });

  static final _timeFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _timeOnlyFmt = DateFormat('HH:mm:ss');

  /// Resolve UID → human-readable name, fallback to "system" or short UID.
  String _resolveUser(String uid) {
    if (uid == 'system') return 'מערכת';
    if (userNames.containsKey(uid)) return userNames[uid]!;
    // Show shortened UID as last resort
    return uid.length > 10 ? '${uid.substring(0, 6)}…' : uid;
  }

  /// Translate entity collection to human-readable label.
  String _collectionLabel(String collection, AppLocalizations l10n) {
    switch (collection) {
      case 'invoices':
        return l10n.invoicesTab;
      case 'creditNotes':
        return l10n.creditNotes;
      case 'deliveryNotes':
        return l10n.deliveryNotesReport;
      case 'receipts':
        return l10n.receiptsReport;
      case 'inventory':
        return l10n.warehouseInventory;
      case 'routes':
        return l10n.routes;
      case 'deliveryPoints':
        return l10n.deliveryPoints;
      default:
        return collection;
    }
  }

  /// Translate module key to human-readable label.
  String _moduleLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'logistics':
        return l10n.moduleLogistics;
      case 'warehouse':
        return l10n.moduleWarehouse;
      case 'accounting':
        return l10n.moduleAccounting;
      case 'dispatcher':
        return l10n.moduleDispatcher;
      default:
        return key;
    }
  }

  /// Translate extra field keys to readable labels.
  String _extraKeyLabel(String key) {
    switch (key) {
      case 'docNumber':
        return 'מס׳ מסמך';
      case 'customerName':
        return 'לקוח';
      case 'amount':
      case 'gross':
        return 'סכום';
      case 'reason':
        return 'סיבה';
      case 'status':
        return 'סטטוס';
      case 'oldStatus':
        return 'סטטוס קודם';
      case 'newStatus':
        return 'סטטוס חדש';
      case 'driverName':
        return 'נהג';
      case 'pointCount':
        return 'נקודות';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = _AuditSectionState._typeLabel(event.type, l10n);
    final userName = _resolveUser(event.createdBy);
    final moduleLbl = _moduleLabel(event.moduleKey, l10n);
    final collectionLbl = _collectionLabel(event.entity.collection, l10n);

    final dateStr =
        event.createdAt != null ? _dateFmt.format(event.createdAt!) : '—';
    final timeStr =
        event.createdAt != null ? _timeOnlyFmt.format(event.createdAt!) : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () => _openDocument(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: type + module badge + info button
              Row(
                children: [
                  _moduleIcon(event.moduleKey, theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      moduleLbl,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (DocumentRouter.isSupported(event.entity.collection)) ...[
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      tooltip: 'פתח בלשונית חדשה',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => DocumentRouter.openInNewTab(
                        context,
                        companyId: companyId,
                        collection: event.entity.collection,
                        docId: event.entity.docId,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 16),
                    tooltip: 'פרטים',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showDetailDialog(context),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 20, color: theme.colorScheme.outline),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: collection label (human-readable)
              Text(
                collectionLbl,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 4),
              // Row 3: immutable fields — date/time + user name
              Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 12, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    '$dateStr $timeStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.person_outline,
                      size: 12, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      userName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fullTimeStr =
        event.createdAt != null ? _timeFmt.format(event.createdAt!) : '—';
    final typeLabel = _AuditSectionState._typeLabel(event.type, l10n);
    final userName = _resolveUser(event.createdBy);
    final moduleLbl = _moduleLabel(event.moduleKey, l10n);
    final collectionLbl = _collectionLabel(event.entity.collection, l10n);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      _moduleIcon(event.moduleKey, theme),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          typeLabel,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Module
                  _labelValue(theme, l10n.moduleFilter, moduleLbl),
                  // Collection (entity type)
                  _labelValue(theme, l10n.eventTypeFilter, collectionLbl),
                  const SizedBox(height: 8),
                  // Created at (immutable)
                  _immutableLabelValue(theme, l10n.dateRange, fullTimeStr),
                  // Created by (immutable)
                  _immutableLabelValue(theme, l10n.userFilter, userName),
                  // Extra details
                  if (event.extra.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    ...event.extra.entries.map(
                      (e) => _labelValue(
                          theme, _extraKeyLabel(e.key), '${e.value}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Label above value — vertical layout for narrow screens.
  Widget _labelValue(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Immutable field — with lock icon, vertical layout.
  Widget _immutableLabelValue(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 12, color: theme.colorScheme.tertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Open the referenced document via DocumentRouter.
  void _openDocument(BuildContext context) {
    if (event.entity.docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אין מזהה מסמך')),
      );
      return;
    }
    DocumentRouter.open(
      context,
      companyId: companyId,
      collection: event.entity.collection,
      docId: event.entity.docId,
    );
  }

  Widget _moduleIcon(String moduleKey, ThemeData theme) {
    final IconData iconData;
    switch (moduleKey) {
      case 'logistics':
        iconData = Icons.local_shipping_outlined;
      case 'warehouse':
        iconData = Icons.warehouse_outlined;
      case 'accounting':
        iconData = Icons.receipt_long_outlined;
      case 'dispatcher':
        iconData = Icons.person_pin_outlined;
      default:
        iconData = Icons.info_outline;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(iconData, size: 18, color: theme.colorScheme.onSurface),
    );
  }
}
