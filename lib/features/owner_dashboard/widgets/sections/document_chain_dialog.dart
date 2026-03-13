import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../models/accounting_doc.dart';
import '../../repositories/accounting_docs_repository.dart';
import 'accounting_helpers.dart';

/// Dialog that displays the chain of related accounting documents.
///
/// Shows: original document → credit note(s) → any related documents.
/// Uses [AccountingDocsRepository.getDocumentChain] to load the chain.
///
/// Requirements: 16.6, 18.4
class DocumentChainDialog extends StatefulWidget {
  final String docId;
  final AccountingDocsRepository docsRepo;
  final AccountingDoc currentDoc;

  const DocumentChainDialog({
    super.key,
    required this.docId,
    required this.docsRepo,
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
    _chainFuture = widget.docsRepo.getDocumentChain(widget.docId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.account_tree_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.documentChainTitle,
                      style: theme.textTheme.titleLarge),
                  const Spacer(),
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
    final dateStr = doc.issuedAt != null
        ? dateFmt.format(doc.issuedAt!)
        : doc.createdAt != null
            ? dateFmt.format(doc.createdAt!)
            : '—';

    final isOriginal = doc.type != AccountingDocType.creditNote &&
        (doc.references?.creditNoteIds?.isNotEmpty ?? false);

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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusClr.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                doc.type == AccountingDocType.creditNote
                    ? Icons.note_add_outlined
                    : Icons.receipt_long_outlined,
                color: statusClr,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        typeLbl,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isOriginal) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
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
                      ],
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
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
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.docNumber != null ? "#${doc.docNumber}" : AppLocalizations.of(context)!.draftStatus}'
                    ' · ${doc.customerName}'
                    ' · ₪${doc.totals.gross.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: 4),
                Text(dateStr, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
