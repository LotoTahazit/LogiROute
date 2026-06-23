import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_print_service.dart';
import '../../services/invoice_assignment_service.dart';
import '../../services/company_context.dart';
import '../../services/auth_service.dart';
import '../../services/access_log_service.dart';
import '../../services/cross_module_audit_service.dart';
import '../../services/issuance_service.dart';
import '../../widgets/payment_details_form.dart';
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
  String? _currentCompanyId;

  Future<void> _loadInvoices(String companyId) async {
    if (companyId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final invoiceService = InvoiceService(companyId: companyId);
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
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingInvoices(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retryAssignment(String companyId, Invoice invoice) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final assignmentService = InvoiceAssignmentService(companyId: companyId);
      final result =
          await assignmentService.requestAssignmentNumber(invoice.id);
      await _loadInvoices(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? l10n.assignmentNumberReceived(
                    result.assignmentNumber ?? '')
                : l10n.errorWithMessage(result.error ?? l10n.cancel)),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.assignmentRequestError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createStandaloneInvoice() async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.standaloneInvoiceInDev),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _createReceipt(String companyId, Invoice invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    try {
      final companyCtx = CompanyContext.of(context);
      final companyDoc = await companyCtx.paths.companyDoc(companyId).get();
      final data = companyDoc.data() ?? {};
      if (data['accountingLockedUntil'] != null) {
        final lockedUntil =
            (data['accountingLockedUntil'] as Timestamp).toDate();
        if (!invoice.deliveryDate.isAfter(lockedUntil)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.receiptPeriodLockedError(
                  DateFormat('dd/MM/yyyy').format(invoice.deliveryDate),
                  DateFormat('dd/MM/yyyy').format(lockedUntil),
                )),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    final paymentResult = await showDialog<PaymentDialogResult>(
      context: context,
      builder: (context) => _ReceiptPaymentDialog(invoice: invoice),
    );

    if (paymentResult == null || !mounted) return;

    try {
      final user = authService.userModel;
      final userUid = authService.currentUser?.uid ?? '';
      if (userUid.isEmpty) throw Exception(l10n.userNotLoggedIn);

      final receipt = Invoice(
        id: '',
        companyId: companyId,
        sequentialNumber: 0,
        clientName: invoice.clientName,
        clientNumber: invoice.clientNumber,
        address: invoice.address,
        driverName: invoice.driverName,
        truckNumber: invoice.truckNumber,
        deliveryDate: invoice.deliveryDate,
        paymentDueDate: DateTime.now(),
        departureTime: invoice.departureTime,
        items: invoice.items,
        discount: invoice.discount,
        createdAt: DateTime.now(),
        createdBy: user?.name ?? 'Unknown',
        documentType: InvoiceDocumentType.receipt,
        linkedInvoiceId: invoice.id,
        paymentMethod: paymentResult.methodKey,
        paymentLines: paymentResult.paymentLines,
      );

      final invoiceService = InvoiceService(companyId: companyId);
      final receiptId = await invoiceService.createInvoice(receipt, userUid);

      final issuanceResult = await IssuanceService().issueDocument(
        companyId: companyId,
        invoiceId: receiptId,
        counterKey: InvoiceDocumentType.receipt.canonicalCounterKey,
      );

      if (!issuanceResult.ok) {
        throw Exception(l10n.receiptIssuanceError);
      }

      final issuedReceipt = await invoiceService.getInvoice(receiptId);
      if (issuedReceipt != null && mounted) {
        final auth = context.read<AuthService>();
        await InvoicePrintService.printFirstTime(
          issuedReceipt,
          actorUid: auth.currentUser?.uid,
          actorName: auth.userModel?.name,
        );
      }

      CrossModuleAuditService(companyId: companyId).log(
        moduleKey: 'accounting',
        type: CrossModuleAuditService.typeReceiptCreated,
        entityCollection: 'receipts',
        entityDocId: receiptId,
        uid: userUid,
      );

      await _loadInvoices(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receiptCreatedAndPrinted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receiptCreateError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reprintInvoice(String companyId, Invoice invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReprintDialog(invoice: invoice),
    );

    if (result != null) {
      try {
        final copyType = result['copyType'] as InvoiceCopyType;
        final copies = result['copies'] as int;
        await InvoicePrintService.printInvoice(invoice,
            copyType: copyType,
            copies: copies,
            actorUid: auth.currentUser?.uid,
            actorName: auth.userModel?.name);
        await _loadInvoices(companyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invoicePrintedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.printError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelInvoice(String companyId, Invoice invoice) async {
    final authService = context.read<AuthService>();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.cancelInvoiceTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cancelInvoiceConfirm(invoice.clientName)),
              const SizedBox(height: 16),
              Text(
                l10n.cancelInvoiceLawNote,
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: l10n.cancellationReasonRequired,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.goBack),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.enterCancellationReason),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(l10n.cancelInvoiceButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final userUid = authService.currentUser?.uid ?? '';
      final userName = authService.userModel?.name;

      try {
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
            SnackBar(
              content: Text(l10n.invoiceCancelledSuccess),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cancelInvoiceError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    reasonController.dispose();
  }

  String _docTypeChipLabel(AppLocalizations l10n, InvoiceDocumentType type) {
    switch (type) {
      case InvoiceDocumentType.creditNote:
        return l10n.creditNote;
      case InvoiceDocumentType.receipt:
        return l10n.receipt;
      case InvoiceDocumentType.taxInvoiceReceipt:
        return l10n.taxInvoiceReceiptShort;
      case InvoiceDocumentType.delivery:
        return l10n.deliveryNoteShort;
      case InvoiceDocumentType.invoice:
        return l10n.taxInvoice;
    }
  }

  String _assignmentChipLabel(AppLocalizations l10n, Invoice invoice) {
    switch (invoice.assignmentStatus) {
      case AssignmentStatus.approved:
        return l10n.assignmentApprovedLabel(invoice.assignmentNumber ?? '');
      case AssignmentStatus.pending:
        return l10n.assignmentPendingLabel;
      case AssignmentStatus.rejected:
        return l10n.assignmentRejectedLabel;
      case AssignmentStatus.error:
        return l10n.assignmentErrorLabel;
      default:
        return l10n.assignmentRequiredLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.watch(context);
    final effectiveCompanyId = companyCtx.effectiveCompanyId ?? '';
    final narrow = MediaQuery.sizeOf(context).width < 600;

    if (_currentCompanyId != effectiveCompanyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadInvoices(effectiveCompanyId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(l10n.invoiceManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInvoices(effectiveCompanyId),
            tooltip: l10n.refresh,
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
                        l10n.billingNoInvoices,
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
                    final statusChips = <Widget>[
                      if (invoice.documentType != InvoiceDocumentType.invoice)
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
                            _docTypeChipLabel(l10n, invoice.documentType),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
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
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            l10n.draftStatus,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.red),
                          ),
                        ),
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
                          child: Text(
                            l10n.billingStatusCancelled,
                            style: const TextStyle(
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
                          child: Text(
                            l10n.originalPrintedLabel,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      if (invoice.copiesPrinted > 0)
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
                            l10n.copiesCountLabel(invoice.copiesPrinted),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      if (invoice.requiresAssignment)
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
                            _assignmentChipLabel(l10n, invoice),
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
                    ];
                    final actionButtons = <Widget>[
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.grey),
                        tooltip: l10n.historyTooltip,
                        onPressed: () {
                          final auth = context.read<AuthService>();
                          final uid = auth.currentUser?.uid ?? '';
                          if (uid.isNotEmpty) {
                            AccessLogService(companyId: effectiveCompanyId)
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
                                invoiceTitle: l10n.invoiceNumberTitle(
                                    invoice.sequentialNumber),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.blue),
                        tooltip: l10n.reprintTooltip,
                        onPressed: () =>
                            _reprintInvoice(effectiveCompanyId, invoice),
                      ),
                      if (invoice.status == InvoiceStatus.active &&
                          invoice.documentType !=
                              InvoiceDocumentType.creditNote)
                        IconButton(
                          icon: const Icon(Icons.receipt_long,
                              color: Colors.orange),
                          tooltip: l10n.createCreditNote,
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final result = await showDialog<String>(
                              context: context,
                              builder: (_) => CreditNoteDialog(
                                originalInvoice: invoice,
                              ),
                            );
                            if (result != null && mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text(l10n.creditNoteCreatedSuccess),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadInvoices(effectiveCompanyId);
                            }
                          },
                        ),
                      if (invoice.status == InvoiceStatus.active &&
                          (invoice.documentType == InvoiceDocumentType.invoice ||
                              invoice.documentType ==
                                  InvoiceDocumentType.taxInvoiceReceipt))
                        IconButton(
                          icon: const Icon(Icons.payments, color: Colors.teal),
                          tooltip: l10n.createReceiptTooltip,
                          onPressed: () =>
                              _createReceipt(effectiveCompanyId, invoice),
                        ),
                      if (invoice.canBeCancelled)
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: l10n.cancelInvoiceTooltip,
                          onPressed: () =>
                              _cancelInvoice(effectiveCompanyId, invoice),
                        ),
                      if (invoice.requiresAssignment &&
                          (invoice.assignmentStatus == AssignmentStatus.error ||
                              invoice.assignmentStatus ==
                                  AssignmentStatus.rejected))
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          tooltip: l10n.retryAssignmentTooltip,
                          onPressed: () =>
                              _retryAssignment(effectiveCompanyId, invoice),
                        ),
                    ];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        isThreeLine: narrow,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.receipt, color: Colors.white),
                        ),
                        title: Text(
                          invoice.clientName,
                          maxLines: narrow ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.driverWithName(invoice.driverName)),
                            Text(l10n.deliveryDateWithValue(
                                DateFormat('dd/MM/yyyy')
                                    .format(invoice.deliveryDate))),
                            Text(
                              l10n.totalWithAmount(
                                  invoice.totalWithVAT.toStringAsFixed(2)),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (statusChips.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: statusChips,
                              ),
                            ],
                            if (narrow) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: actionButtons,
                              ),
                            ],
                          ],
                        ),
                        trailing: narrow
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: actionButtons,
                              ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createStandaloneInvoice,
        icon: const Icon(Icons.add),
        label: Text(l10n.newInvoiceButton),
      ),
    );
  }
}

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.reprintDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<InvoiceCopyType>(
            groupValue: _selectedType,
            onChanged: (v) => setState(() => _selectedType = v!),
            child: Column(
              children: [
                ListTile(
                  leading: const Radio<InvoiceCopyType>(
                    value: InvoiceCopyType.copy,
                  ),
                  title: Text(l10n.copyTypeLabel),
                  subtitle: Text(l10n
                      .copyNumberLabel(widget.invoice.copiesPrinted + 1)),
                  onTap: () =>
                      setState(() => _selectedType = InvoiceCopyType.copy),
                ),
                ListTile(
                  leading: const Radio<InvoiceCopyType>(
                    value: InvoiceCopyType.replacesOriginal,
                  ),
                  title: Text(l10n.trueToOriginalLabel),
                  subtitle: Text(l10n.replacesOriginalLabel),
                  onTap: () => setState(
                      () => _selectedType = InvoiceCopyType.replacesOriginal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('${l10n.quantity}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, {
            'copyType': _selectedType,
            'copies': _copies,
          }),
          icon: const Icon(Icons.print),
          label: Text(l10n.printCopiesButton(_copies)),
        ),
      ],
    );
  }
}

class _ReceiptPaymentDialog extends StatefulWidget {
  final Invoice invoice;
  const _ReceiptPaymentDialog({required this.invoice});

  @override
  State<_ReceiptPaymentDialog> createState() => _ReceiptPaymentDialogState();
}

class _ReceiptPaymentDialogState extends State<_ReceiptPaymentDialog> {
  final _paymentDetails = PaymentDetailsController();

  @override
  void dispose() {
    _paymentDetails.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = widget.invoice.totalWithVAT;
    return AlertDialog(
      title: Text(l10n.createReceiptTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.receiptForInvoice(widget.invoice.sequentialNumber),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(l10n.clientWithName(widget.invoice.clientName)),
              Text(
                l10n.amountWithValue(total.toStringAsFixed(2)),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 16),
              PaymentDetailsForm(
                controller: _paymentDetails,
                totalAmount: total,
                defaultDueDate: DateTime.now(),
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final err = _paymentDetails.validate(l10n);
            if (err != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err), backgroundColor: Colors.red),
              );
              return;
            }
            Navigator.pop(
              context,
              PaymentDialogResult(
                methodKey: _paymentDetails.methodKey,
                paymentLines: _paymentDetails.buildLines(
                  total: total,
                  defaultDue: DateTime.now(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.payments),
          label: Text(l10n.createReceiptButton),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        ),
      ],
    );
  }
}
