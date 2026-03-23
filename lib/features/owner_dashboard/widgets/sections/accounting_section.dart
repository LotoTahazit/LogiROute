import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../models/accounting_doc.dart';
import '../../repositories/accounting_docs_repository.dart';
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
  late final AccountingDocsRepository _docsRepo;

  AccountingDocType? _filterType;
  AccountingDocStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _docsRepo = AccountingDocsRepository(companyId: widget.companyId);
  }

  AccountingDocFilter get _currentFilter => AccountingDocFilter(
        type: _filterType,
        status: _filterStatus,
      );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 500;
    return StreamBuilder<List<AccountingDoc>>(
      stream: _docsRepo.watchDocs(filter: _currentFilter),
      builder: (context, snapshot) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              // Summary cards — KPIs for accountant
              _buildSummaryCards(context, snapshot),
              const SizedBox(height: 16),
              _buildFilters(context),
              const SizedBox(height: 16),
              _buildDocsList(context, snapshot),
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
      stream: _docsRepo.watchDocs(),
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 500;
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.accountingDocuments,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
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
        const Spacer(),
        FilledButton.icon(
          onPressed: () => _showCreateDocDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.createDocument),
        ),
      ],
    );
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
        itemBuilder: (context, i) => _buildDocCard(context, docs[i]),
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
            DataColumn(label: Text(l10n.columnDate)),
            DataColumn(label: Text(l10n.columnActions)),
          ],
          rows: docs.map((doc) => _buildDocRow(context, doc)).toList(),
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, AccountingDoc doc) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateStr =
        doc.createdAt != null ? dateFmt.format(doc.createdAt!) : '\u2014';
    final statusColor = docStatusColor(doc.status);
    final isClickable = doc.id != null;
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            docTypeLabel(context, doc.type),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(dateStr, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (isClickable)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDocRow(BuildContext context, AccountingDoc doc) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateStr =
        doc.createdAt != null ? dateFmt.format(doc.createdAt!) : '\u2014';
    final statusColor = docStatusColor(doc.status);
    final isImmutable = doc.status != AccountingDocStatus.draft;

    return DataRow(
        onSelectChanged: doc.id != null
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
          DataCell(Text(dateStr)),
          DataCell(_buildActionButtons(context, doc)),
        ]);
  }

  // ---------------------------------------------------------------------------
  // Context-sensitive action buttons per document status
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context, AccountingDoc doc) {
    final l10n = AppLocalizations.of(context)!;
    switch (doc.status) {
      case AccountingDocStatus.draft:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: l10n.editTooltip,
              onPressed: () => _showDocForm(context, doc.type),
            ),
            IconButton(
              icon: const Icon(Icons.publish_outlined, size: 20),
              tooltip: l10n.issueTooltip,
              color: Colors.green,
              onPressed:
                  doc.id != null ? () => _confirmIssueDoc(context, doc) : null,
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, size: 20),
              tooltip: l10n.cancelTooltip,
              color: Colors.red,
              onPressed:
                  doc.id != null ? () => _confirmVoidDoc(context, doc) : null,
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
        await _docsRepo.issueDoc(doc.id!);
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
        await _docsRepo.voidBeforeDelivery(
          doc.id!,
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
        docsRepo: _docsRepo,
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
        docsRepo: _docsRepo,
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
        docsRepo: _docsRepo,
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
