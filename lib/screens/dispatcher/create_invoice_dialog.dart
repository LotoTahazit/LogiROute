import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_point.dart';
import '../../models/invoice.dart';
import '../../models/user_model.dart';
import '../../services/price_service.dart';
import '../../services/invoice_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';

class CreateInvoiceDialog extends StatefulWidget {
  final DeliveryPoint point;
  final UserModel driver;

  const CreateInvoiceDialog({
    super.key,
    required this.point,
    required this.driver,
  });

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  late DateTime _deliveryDate;
  int _paymentTermDays = 30; // Срок оплаты по умолчанию 30 дней
  bool _customPaymentDate = false; // Ручной ввод даты
  DateTime? _manualPaymentDate; // Дата при ручном вводе
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );
  final Map<int, TextEditingController> _priceControllers = {};

  bool _isLoading = true;
  List<InvoiceItem> _items = [];

  DateTime get _effectivePaymentDueDate {
    if (_customPaymentDate && _manualPaymentDate != null) {
      return _manualPaymentDate!;
    }
    return _deliveryDate.add(Duration(days: _paymentTermDays));
  }

  @override
  void initState() {
    super.initState();
    // По умолчанию дата доставки = завтра
    _deliveryDate = DateTime.now().add(const Duration(days: 1));
    _loadPrices();
  }

  @override
  void dispose() {
    _discountController.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);

    try {
      if (widget.point.boxTypes == null || widget.point.boxTypes!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Используем CompanyContext для получения effectiveCompanyId
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId ?? '';
      final priceService = PriceService(companyId: companyId);
      final items = <InvoiceItem>[];

      for (final boxType in widget.point.boxTypes!) {
        // Загружаем цену из базы
        final price = await priceService.getPrice(
          boxType.type,
          boxType.number,
        );
        final pricePerUnit = price?.priceBeforeVAT ?? 0.0;

        items.add(
          InvoiceItem(
            productCode:
                boxType.productCode, // Используем настоящий מק"ט из boxType
            type: boxType.type,
            number: boxType.number,
            quantity: boxType.quantity,
            pricePerUnit: pricePerUnit,
          ),
        );
      }

      setState(() {
        _items = items;
        // Создаём контроллеры для каждой цены
        for (int i = 0; i < _items.length; i++) {
          _priceControllers[i] = TextEditingController(
            text: _items[i].pricePerUnit.toStringAsFixed(2),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading prices: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateItemPrice(int index, double newPrice) {
    setState(() {
      _items[index] = InvoiceItem(
        productCode: _items[index].productCode, // Сохраняем מק"ט
        type: _items[index].type,
        number: _items[index].number,
        quantity: _items[index].quantity,
        pricePerUnit: newPrice,
      );
    });
  }

  double get _subtotalBeforeVAT {
    final total = _items.fold(0.0, (sum, item) => sum + item.totalBeforeVAT);
    final discountPercent = double.tryParse(_discountController.text) ?? 0.0;
    final discountAmount = total * (discountPercent / 100);
    return total - discountAmount;
  }

  double get _vatAmount => _subtotalBeforeVAT * Invoice.VAT_RATE;
  double get _totalWithVAT => _subtotalBeforeVAT + _vatAmount;

  Future<void> _createInvoice() async {
    try {
      // ✅ Берём данные из authService (виртуальный companyId для super_admin)
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      final companyId = user?.companyId ?? '';
      final userName = user?.name ?? 'Unknown';
      final userUid = authService.currentUser?.uid ?? '';
      if (userUid.isEmpty) {
        throw Exception('משתמש לא מחובר — לא ניתן ליצור חשבונית');
      }

      // Время выезда всегда 7:00
      final departureTime = DateTime(
        _deliveryDate.year,
        _deliveryDate.month,
        _deliveryDate.day,
        7,
        0,
      );

      final invoice = Invoice(
        id: '',
        companyId: companyId,
        sequentialNumber: 0, // Will be set by service
        clientName: widget.point.clientName,
        clientNumber: widget.point.clientNumber ?? '', // Берем из DeliveryPoint
        address: widget.point.address,
        driverName: widget.driver.name,
        truckNumber: widget.driver.vehicleNumber ?? '',
        deliveryDate: _deliveryDate,
        paymentDueDate: _effectivePaymentDueDate,
        departureTime: departureTime,
        items: _items,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        createdAt: DateTime.now(),
        createdBy: userName,
      );

      // Создаём сервис с companyId
      final invoiceService = InvoiceService(companyId: companyId);

      // Create invoice and get the ID
      final invoiceId = await invoiceService.createInvoice(invoice, userUid);

      // Финализируем сразу — это запускает assignment request если нужно
      await invoiceService.finalizeInvoice(invoiceId, userUid);

      // Загружаем актуальный объект с обновлённым assignmentStatus
      final finalizedInvoice = await invoiceService.getInvoice(invoiceId);

      if (mounted) {
        Navigator.pop(
            context, finalizedInvoice ?? invoice.copyWith(id: invoiceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ חשבונית נוצרה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('יצירת חשבונית'),
      content: SizedBox(
        width: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Информация о клиенте
                    _buildInfoSection(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Дата доставки
                    _buildDatePicker(),
                    const SizedBox(height: 16),

                    // Срок оплаты
                    _buildPaymentTermSelector(),
                    const SizedBox(height: 16),

                    // Таблица товаров
                    _buildItemsTable(),
                    const SizedBox(height: 16),

                    // Скидка
                    _buildDiscountField(),
                    const SizedBox(height: 16),
                    const Divider(),

                    // Итоги
                    _buildTotals(),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton.icon(
          onPressed: _items.isEmpty ? null : _createInvoice,
          icon: const Icon(Icons.print),
          label: const Text('צור והדפס'),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'לקוח: ${widget.point.clientName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('כתובת: ${widget.point.address}'),
        Text('נהג: ${widget.driver.name}'),
        Text('משאית: ${widget.driver.vehicleNumber ?? "לא צוין"}'),
        const Text('שעת יציאה: 07:00'),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        const Text(
          'תאריך אספקה: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _deliveryDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _deliveryDate = picked);
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(DateFormat('dd/MM/yyyy').format(_deliveryDate)),
        ),
      ],
    );
  }

  Widget _buildPaymentTermSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'תנאי תשלום:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30 ימים')),
                  ButtonSegment(value: 60, label: Text('60 ימים')),
                  ButtonSegment(value: 90, label: Text('90 ימים')),
                  ButtonSegment(value: -1, label: Text('ידני')),
                ],
                selected: {_customPaymentDate ? -1 : _paymentTermDays},
                onSelectionChanged: (Set<int> selected) {
                  setState(() {
                    if (selected.first == -1) {
                      _customPaymentDate = true;
                      _manualPaymentDate ??=
                          _deliveryDate.add(const Duration(days: 30));
                    } else {
                      _customPaymentDate = false;
                      _paymentTermDays = selected.first;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_customPaymentDate)
          Row(
            children: [
              const Text('תשלום עד: '),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _manualPaymentDate ??
                        _deliveryDate.add(const Duration(days: 30)),
                    firstDate: _deliveryDate,
                    lastDate: _deliveryDate.add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _manualPaymentDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  DateFormat('dd/MM/yyyy').format(_effectivePaymentDueDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        else
          Text(
            'תשלום עד: ${DateFormat('dd/MM/yyyy').format(_effectivePaymentDueDate)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'פריטים:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
          },
          children: [
            // Заголовок
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'פריט',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'קרטונים',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'מחיר ליח\'',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'סה"כ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // Строки товаров
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${item.type} ${item.number}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${item.quantity}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: TextField(
                      controller: _priceControllers[index],
                      decoration: const InputDecoration(
                        prefixText: '₪',
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value) ?? 0.0;
                        _updateItemPrice(index, price);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('₪${item.totalBeforeVAT.toStringAsFixed(2)}'),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountField() {
    return Row(
      children: [
        const Text('הנחה: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _discountController,
            decoration: const InputDecoration(
              suffixText: '%',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('סה"כ לפני מע"מ:', style: TextStyle(fontSize: 16)),
            Text(
              '₪${_subtotalBeforeVAT.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('מע"מ (18%):', style: TextStyle(fontSize: 16)),
            Text(
              '₪${_vatAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'סה"כ לתשלום:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '₪${_totalWithVAT.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
