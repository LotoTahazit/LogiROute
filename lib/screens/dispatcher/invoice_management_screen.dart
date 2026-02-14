import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_print_service.dart';
import 'create_standalone_invoice_dialog.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  List<Invoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      // ⚡ OPTIMIZED: Load only recent invoices (this month) with limit
      final invoices = await _invoiceService.getRecentInvoices(
        period: 'month',
        limit: 100,
      );
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה בטעינת חשבוניות: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createStandaloneInvoice() async {
    final invoice = await showDialog<Invoice>(
      context: context,
      builder: (context) => const CreateStandaloneInvoiceDialog(),
    );

    if (invoice != null) {
      await _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ חשבונית נוצרה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _reprintInvoice(Invoice invoice) async {
    // Показываем диалог выбора типа копии
    final copyType = await showDialog<InvoiceCopyType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר סוג העתק'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!invoice.originalPrinted)
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('מקור'),
                subtitle: const Text('העתק מקורי ראשון'),
                onTap: () => Navigator.pop(context, InvoiceCopyType.original),
              ),
            if (invoice.originalPrinted)
              ListTile(
                leading: const Icon(Icons.copy_all, color: Colors.blue),
                title: const Text('עותק'),
                subtitle: Text('עותק מספר ${invoice.copiesPrinted + 1}'),
                onTap: () => Navigator.pop(context, InvoiceCopyType.copy),
              ),
            if (invoice.originalPrinted)
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('נעימן למקור'),
                subtitle: const Text('מחליף את המקור האבוד'),
                onTap: () =>
                    Navigator.pop(context, InvoiceCopyType.replacesOriginal),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );

    if (copyType != null) {
      try {
        await InvoicePrintService.printInvoice(invoice, copyType: copyType);
        await _loadInvoices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ חשבונית הודפסה'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ שגיאה בהדפסה: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת חשבונית'),
        content: Text('האם למחוק חשבונית עבור ${invoice.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _invoiceService.deleteInvoice(invoice.id);
        await _loadInvoices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ חשבונית נמחקה'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ שגיאה במחיקה: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('ניהול חשבוניות'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'רענן',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'אין חשבוניות',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _invoices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.receipt, color: Colors.white),
                        ),
                        title: Text(
                          invoice.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('נהג: ${invoice.driverName}'),
                            Text(
                              'תאריך אספקה: ${DateFormat('dd/MM/yyyy').format(invoice.deliveryDate)}',
                            ),
                            Text(
                              'סה"כ: ₪${invoice.totalWithVAT.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (invoice.originalPrinted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'מקור הודפס',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                if (invoice.copiesPrinted > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'עותקים: ${invoice.copiesPrinted}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue),
                              tooltip: 'הדפס מחדש',
                              onPressed: () => _reprintInvoice(invoice),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'מחק',
                              onPressed: () => _deleteInvoice(invoice),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createStandaloneInvoice,
        icon: const Icon(Icons.add),
        label: const Text('חשבונית חדשה'),
      ),
    );
  }
}
