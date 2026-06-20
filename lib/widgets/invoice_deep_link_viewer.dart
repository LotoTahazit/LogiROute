import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/invoice.dart';
import '../services/firestore_paths.dart';
import '../l10n/app_localizations.dart';
import '../utils/document_type_labels.dart';

/// Invoice viewer opened via deep-link URL.
class InvoiceDeepLinkViewer extends StatefulWidget {
  final String companyId;
  final String docId;
  final String collection;

  const InvoiceDeepLinkViewer({
    super.key,
    required this.companyId,
    required this.docId,
    this.collection = 'invoices',
  });

  @override
  State<InvoiceDeepLinkViewer> createState() => _InvoiceDeepLinkViewerState();
}

class _InvoiceDeepLinkViewerState extends State<InvoiceDeepLinkViewer> {
  late Future<Invoice?> _future;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '[DeepLink] Opening ${widget.collection}/${widget.docId} company=${widget.companyId}');
    _future = _loadInvoice();
  }

  Future<Invoice?> _loadInvoice() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[DeepLink] Auth not ready, waiting...');
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
      }
      if (user == null) {
        debugPrint('[DeepLink] User not authenticated');
        if (mounted) {
          setState(() => _errorMessage =
              AppLocalizations.of(context)!.loginRequiredFirst);
        }
        return null;
      }
      debugPrint('[DeepLink] Auth OK: ${user.uid}');

      final col = widget.collection;
      final docRef = FirestorePaths()
          .companyDoc(widget.companyId)
          .collection('accounting')
          .doc('_root')
          .collection(col)
          .doc(widget.docId);
      final path = docRef.path;
      debugPrint('[DeepLink] Fetching: $path');

      final doc = await docRef.get();

      debugPrint('[DeepLink] Doc exists: ${doc.exists}');
      if (doc.exists) {
        return Invoice.fromMap(doc.data()!, doc.id);
      } else {
        if (mounted) {
          setState(() => _errorMessage =
              AppLocalizations.of(context)!.documentNotFoundAtPath(path));
        }
      }
    } catch (e, st) {
      debugPrint('[DeepLink] ERROR: $e');
      debugPrint('[DeepLink] Stack: $st');
      if (mounted) {
        setState(() => _errorMessage =
            AppLocalizations.of(context)!.errorWithMessage(e.toString()));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Invoice?>(
      future: _future,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.loadingDocument)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final invoice = snapshot.data;
        if (invoice == null) {
          return _NotFoundScreen(
            docId: widget.docId,
            companyId: widget.companyId,
            errorMessage: _errorMessage,
          );
        }
        return _DetailScreen(invoice: invoice);
      },
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  final String docId;
  final String companyId;
  final String? errorMessage;
  const _NotFoundScreen({
    required this.docId,
    required this.companyId,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.documentNotFound)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMessage ?? l10n.documentNotFoundOrNoAccess,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.docIdLabel(docId),
                style: const TextStyle(color: Colors.grey)),
            Text(l10n.companyLabelColon(companyId),
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.goBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailScreen extends StatelessWidget {
  final Invoice invoice;
  const _DetailScreen({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${invoiceDocTypeLabel(l10n, invoice.documentType)} #${invoice.sequentialNumber}'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(l10n, theme, fmt),
              const SizedBox(height: 16),
              _itemsCard(l10n, theme),
              const SizedBox(height: 16),
              _totalsCard(l10n, theme),
              if (invoice.status == InvoiceStatus.cancelled)
                _cancelledCard(l10n, theme, fmt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(AppLocalizations l10n, ThemeData theme, DateFormat fmt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.receipt_long, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(invoiceDocTypeLabel(l10n, invoice.documentType),
                    style: theme.textTheme.titleLarge),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(invoice.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _statusLabel(l10n, invoice.status),
                  style: TextStyle(
                    color: _statusColor(invoice.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
            const Divider(height: 24),
            _kv(l10n.documentNumberLabel, '#${invoice.sequentialNumber}'),
            _kv(l10n.clientKvLabel, invoice.clientName),
            _kv(l10n.clientNumber, invoice.clientNumber),
            _kv(l10n.addressKvLabel, invoice.address),
            _kv(l10n.driverKvLabel, invoice.driverName),
            _kv(l10n.truckKvLabel, invoice.truckNumber),
            _kv(l10n.deliveryDateKvLabel, fmt.format(invoice.deliveryDate)),
            _kv(l10n.createdAtLabel, fmt.format(invoice.createdAt)),
            _kv(l10n.createdByLabel, invoice.createdBy),
            if (invoice.paymentMethod != null)
              _kv(l10n.paymentMethodLabel, invoice.paymentMethod!),
            if (invoice.assignmentNumber != null)
              _kv(l10n.assignmentNumberLabel, invoice.assignmentNumber!),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.itemsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: [
                  DataColumn(label: Text(l10n.skuColumn)),
                  DataColumn(label: Text(l10n.typeColumn)),
                  DataColumn(label: Text(l10n.numberColumn)),
                  DataColumn(label: Text(l10n.quantityColumn)),
                  DataColumn(label: Text(l10n.priceColumn)),
                  DataColumn(label: Text(l10n.totalColumn)),
                ],
                rows: invoice.items
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item.productCode)),
                          DataCell(Text(item.type)),
                          DataCell(Text(item.number)),
                          DataCell(Text('${item.quantity}')),
                          DataCell(
                              Text('₪${item.pricePerUnit.toStringAsFixed(2)}')),
                          DataCell(Text(
                              '₪${item.totalBeforeVAT.toStringAsFixed(2)}')),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _sumRow(l10n.totalBeforeDiscountLabel,
              '₪${invoice.totalBeforeDiscount.toStringAsFixed(2)}'),
          if (invoice.discount > 0)
            _sumRow(l10n.discountPercentLabel(invoice.discount.round()),
                '-₪${invoice.discountAmount.toStringAsFixed(2)}'),
          _sumRow(l10n.netBeforeVat,
              '₪${invoice.subtotalBeforeVAT.toStringAsFixed(2)}'),
          _sumRow(l10n.vat18Label,
              '₪${invoice.vatAmount.toStringAsFixed(2)}'),
          const Divider(),
          _sumRow(
            l10n.totalToPay,
            '₪${invoice.totalWithVAT.toStringAsFixed(2)}',
            bold: true,
            fontSize: 20,
          ),
        ]),
      ),
    );
  }

  Widget _cancelledCard(
      AppLocalizations l10n, ThemeData theme, DateFormat fmt) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.cancellationDetailsTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.red)),
              ]),
              const SizedBox(height: 8),
              if (invoice.cancelledBy != null)
                _kv(l10n.cancelledByLabel, invoice.cancelledBy!),
              if (invoice.cancelledAt != null)
                _kv(l10n.cancellationDateLabel,
                    fmt.format(invoice.cancelledAt!)),
              if (invoice.cancellationReason != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(l10n.reasonLabel(invoice.cancellationReason!)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  static Widget _sumRow(String label, String value,
      {bool bold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: fontSize,
              )),
        ],
      ),
    );
  }

  static String _statusLabel(AppLocalizations l10n, InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.active:
        return l10n.statusActive;
      case InvoiceStatus.cancelled:
        return l10n.billingStatusCancelled;
      case InvoiceStatus.draft:
        return l10n.draftStatus;
      case InvoiceStatus.issued:
        return l10n.issuedStatus;
      case InvoiceStatus.voided:
        return l10n.voidedStatus;
    }
  }

  static Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.active:
      case InvoiceStatus.issued:
        return Colors.green;
      case InvoiceStatus.cancelled:
      case InvoiceStatus.voided:
        return Colors.red;
      case InvoiceStatus.draft:
        return Colors.orange;
    }
  }
}
