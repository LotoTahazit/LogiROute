import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/invoice_service.dart';
import '../../models/accounting_doc.dart';
import 'accounting_helpers.dart';

/// Dialog that displays the chain of related accounting documents.
///
/// Shows: original document → credit note(s) → any related documents.
/// Uses [InvoiceService.getAccountingDocumentChain] to load the chain.
///
/// Requirements: 16.6, 18.4
class DocumentChainDialog extends StatefulWidget {
  final String docId;
  final InvoiceService invoiceService;
  final AccountingDoc currentDoc;

  const DocumentChainDialog({
    super.key,
    required this.docId,
    required this.invoiceService,
    required this.currentDoc,
  });

  @override
  State<DocumentChainDialog> createState() => _DocumentChainDialogState();
}

class _DocumentChainDialogState extends State<DocumentChainDialog> {
  late Future<List<AccountingDoc>> _chainFuture;

  @override
  void initState() {
    super.initState();
    _chainFuture = widget.invoiceService.getAccountingDocumentChain(widget.docId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final narrow = MediaQuery.sizeOf(context).width < 500;
    return Dialog(
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: narrow ? MediaQuery.sizeOf(context).height * 0.85 : 500,
        ),
        child: Padding(
          padding: EdgeInsets.all(narrow ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.account_tree_outlined,
                            color: theme.colorScheme.primary),
                        Text(
                          AppLocalizations.of(context)!.documentChainTitle,
                          style: narrow
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              // Chain content
              Flexible(
                child: FutureBuilder<List<AccountingDoc>>(
                  future: _chainFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            AppLocalizations.of(context)!.errorLoadingChain,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      );
                    }

                    final chain = snapshot.data ?? [];
                    if (chain.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child:
                              Text(AppLocalizations.of(context)!.noRelatedDocs),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: _buildChainView(context, chain),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChainView(BuildContext context, List<AccountingDoc> chain) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    for (int i = 0; i < chain.length; i++) {
      final doc = chain[i];
      final isCurrent = doc.id == widget.docId;

      widgets.add(_buildChainCard(context, doc, isCurrent));

      if (i < chain.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: Icon(Icons.arrow_downward,
                  size: 24, color: theme.colorScheme.outline),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildChainCard(
      BuildContext context, AccountingDoc doc, bool isCurrent) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final statusClr = docStatusColor(doc.status);
    final typeLbl = docTypeLabel(context, doc.type);
    final statusLbl = docStatusLabel(context, doc.status);
    final narrow = MediaQuery.sizeOf(context).width < 500;
    final dateStr = doc.issuedAt != null
        ? dateFmt.format(doc.issuedAt!)
        : doc.createdAt != null
            ? dateFmt.format(doc.createdAt!)
            : '—';

    final isOriginal = doc.type != AccountingDocType.creditNote &&
        (doc.references?.creditNoteIds?.isNotEmpty ?? false);

    final badges = <Widget>[
      if (isOriginal)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            AppLocalizations.of(context)!.originalDocBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      if (isCurrent)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            AppLocalizations.of(context)!.currentDocBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
        ),
    ];

    return Card(
      elevation: isCurrent ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isCurrent
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusClr.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    doc.type == AccountingDocType.creditNote
                        ? Icons.note_add_outlined
                        : Icons.receipt_long_outlined,
                    color: statusClr,
                    size: 20,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: narrow ? 220 : 320),
                  child: Text(
                    typeLbl,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusClr.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLbl,
                    style: TextStyle(color: statusClr, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: badges),
            ],
            const SizedBox(height: 6),
            Text(
              '${doc.docNumber != null ? "#${doc.docNumber}" : AppLocalizations.of(context)!.draftStatus}'
              ' · ${doc.customerName}',
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(dateStr, style: theme.textTheme.bodySmall),
                Text(
                  '₪${doc.totals.gross.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
