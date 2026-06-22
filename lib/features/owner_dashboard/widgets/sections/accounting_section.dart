import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/accounting_sync_service.dart';
import '../../../../services/invoice_service.dart';
import '../../../../services/issuance_service.dart';
import '../../../../utils/accounting_period_lock.dart';
import '../../../../widgets/accounting_sync_panel.dart';
import '../../../../widgets/logi_route_tab_bar.dart';
import '../../models/accounting_doc.dart';
import '../credit_note_form.dart';
import 'accounting_helpers.dart';
import 'create_doc_form_dialog.dart';
import 'document_chain_dialog.dart';

/// Секция «Бухгалтерия» Owner Dashboard.
///
/// Отображает:
/// - Список бухгалтерских документов с фильтрацией по типу и статусу
/// - Для каждого документа: тип, номер, клиент, сумма (gross), статус, дата
/// - Кнопка «Создать документ» → форма выбора типа и создания документа
/// - Форма создания: клиент, строки (description, quantity, unitPrice, vatRate),
///   итоги (автоматический расчёт net/vat/gross), заметки
///
/// Requirements: 14.2, 14.3, 15.7
class AccountingSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const AccountingSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<AccountingSection> createState() => _AccountingSectionState();
}

class _AccountingSectionState extends State<AccountingSection> {
  late final InvoiceService _invoiceService;
  late final AccountingSyncService _syncService;

  AccountingDocType? _filterType;
  AccountingDocStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService(companyId: widget.companyId);
    _syncService = AccountingSyncService(companyId: widget.companyId);
  }

  AccountingDocFilter get _currentFilter => AccountingDocFilter(
        type: _filterType,
        status: _filterStatus,
      );

  bool get _hasExternalAccounting {
    final p = widget.companySettings.accountingProvider;
    return p == 'greeninvoice' || p == 'icount' || p == 'export';
  }

  DateTime? get _accountingLockedUntil =>
      widget.companySettings.accountingLockedUntil;

  bool _isDocPeriodLocked(AccountingDoc doc) {
    final lock = _accountingLockedUntil;
    final date = doc.deliveryDate;
    if (lock == null || date == null) return false;
    return AccountingPeriodLock.isLocked(date, lock);
  }

  void _showPeriodLockedSnack(BuildContext context, AccountingDoc doc) {
    final l10n = AppLocalizations.of(context)!;
    final lock = _accountingLockedUntil!;
    final date = doc.deliveryDate ?? doc.createdAt ?? DateTime.now();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.invoicePeriodLockedError(
          DateFormat('dd/MM/yyyy').format(date),
          DateFormat('dd/MM/yyyy').format(lock),
        )),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 500;
    return StreamBuilder<List<AccountingDoc>>(
      stream: _invoiceService.watchAccountingDocs(filter: _currentFilter),
      builder: (context, snapshot) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              if (_accountingLockedUntil != null) ...[
                const SizedBox(height: 12),
                _buildPeriodLockBanner(context, snapshot.data ?? []),
              ],
              const SizedBox(height: 16),
              if (_hasExternalAccounting) ...[
                AccountingSyncPanel(companyId: widget.companyId),
                const SizedBox(height: 16),
              ],
              // Summary cards — KPIs for accountant
              _buildSummaryCards(context, snapshot),
              const SizedBox(height: 16),
              _buildStatusChips(context, snapshot.data ?? []),
              const SizedBox(height: 12),
              _buildFilters(context),
              const SizedBox(height: 16),
              StreamBuilder<Map<String, AccountingSyncEntry>>(
                stream: _hasExternalAccounting
                    ? _syncService.watchLedgerMap()
                    : Stream.value(const {}),
                builder: (context, syncSnap) {
                  return _buildDocsList(
                    context,
                    snapshot,
                    syncSnap.data ?? const {},
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Summary KPI cards
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCards(
    BuildContext context,
    AsyncSnapshot<List<AccountingDoc>> snapshot,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Use ALL docs (unfiltered) for summary — listen to a separate unfiltered stream
    return StreamBuilder<List<AccountingDoc>>(
      stream: _invoiceService.watchAccountingDocs(),
      builder: (context, allSnapshot) {
        final allDocs = allSnapshot.data ?? [];

        // Calculate KPIs
        final issuedDocs = allDocs
            .where((d) =>
                d.status != AccountingDocStatus.draft &&
                d.status != AccountingDocStatus.voidedBeforeDelivery)
            .toList();
        final totalRevenue =
            issuedDocs.fold<double>(0, (sum, d) => sum + d.totals.gross);
        final totalVat =
            issuedDocs.fold<double>(0, (sum, d) => sum + d.totals.vat);
        final totalNet =
            issuedDocs.fold<double>(0, (sum, d) => sum + d.totals.net);
        final draftCount =
            allDocs.where((d) => d.status == AccountingDocStatus.draft).length;
        final creditNotes = allDocs
            .where((d) => d.type == AccountingDocType.creditNote)
            .toList();
        final creditTotal =
            creditNotes.fold<double>(0, (sum, d) => sum + d.totals.gross);

        final narrow = MediaQuery.sizeOf(context).width < 500;
        final cardWidth = narrow ? double.infinity : 220.0;
        final cards = [
          _SummaryCard(
            width: cardWidth,
            icon: Icons.receipt_long,
            iconColor: Colors.blue,
            title: l10n.issuedDocuments,
            value: '${issuedDocs.length}',
            subtitle: l10n.draftsCount(draftCount),
          ),
          _SummaryCard(
            width: cardWidth,
            icon: Icons.payments,
            iconColor: Colors.green,
            title: l10n.totalRevenueGross,
            value: '\u20AA${formatCurrency(totalRevenue)}',
            subtitle: l10n.netLabel(formatCurrency(totalNet)),
          ),
          _SummaryCard(
            width: cardWidth,
            icon: Icons.account_balance,
            iconColor: Colors.orange,
            title: l10n.vatPercent,
            value: '\u20AA${formatCurrency(totalVat)}',
            subtitle: l10n.forTaxAuthorities,
          ),
          _SummaryCard(
            width: cardWidth,
            icon: Icons.note_add,
            iconColor: Colors.red,
            title: l10n.creditNotes,
            value: '${creditNotes.length}',
            subtitle: '\u20AA${formatCurrency(creditTotal)}',
          ),
        ];
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header with title and create button
  // ---------------------------------------------------------------------------

  Widget _buildPeriodLockBanner(
      BuildContext context, List<AccountingDoc> docs) {
    final l10n = AppLocalizations.of(context)!;
    final lock = _accountingLockedUntil!;
    final lockedDrafts = docs
        .where((d) =>
            d.status == AccountingDocStatus.draft && _isDocPeriodLocked(d))
        .length;
    return MaterialBanner(
      backgroundColor: Colors.orange.withValues(alpha: 0.12),
      leading: const Icon(Icons.lock_clock, color: Colors.orange),
      content: Text(
        '${l10n.accountingPeriodLockDesc} '
        '(${DateFormat('dd/MM/yyyy').format(lock)})'
        '${lockedDrafts > 0 ? ' · ${l10n.draftsCount(lockedDrafts)}' : ''}',
      ),
      actions: const [SizedBox.shrink()],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 500;
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 24, color: theme.colorScheme.primary),
              Text(
                l10n.accountingDocuments,
                style: theme.textTheme.titleLarge,
              ),
              if (_hasExternalAccounting)
                Chip(
                  label: Text(
                    _providerLabel(l10n),
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _showCreateDocDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.createDocument),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.receipt_long_outlined,
            size: 28, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(l10n.accountingDocuments, style: theme.textTheme.headlineSmall),
        if (_hasExternalAccounting) ...[
          const SizedBox(width: 8),
          Chip(
            label: Text(_providerLabel(l10n),
                style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
          ),
        ],
        const Spacer(),
        FilledButton.icon(
          onPressed: () => _showCreateDocDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.createDocument),
        ),
      ],
    );
  }

  String _providerLabel(AppLocalizations l10n) {
    switch (widget.companySettings.accountingProvider) {
      case 'greeninvoice':
        return l10n.accountingProviderGreeninvoice;
      case 'icount':
        return l10n.accountingProviderIcount;
      case 'export':
        return l10n.accountingProviderExport;
      default:
        return l10n.accountingProviderNone;
    }
  }

  Widget _buildStatusChips(BuildContext context, List<AccountingDoc> docs) {
    final l10n = AppLocalizations.of(context)!;
    final counts = <AccountingDocStatus, int>{};
    for (final s in AccountingDocStatus.values) {
      counts[s] = docs.where((d) => d.status == s).length;
    }

    final statuses = <AccountingDocStatus?>[null, ...AccountingDocStatus.values];
    final labels = statuses
        .map((s) => s == null
            ? '${l10n.allFilter} (${docs.length})'
            : '${docStatusLabel(context, s)} (${counts[s] ?? 0})')
        .toList();

    return LogiRoutePillSelector(
      labels: labels,
      selectedIndex: statuses.indexOf(_filterStatus),
      onSelected: (i) => setState(() => _filterStatus = statuses[i]),
    );
  }

  Widget _buildSyncBadge(
    BuildContext context,
    AccountingDoc doc,
    Map<String, AccountingSyncEntry> syncMap,
  ) {
    if (!_hasExternalAccounting || doc.id == null) {
      return const SizedBox.shrink();
    }
    if (doc.status == AccountingDocStatus.draft) {
      return Text(
        externalSyncLabel(context, null),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      );
    }
    final entry = syncMap[doc.id!];
    final status = entry?.status;
    final color = externalSyncColor(status);
    final extNumber =
        doc.externalDocNumber ?? entry?.externalNumber;
    final pdfUrl = doc.externalPdfUrl ?? entry?.pdfUrl;
    final alloc = doc.externalDistributionNumber ?? entry?.distributionNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                externalSyncLabel(context, status),
                style: TextStyle(color: color, fontSize: 11),
              ),
            ),
            if (status == 'failed')
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                tooltip: AppLocalizations.of(context)!.accountingSyncRetry,
                onPressed: () => _retrySync(context, doc.id!),
              ),
            if (pdfUrl != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                tooltip: 'PDF',
                onPressed: () => launchUrl(
                  Uri.parse(pdfUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
        if (extNumber != null && extNumber.isNotEmpty)
          Text(
            AppLocalizations.of(context)!.accountingExternalDocNumber(extNumber),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        if (alloc != null && alloc.isNotEmpty)
          Text(
            AppLocalizations.of(context)!.accountingSyncDistribution(alloc),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
      ],
    );
  }

  Future<void> _retrySync(BuildContext context, String docId) async {
    try {
      await _syncService.retry(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.accountingSyncRetried),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Filters — type and status dropdowns
  // ---------------------------------------------------------------------------

  Widget _buildFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 500;
    final typeDropdown = DropdownButtonFormField<AccountingDocType?>(
      key: ValueKey(_filterType),
      initialValue: _filterType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.documentType,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.allFilter)),
        ...AccountingDocType.values.map(
          (t) => DropdownMenuItem(
            value: t,
            child:
                Text(docTypeLabel(context, t), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _filterType = value),
    );
    final statusDropdown = DropdownButtonFormField<AccountingDocStatus?>(
      key: ValueKey(_filterStatus),
      initialValue: _filterStatus,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.columnStatus,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.allFilter)),
        ...AccountingDocStatus.values.map(
          (s) => DropdownMenuItem(
            value: s,
            child: Text(docStatusLabel(context, s),
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _filterStatus = value),
    );
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          typeDropdown,
          const SizedBox(height: 8),
          statusDropdown,
        ],
      );
    }
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        SizedBox(width: 200, child: typeDropdown),
        SizedBox(width: 200, child: statusDropdown),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Documents list / table
  // ---------------------------------------------------------------------------

  Widget _buildDocsList(
    BuildContext context,
    AsyncSnapshot<List<AccountingDoc>> snapshot,
    Map<String, AccountingSyncEntry> syncMap,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.errorLoadingDocuments,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    final docs = snapshot.data ?? [];
    if (docs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(child: Text(AppLocalizations.of(context)!.noDocuments)),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 500;
    if (narrow) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _buildDocCard(context, docs[i], syncMap),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: [
            DataColumn(label: Text(l10n.columnType)),
            DataColumn(label: Text(l10n.columnNumber)),
            DataColumn(label: Text(l10n.columnCustomer)),
            DataColumn(label: Text(l10n.columnAmount), numeric: true),
            DataColumn(label: Text(l10n.columnStatus)),
            if (_hasExternalAccounting)
              DataColumn(label: Text(l10n.accountingDocSyncColumn)),
            DataColumn(label: Text(l10n.columnDate)),
            DataColumn(label: Text(l10n.columnActions)),
          ],
          rows: docs.map((doc) => _buildDocRow(context, doc, syncMap)).toList(),
        ),
      ),
    );
  }

  Widget _buildDocCard(
    BuildContext context,
    AccountingDoc doc,
    Map<String, AccountingSyncEntry> syncMap,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateStr =
        doc.createdAt != null ? dateFmt.format(doc.createdAt!) : '\u2014';
    final statusColor = docStatusColor(doc.status);
    final isClickable = doc.id != null && doc.isOwnerManaged;
    final narrow = MediaQuery.sizeOf(context).width < 500;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            isClickable ? () => _showDocumentChainDialog(context, doc) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: narrow ? 260 : 420,
                    ),
                    child: Text(
                      docTypeLabel(context, doc.type),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      docStatusLabel(context, doc.status),
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                doc.customerName,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    doc.docNumber != null
                        ? '#${doc.docNumber}'
                        : l10n.draftStatus,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '₪${doc.totals.gross.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildSyncBadge(context, doc, syncMap),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(child: Text(dateStr, style: theme.textTheme.bodySmall)),
                  if (isClickable)
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.outline,
                      size: 24,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDocRow(
    BuildContext context,
    AccountingDoc doc,
    Map<String, AccountingSyncEntry> syncMap,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateStr =
        doc.createdAt != null ? dateFmt.format(doc.createdAt!) : '\u2014';
    final statusColor = docStatusColor(doc.status);
    final isImmutable = doc.status != AccountingDocStatus.draft;

    return DataRow(
        onSelectChanged: doc.id != null && doc.isOwnerManaged
            ? (_) => _showDocumentChainDialog(context, doc)
            : null,
        cells: [
          DataCell(Text(docTypeLabel(context, doc.type))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(doc.docNumber?.toString() ?? l10n.draftStatus),
              if (isImmutable) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: l10n.immutableFieldsTooltip,
                  child:
                      Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
                ),
              ],
            ],
          )),
          DataCell(Text(doc.customerName)),
          DataCell(Text('₪${doc.totals.gross.toStringAsFixed(2)}')),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                docStatusLabel(context, doc.status),
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
          ),
          if (_hasExternalAccounting)
            DataCell(_buildSyncBadge(context, doc, syncMap)),
          DataCell(Text(dateStr)),
          DataCell(_buildActionButtons(context, doc)),
        ]);
  }

  // ---------------------------------------------------------------------------
  // Context-sensitive action buttons per document status
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context, AccountingDoc doc) {
    final l10n = AppLocalizations.of(context)!;
    if (!doc.isOwnerManaged) {
      return Tooltip(
        message: l10n.dispatcher,
        child: Icon(Icons.local_shipping_outlined, size: 20, color: Colors.grey.shade600),
      );
    }
    final periodLocked = _isDocPeriodLocked(doc);
    switch (doc.status) {
      case AccountingDocStatus.draft:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (periodLocked)
              Tooltip(
                message: l10n.accountingPeriodLockDesc,
                child: Icon(Icons.lock, size: 18, color: Colors.orange.shade700),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: l10n.editTooltip,
              onPressed: periodLocked
                  ? null
                  : () => _showDocForm(context, doc.type),
            ),
            IconButton(
              icon: const Icon(Icons.publish_outlined, size: 20),
              tooltip: l10n.issueTooltip,
              color: Colors.green,
              onPressed: doc.id != null && !periodLocked
                  ? () => _confirmIssueDoc(context, doc)
                  : periodLocked
                      ? () => _showPeriodLockedSnack(context, doc)
                      : null,
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, size: 20),
              tooltip: l10n.cancelTooltip,
              color: Colors.red,
              onPressed: doc.id != null && !periodLocked
                  ? () => _confirmVoidDoc(context, doc)
                  : periodLocked
                      ? () => _showPeriodLockedSnack(context, doc)
                      : null,
            ),
          ],
        );
      case AccountingDocStatus.issued:
      case AccountingDocStatus.locked:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: Text(l10n.createCreditNote,
                  style: const TextStyle(fontSize: 12)),
              onPressed: doc.id != null
                  ? () => _onCreateCreditNote(context, doc)
                  : null,
            ),
          ],
        );
      case AccountingDocStatus.credited:
      case AccountingDocStatus.voidedBeforeDelivery:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // Confirmation dialogs for Issue and Void actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmIssueDoc(BuildContext context, AccountingDoc doc) async {
    if (_isDocPeriodLocked(doc)) {
      _showPeriodLockedSnack(context, doc);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.issueDocumentTitle),
        content: Text(l10n.issueDocumentConfirm(doc.customerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.issueButton),
          ),
        ],
      ),
    );

    if (confirmed == true && doc.id != null && mounted) {
      try {
        await IssuanceService().issueDocument(
          companyId: widget.companyId,
          invoiceId: doc.id!,
          counterKey: doc.type.canonicalCounterKey,
        );
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.documentIssuedSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.errorIssuingDocument(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _confirmVoidDoc(BuildContext context, AccountingDoc doc) async {
    if (_isDocPeriodLocked(doc)) {
      _showPeriodLockedSnack(context, doc);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.voidDocumentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.voidDocumentConfirm(doc.customerName)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.voidReasonLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.voidReasonRequired)),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(l10n.voidDocumentButton),
          ),
        ],
      ),
    );

    if (confirmed == true && doc.id != null && mounted) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        await _invoiceService.voidDraftInvoice(
          doc.id!,
          uid,
          reasonController.text.trim(),
        );
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.documentVoidedSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.errorVoidingDocument(e.toString()))),
          );
        }
      }
    }
    reasonController.dispose();
  }

  // ---------------------------------------------------------------------------
  // Document chain dialog — shows related documents (original → credit notes)
  // ---------------------------------------------------------------------------

  void _showDocumentChainDialog(BuildContext context, AccountingDoc doc) {
    if (doc.id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => DocumentChainDialog(
        docId: doc.id!,
        invoiceService: _invoiceService,
        currentDoc: doc,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Credit Note creation — opens CreditNoteFormDialog (task 26.1)
  // ---------------------------------------------------------------------------

  void _onCreateCreditNote(BuildContext context, AccountingDoc doc) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreditNoteFormDialog(
        originalDoc: doc,
        invoiceService: _invoiceService,
        companyId: widget.companyId,
        accountingLockedUntil: _accountingLockedUntil,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Create document dialog — type selection then form
  // ---------------------------------------------------------------------------

  void _showCreateDocDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => CreateDocTypeDialog(
        onTypeSelected: (type) {
          Navigator.of(ctx).pop();
          _showDocForm(context, type);
        },
      ),
    );
  }

  void _showDocForm(BuildContext context, AccountingDocType type) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateDocFormDialog(
        docType: type,
        companyId: widget.companyId,
        invoiceService: _invoiceService,
        accountingLockedUntil: _accountingLockedUntil,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers — labels and colors (moved to accounting_helpers.dart)
  // ---------------------------------------------------------------------------
}

// =============================================================================
// Summary KPI card widget
// =============================================================================

class _SummaryCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    this.width = 220,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
