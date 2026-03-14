import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Module filter
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedModule,
              decoration: InputDecoration(
                labelText: l10n.moduleFilter,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.all)),
                ..._moduleOptions.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(_moduleLabel(m, l10n)),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedModule = v),
            ),
          ),
          // Event type filter
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.eventTypeFilter,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.all)),
                ...CrossModuleAuditService.allTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabel(t, l10n)),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedType = v),
            ),
          ),
          // User filter — dropdown with auditable members only
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedUser,
              decoration: InputDecoration(
                labelText: l10n.userFilter,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ),
          ),
          // Date range picker
          ActionChip(
            avatar: const Icon(Icons.date_range, size: 18),
            label: Text(_dateRange != null
                ? '${DateFormat('dd/MM').format(_dateRange!.start)} — ${DateFormat('dd/MM').format(_dateRange!.end)}'
                : l10n.dateRange),
            onPressed: () => _pickDateRange(context),
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: l10n.clearDateRange,
              onPressed: () => setState(() => _dateRange = null),
            ),
          const Spacer(),
          // Export CSV button — Requirement 8.5
          FilledButton.icon(
            onPressed: _isExporting ? null : () => _exportCsv(context),
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 18),
            label: Text(_isExporting ? l10n.exporting : l10n.exportCsv),
          ),
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
      await Clipboard.setData(ClipboardData(text: csv));
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
            child: Text(l10n.noAuditRecords),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _AuditEventTile(event: events[index]),
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
class _AuditEventTile extends StatelessWidget {
  final CrossModuleAuditEvent event;
  const _AuditEventTile({required this.event});

  static final _timeFmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        event.createdAt != null ? _timeFmt.format(event.createdAt!) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module icon
          _moduleIcon(event.moduleKey, theme),
          const SizedBox(width: 12),
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + module
                Row(
                  children: [
                    Text(
                      _AuditSectionState._typeLabel(
                          event.type, AppLocalizations.of(context)!),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.moduleKey,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Entity
                Text(
                  '${event.entity.collection}/${event.entity.docId}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Extra details (Req 8.6)
                if (event.extra.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.extra.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' · '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Immutable fields: createdAt, createdBy — highlighted (Req 8.4)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 12, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 12, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    event.createdBy.length > 8
                        ? '${event.createdBy.substring(0, 8)}…'
                        : event.createdBy,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
