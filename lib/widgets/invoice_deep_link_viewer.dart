import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/invoice.dart';
import '../services/firestore_paths.dart';

/// Экран просмотра инвойса по deep-link URL.
/// Загружает документ из Firestore по companyId + docId.
/// Ожидает инициализации Firebase Auth перед запросом.
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
      // Wait for Firebase Auth to restore session (up to 10s)
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
        setState(() => _errorMessage = 'יש להתחבר למערכת תחילה');
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
        setState(() => _errorMessage = 'מסמך לא נמצא בנתיב: $path');
      }
    } catch (e, st) {
      debugPrint('[DeepLink] ERROR: $e');
      debugPrint('[DeepLink] Stack: $st');
      if (mounted) {
        setState(() => _errorMessage = 'שגיאה: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Invoice?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('טוען מסמך...')),
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

// ── Not Found ──────────────────────────────────────────────────────────────

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
    return Scaffold(
      appBar: AppBar(title: const Text('מסמך לא נמצא')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMessage ?? 'המסמך לא נמצא או שאין גישה',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Doc ID: $docId', style: const TextStyle(color: Colors.grey)),
            Text('Company: $companyId',
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
              label: const Text('חזרה'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Screen ──────────────────────────────────────────────────────────

class _DetailScreen extends StatelessWidget {
  final Invoice invoice;
  const _DetailScreen({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${_docTypeLabel(invoice.documentType)} #${invoice.sequentialNumber}'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(theme, fmt),
              const SizedBox(height: 16),
              _itemsCard(theme),
              const SizedBox(height: 16),
              _totalsCard(theme),
              if (invoice.status == InvoiceStatus.cancelled)
                _cancelledCard(theme, fmt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(ThemeData theme, DateFormat fmt) {
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
                child: Text(_docTypeLabel(invoice.documentType),
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
                  _statusLabel(invoice.status),
                  style: TextStyle(
                    color: _statusColor(invoice.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
            const Divider(height: 24),
            _kv('מספר מסמך', '#${invoice.sequentialNumber}'),
            _kv('לקוח', invoice.clientName),
            _kv('מספר לקוח', invoice.clientNumber),
            _kv('כתובת', invoice.address),
            _kv('נהג', invoice.driverName),
            _kv('משאית', invoice.truckNumber),
            _kv('תאריך אספקה', fmt.format(invoice.deliveryDate)),
            _kv('נוצר', fmt.format(invoice.createdAt)),
            _kv('נוצר על ידי', invoice.createdBy),
            if (invoice.paymentMethod != null)
              _kv('אופן תשלום', invoice.paymentMethod!),
            if (invoice.assignmentNumber != null)
              _kv('מספר הקצאה', invoice.assignmentNumber!),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('פריטים', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('מק"ט')),
                  DataColumn(label: Text('סוג')),
                  DataColumn(label: Text('מספר')),
                  DataColumn(label: Text('כמות')),
                  DataColumn(label: Text('מחיר')),
                  DataColumn(label: Text('סה"כ')),
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

  Widget _totalsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _sumRow('סה"כ לפני הנחה',
              '₪${invoice.totalBeforeDiscount.toStringAsFixed(2)}'),
          if (invoice.discount > 0)
            _sumRow('הנחה (${invoice.discount}%)',
                '-₪${invoice.discountAmount.toStringAsFixed(2)}'),
          _sumRow(
              'לפני מע"מ', '₪${invoice.subtotalBeforeVAT.toStringAsFixed(2)}'),
          _sumRow('מע"מ (18%)', '₪${invoice.vatAmount.toStringAsFixed(2)}'),
          const Divider(),
          _sumRow(
            'סה"כ לתשלום',
            '₪${invoice.totalWithVAT.toStringAsFixed(2)}',
            bold: true,
            fontSize: 20,
          ),
        ]),
      ),
    );
  }

  Widget _cancelledCard(ThemeData theme, DateFormat fmt) {
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
                Text('פרטי ביטול',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.red)),
              ]),
              const SizedBox(height: 8),
              if (invoice.cancelledBy != null)
                _kv('בוטל על ידי', invoice.cancelledBy!),
              if (invoice.cancelledAt != null)
                _kv('תאריך ביטול', fmt.format(invoice.cancelledAt!)),
              if (invoice.cancellationReason != null)
                _kv('סיבה', invoice.cancellationReason!),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ──

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

  static String _docTypeLabel(InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.invoice:
        return 'חשבונית מס';
      case InvoiceDocumentType.taxInvoiceReceipt:
        return 'חשבונית מס / קבלה';
      case InvoiceDocumentType.delivery:
        return 'תעודת משלוח';
      case InvoiceDocumentType.creditNote:
        return 'זיכוי';
      case InvoiceDocumentType.receipt:
        return 'קבלה';
    }
  }

  static String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.active:
        return 'פעיל';
      case InvoiceStatus.cancelled:
        return 'מבוטל';
      case InvoiceStatus.draft:
        return 'טיוטה';
      case InvoiceStatus.issued:
        return 'הונפק';
      case InvoiceStatus.voided:
        return 'בוטל';
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
