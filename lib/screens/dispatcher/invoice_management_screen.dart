import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_print_service.dart';
import '../../services/invoice_assignment_service.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/access_log_service.dart';
import 'audit_log_screen.dart';
import 'credit_note_dialog.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _currentCompanyId; // Для отслеживания смены компании

  @override
  void initState() {
    super.initState();
    // Первоначальная загрузка данных произойдёт в build() через CompanyContext
  }

  Future<void> _loadInvoices(String companyId) async {
    if (companyId.isEmpty) {
      print('⚠️ [InvoiceManagement] CompanyId is empty, skipping load');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📊 [InvoiceManagement] Loading invoices for company: $companyId');

      // Создаём сервис с текущим companyId
      final invoiceService = InvoiceService(companyId: companyId);

      // ⚡ OPTIMIZED: Load only recent invoices (this month) with limit
      // כולל מבוטלים — נדרש לפי חוק ניהול ספרים
      final invoices = await invoiceService.getAllInvoices(
        fromDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        limit: 100,
        includeCancelled: true,
      );

      if (mounted) {
        setState(() {
          _invoices = invoices;
          _isLoading = false;
          _currentCompanyId = companyId;
        });
      }

      print('✅ [InvoiceManagement] Loaded ${invoices.length} invoices');
    } catch (e) {
      print('❌ [InvoiceManagement] Error loading invoices: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה בטעינת חשבוניות: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retryAssignment(String companyId, Invoice invoice) async {
    try {
      final assignmentService = InvoiceAssignmentService(companyId: companyId);
      final result =
          await assignmentService.requestAssignmentNumber(invoice.id);
      await _loadInvoices(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? '✅ מספר הקצאה התקבל: ${result.assignmentNumber}'
                : '❌ ${result.error ?? "שגיאה"}'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה בבקשת הקצאה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createStandaloneInvoice() async {
    // TODO: Implement standalone invoice creation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ יצירת חשבונית עצמאית בפיתוח'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _reprintInvoice(String companyId, Invoice invoice) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReprintDialog(invoice: invoice),
    );

    if (result != null) {
      try {
        final copyType = result['copyType'] as InvoiceCopyType;
        final copies = result['copies'] as int;
        final auth = context.read<AuthService>();
        await InvoicePrintService.printInvoice(invoice,
            copyType: copyType,
            copies: copies,
            actorUid: auth.currentUser?.uid,
            actorName: auth.userModel?.name);
        await _loadInvoices(companyId);
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

  Future<void> _cancelInvoice(String companyId, Invoice invoice) async {
    // Запрашиваем причину отмены
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול חשבונית'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('האם לבטל חשבונית עבור ${invoice.clientName}?'),
            const SizedBox(height: 16),
            const Text(
              'לפי חוק ניהול ספרים, חשבונית לא ניתן למחוק, רק לבטל.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'סיבת ביטול (חובה)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('חזור'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('נא להזין סיבת ביטול'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('בטל חשבונית'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        final authService = context.read<AuthService>();
        final userUid = authService.currentUser?.uid ?? '';
        final userName = authService.userModel?.name;

        final invoiceService = InvoiceService(companyId: companyId);
        await invoiceService.cancelInvoice(
          invoice.id,
          userUid,
          reasonController.text.trim(),
          cancelledByName: userName,
        );
        await _loadInvoices(companyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ חשבונית בוטלה'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ שגיאה בביטול: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ЭТАЛОННЫЙ ПАТТЕРН: Используем CompanyContext.watch() для автообновления
    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';

    // ✅ ЭТАЛОННЫЙ ПАТТЕРН: Отслеживаем смену компании
    if (_currentCompanyId != effectiveCompanyId) {
      // Компания изменилась - перезагружаем данные
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              '🔄 [InvoiceManagement] Company changed: $_currentCompanyId -> $effectiveCompanyId');
          _loadInvoices(effectiveCompanyId);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('ניהול חשבוניות'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInvoices(effectiveCompanyId),
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
                                // סוג מסמך
                                if (invoice.documentType !=
                                    InvoiceDocumentType.invoice)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: invoice.documentType ==
                                              InvoiceDocumentType.creditNote
                                          ? Colors.orange.shade100
                                          : Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      invoice.documentType ==
                                              InvoiceDocumentType.creditNote
                                          ? 'זיכוי'
                                          : invoice.documentType ==
                                                  InvoiceDocumentType.receipt
                                              ? 'קבלה'
                                              : 'ת. משלוח',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                // טיוטה
                                if (invoice.status == InvoiceStatus.draft)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.red.shade300),
                                    ),
                                    child: const Text(
                                      'טיוטה',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.red),
                                    ),
                                  ),
                                // מבוטל
                                if (invoice.status == InvoiceStatus.cancelled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'מבוטל',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.red),
                                    ),
                                  ),
                                if (invoice.originalPrinted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(left: 4),
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
                                // סטטוס מספר הקצאה
                                if (invoice.requiresAssignment) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: invoice.assignmentStatus ==
                                              AssignmentStatus.approved
                                          ? Colors.green.shade100
                                          : invoice.assignmentStatus ==
                                                  AssignmentStatus.pending
                                              ? Colors.orange.shade100
                                              : invoice.assignmentStatus ==
                                                      AssignmentStatus.rejected
                                                  ? Colors.red.shade100
                                                  : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      invoice.assignmentStatus ==
                                              AssignmentStatus.approved
                                          ? 'הקצאה: ${invoice.assignmentNumber ?? ''}'
                                          : invoice.assignmentStatus ==
                                                  AssignmentStatus.pending
                                              ? 'ממתין להקצאה'
                                              : invoice.assignmentStatus ==
                                                      AssignmentStatus.rejected
                                                  ? 'הקצאה נדחתה'
                                                  : invoice.assignmentStatus ==
                                                          AssignmentStatus.error
                                                      ? 'שגיאת הקצאה'
                                                      : 'נדרש הקצאה',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: invoice.assignmentStatus ==
                                                AssignmentStatus.approved
                                            ? Colors.green.shade800
                                            : invoice.assignmentStatus ==
                                                    AssignmentStatus.rejected
                                                ? Colors.red
                                                : Colors.black87,
                                      ),
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
                              icon:
                                  const Icon(Icons.history, color: Colors.grey),
                              tooltip: 'היסטוריה',
                              onPressed: () {
                                // רישום צפייה ביומן גישה
                                final auth = context.read<AuthService>();
                                final uid = auth.currentUser?.uid ?? '';
                                if (uid.isNotEmpty) {
                                  AccessLogService(
                                          companyId: effectiveCompanyId)
                                      .logAccess(
                                    actorUid: uid,
                                    eventType: AccessEventType.viewDocument,
                                    actorName: auth.userModel?.name,
                                    targetEntityId: invoice.id,
                                    targetEntityType: invoice.documentType.name,
                                  );
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AuditLogScreen(
                                      invoiceId: invoice.id,
                                      companyId: effectiveCompanyId,
                                      invoiceTitle:
                                          'חשבונית #${invoice.sequentialNumber}',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue),
                              tooltip: 'הדפס מחדש',
                              onPressed: () =>
                                  _reprintInvoice(effectiveCompanyId, invoice),
                            ),
                            if (invoice.status == InvoiceStatus.active &&
                                invoice.documentType !=
                                    InvoiceDocumentType.creditNote)
                              IconButton(
                                icon: const Icon(Icons.receipt_long,
                                    color: Colors.orange),
                                tooltip: 'צור זיכוי',
                                onPressed: () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (_) => CreditNoteDialog(
                                      originalInvoice: invoice,
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ זיכוי נוצר בהצלחה'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadInvoices(effectiveCompanyId);
                                  }
                                },
                              ),
                            if (invoice.canBeCancelled)
                              IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'בטל חשבונית',
                                onPressed: () =>
                                    _cancelInvoice(effectiveCompanyId, invoice),
                              ),
                            // כפתור ניסיון חוזר למספר הקצאה
                            if (invoice.requiresAssignment &&
                                (invoice.assignmentStatus ==
                                        AssignmentStatus.error ||
                                    invoice.assignmentStatus ==
                                        AssignmentStatus.rejected))
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Colors.orange),
                                tooltip: 'ניסיון חוזר להקצאה',
                                onPressed: () => _retryAssignment(
                                    effectiveCompanyId, invoice),
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

/// Диалог повторной печати с выбором типа и количества
class _ReprintDialog extends StatefulWidget {
  final Invoice invoice;
  const _ReprintDialog({required this.invoice});

  @override
  State<_ReprintDialog> createState() => _ReprintDialogState();
}

class _ReprintDialogState extends State<_ReprintDialog> {
  InvoiceCopyType _selectedType = InvoiceCopyType.copy;
  int _copies = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הדפסה חוזרת'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Radio<InvoiceCopyType>(
              value: InvoiceCopyType.copy,
              groupValue: _selectedType,
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            title: const Text('העתק'),
            subtitle: Text('עותק מספר ${widget.invoice.copiesPrinted + 1}'),
            onTap: () => setState(() => _selectedType = InvoiceCopyType.copy),
          ),
          ListTile(
            leading: Radio<InvoiceCopyType>(
              value: InvoiceCopyType.replacesOriginal,
              groupValue: _selectedType,
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            title: const Text('נאמן למקור'),
            subtitle: const Text('מחליף את המקור'),
            onTap: () => setState(
                () => _selectedType = InvoiceCopyType.replacesOriginal),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('כמות: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
              ),
              Text('$_copies',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed:
                    _copies < 10 ? () => setState(() => _copies++) : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, {
            'copyType': _selectedType,
            'copies': _copies,
          }),
          icon: const Icon(Icons.print),
          label: Text('הדפס $_copies עותקים'),
        ),
      ],
    );
  }
}
