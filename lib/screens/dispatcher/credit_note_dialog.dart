import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

/// דיאלוג יצירת זיכוי
class CreditNoteDialog extends StatefulWidget {
  final Invoice originalInvoice;

  const CreditNoteDialog({super.key, required this.originalInvoice});

  @override
  State<CreditNoteDialog> createState() => _CreditNoteDialogState();
}

class _CreditNoteDialogState extends State<CreditNoteDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _createCreditNote() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'חובה לציין סיבה לזיכוי');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      final uid = auth.currentUser?.uid ?? '';
      final invoiceService = InvoiceService(
        companyId: widget.originalInvoice.companyId,
      );

      final creditNoteId = await invoiceService.createCreditNote(
        originalInvoice: widget.originalInvoice,
        reason: reason,
        createdBy: uid,
      );

      if (mounted) {
        Navigator.of(context).pop(creditNoteId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'שגיאה ביצירת זיכוי: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.originalInvoice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('יצירת זיכוי'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // פרטי המסמך המקורי
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'חשבונית מקור #${inv.sequentialNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('לקוח: ${inv.clientName}'),
                    Text('סכום: ₪${inv.totalWithVAT.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'הזיכוי ייצור מסמך חדש עם סכומים שליליים.\nהמסמך המקורי לא ישתנה.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'סיבת הזיכוי *',
                  hintText: 'לדוגמה: טעות בכמות',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textDirection: TextDirection.rtl,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _createCreditNote,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('צור זיכוי',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
