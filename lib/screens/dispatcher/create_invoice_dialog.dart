import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/delivery_point.dart';
import '../../models/invoice.dart';
import '../../models/user_model.dart';
import '../../services/price_service.dart';
import '../../services/invoice_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/issuance_service.dart';
import '../../services/box_type_service.dart';
import '../../services/inventory_service.dart';
import '../../services/company_cache.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';

class CreateInvoiceDialog extends StatefulWidget {
  final DeliveryPoint point;
  final UserModel driver;
  final InvoiceDocumentType documentType;

  const CreateInvoiceDialog({
    super.key,
    required this.point,
    required this.driver,
    this.documentType = InvoiceDocumentType.invoice,
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
  bool _isCreating = false;
  bool _paymentReceived =
      false; // תשלום התקבל — переключает тип на taxInvoiceReceipt
  String _paymentMethod = 'מזומן'; // אופן תשלום
  DateTime? _accountingLockedUntil; // период закрытия бухгалтерии
  String? _periodLockError; // ошибка если дата в закрытом периоде

  bool get _taxInvoiceReceiptBlocked =>
      !AppConfig.enableTaxInvoiceReceipt &&
      (widget.documentType == InvoiceDocumentType.taxInvoiceReceipt ||
          _effectiveDocumentType == InvoiceDocumentType.taxInvoiceReceipt);

  /// Эффективный тип документа: если оплата получена — taxInvoiceReceipt
  InvoiceDocumentType get _effectiveDocumentType {
    if (AppConfig.enableTaxInvoiceReceipt &&
        _paymentReceived &&
        widget.documentType == InvoiceDocumentType.invoice) {
      return InvoiceDocumentType.taxInvoiceReceipt;
    }
    return widget.documentType;
  }

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
      // Загружаем accountingLockedUntil из company doc
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId ?? '';

      try {
        final companyDoc = await companyCtx.paths.companyDoc(companyId).get();
        final data = companyDoc.data() ?? {};
        if (data['accountingLockedUntil'] != null) {
          _accountingLockedUntil =
              (data['accountingLockedUntil'] as Timestamp).toDate();
          // Если дефолтная дата попадает в закрытый период — сдвигаем
          if (_accountingLockedUntil != null &&
              !_deliveryDate.isAfter(_accountingLockedUntil!)) {
            _deliveryDate =
                _accountingLockedUntil!.add(const Duration(days: 1));
          }
        }
      } catch (_) {
        // Не блокируем загрузку если не удалось прочитать lock
      }

      // Автозаполнение paymentMethod из клиента
      try {
        final cache = CompanyCache.instance(companyId);
        final clientNumber = widget.point.clientNumber;
        if (clientNumber != null && clientNumber.isNotEmpty) {
          final client = cache.clients.where(
            (c) => c.clientNumber == clientNumber,
          );
          if (client.isNotEmpty &&
              client.first.paymentMethod != null &&
              client.first.paymentMethod!.isNotEmpty) {
            _paymentMethod = client.first.paymentMethod!;
          }
        }
      } catch (_) {}

      if (widget.point.boxTypes == null || widget.point.boxTypes!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final priceService = PriceService(companyId: companyId);
      final boxTypeService = BoxTypeService(companyId: companyId);
      final inventoryService = InventoryService(companyId: companyId);
      final allBoxTypes = await boxTypeService.getAllBoxTypes();
      final inventory = await inventoryService.getInventory();
      final items = <InvoiceItem>[];

      for (final boxType in widget.point.boxTypes!) {
        // Загружаем цену из базы
        final price = await priceService.getPrice(
          boxType.type,
          boxType.number,
        );
        final pricePerUnit = price?.priceBeforeVAT ?? 0.0;

        // Загружаем piecesPerBox: 1) box_types  2) inventory  3) default 1
        int piecesPerBox = 1;
        final match = allBoxTypes.where(
          (bt) => bt['productCode'] == boxType.productCode,
        );
        if (match.isNotEmpty && match.first['piecesPerBox'] != null) {
          piecesPerBox = ((match.first['piecesPerBox']) as num).toInt();
        } else {
          // Fallback: ищем piecesPerBox в инвентаре по type+number
          final invMatch = inventory.where(
            (inv) => inv.type == boxType.type && inv.number == boxType.number,
          );
          if (invMatch.isNotEmpty && invMatch.first.piecesPerBox != null) {
            piecesPerBox = invMatch.first.piecesPerBox!;
          }
        }
        debugPrint(
          '📋 [Invoice] ${boxType.type} ${boxType.number} (${boxType.productCode}): '
          'piecesPerBox=$piecesPerBox, qty=${boxType.quantity}, '
          'totalUnits=${boxType.quantity * piecesPerBox}',
        );

        items.add(
          InvoiceItem(
            productCode:
                boxType.productCode, // Используем настоящий מק"ט из boxType
            type: boxType.type,
            number: boxType.number,
            quantity: boxType.quantity,
            piecesPerBox: piecesPerBox,
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
        piecesPerBox: _items[index].piecesPerBox,
        pricePerUnit: newPrice,
      );
    });
  }

  /// Проверка: дата не попадает в закрытый бухгалтерский период
  void _validatePeriodLock() {
    if (_accountingLockedUntil != null &&
        !_deliveryDate.isAfter(_accountingLockedUntil!)) {
      final l10n = AppLocalizations.of(context)!;
      _periodLockError = l10n.invoicePeriodLockedError(
        DateFormat('dd/MM/yyyy').format(_deliveryDate),
        DateFormat('dd/MM/yyyy').format(_accountingLockedUntil!),
      );
    } else {
      _periodLockError = null;
    }
  }

  double get _subtotalBeforeVAT {
    final total = _items.fold(
        0.0, (runningTotal, item) => runningTotal + item.totalBeforeVAT);
    final discountPercent = double.tryParse(_discountController.text) ?? 0.0;
    final discountAmount = total * (discountPercent / 100);
    return total - discountAmount;
  }

  double get _vatAmount => _subtotalBeforeVAT * Invoice.vatRate;
  double get _totalWithVAT => _subtotalBeforeVAT + _vatAmount;

  Future<void> _createInvoice() async {
    if (_isCreating) return;
    final l10n = AppLocalizations.of(context)!;
    if (_taxInvoiceReceiptBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hashbonit is under construction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isCreating = true);
    try {
      // ✅ Берём данные из authService (виртуальный companyId для super_admin)
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      final companyId = user?.companyId ?? '';
      final userName = user?.name ?? 'Unknown';
      final userUid = authService.currentUser?.uid ?? '';
      if (userUid.isEmpty) {
        throw Exception(l10n.userNotLoggedIn);
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
        sequentialNumber: 0, // Draft — номер выдаст сервер
        clientName: widget.point.clientName,
        clientNumber: widget.point.clientNumber ?? '',
        address: widget.point.address,
        driverName: widget.driver.name,
        truckNumber: widget.driver.vehicleNumber ?? '',
        deliveryDate: _deliveryDate,
        paymentDueDate: widget.documentType == InvoiceDocumentType.delivery
            ? null
            : _effectiveDocumentType == InvoiceDocumentType.taxInvoiceReceipt
                ? DateTime.now()
                : _effectivePaymentDueDate,
        departureTime: departureTime,
        items: _items,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        createdAt: DateTime.now(),
        createdBy: userName,
        documentType: _effectiveDocumentType,
        deliveryPointId: widget.point.id,
        paymentMethod: _paymentMethod,
        status: InvoiceStatus.draft,
      );

      // Создаём сервис с companyId
      final invoiceService = InvoiceService(companyId: companyId);

      // 1. Создаём draft (или получаем ID существующего, если дубликат)
      final invoiceId = await invoiceService.createInvoice(invoice, userUid);

      // 2. Проверяем статус — если уже выпущен (idempotent duplicate), пропускаем issuance
      final existingInvoice = await invoiceService.getInvoice(invoiceId);
      final alreadyIssued = existingInvoice != null &&
          (existingInvoice.status == InvoiceStatus.active ||
              existingInvoice.status == InvoiceStatus.issued);

      IssuanceResult? issuanceResult;
      if (!alreadyIssued) {
        // 3. Вызываем серверную функцию issueInvoice (атомарно: номер + anchor + chain)
        issuanceResult = await IssuanceService().issueDocument(
          companyId: companyId,
          invoiceId: invoiceId,
          counterKey: _effectiveDocumentType.name,
        );

        if (!issuanceResult.ok) {
          throw Exception(l10n.serverIssuanceError);
        }
      }

      // Загружаем актуальный объект с номером и статусом issued
      final issuedInvoice = alreadyIssued
          ? existingInvoice
          : await invoiceService.getInvoice(invoiceId);

      if (mounted) {
        Navigator.pop(
            context, issuedInvoice ?? invoice.copyWith(id: invoiceId));
        final docNum = alreadyIssued
            ? (existingInvoice.sequentialNumber)
            : (issuanceResult?.docNumber ?? 0);
        final String successMsg;
        if (alreadyIssued) {
          successMsg = l10n.deliveryNoteAlreadyExists(docNum);
        } else if (_effectiveDocumentType == InvoiceDocumentType.delivery) {
          successMsg = l10n.deliveryNoteCreatedSuccess(docNum);
        } else if (_effectiveDocumentType ==
            InvoiceDocumentType.taxInvoiceReceipt) {
          successMsg = l10n.taxInvoiceReceiptCreatedSuccess(docNum);
        } else {
          successMsg = l10n.invoiceCreatedSuccess(docNum);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: alreadyIssued ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dispatcherGenericError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 16 : 40,
        vertical: 24,
      ),
      title: Text(widget.documentType == InvoiceDocumentType.delivery
          ? l10n.createDeliveryNoteTitle
          : l10n.createInvoiceTitle),
      content: SizedBox(
        width: narrow ? MediaQuery.sizeOf(context).width * 0.9 : 600,
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

                    // Срок оплаты (не для תעודת משלוח)
                    if (widget.documentType !=
                        InvoiceDocumentType.delivery) ...[
                      _buildPaymentTermSelector(),
                      const SizedBox(height: 16),
                    ],

                    // Таблица товаров
                    _buildItemsTable(),
                    const SizedBox(height: 16),

                    // Скидка и итоги (не для תעודת משלוח)
                    if (widget.documentType !=
                        InvoiceDocumentType.delivery) ...[
                      _buildDiscountField(),
                      const SizedBox(height: 16),

                      // Чекбокс "תשלום התקבל" + способ оплаты (только для invoice)
                      if (widget.documentType ==
                          InvoiceDocumentType.invoice) ...[
                        _buildPaymentReceivedSection(),
                        const SizedBox(height: 16),
                      ],

                      const Divider(),
                      _buildTotals(),
                    ],
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
          onPressed: _items.isEmpty ||
                  _isCreating ||
                  _periodLockError != null ||
                  _taxInvoiceReceiptBlocked
              ? null
              : _createInvoice,
          icon: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print),
          label: Text(_isCreating
              ? l10n.creatingDoc
              : widget.documentType == InvoiceDocumentType.delivery
                  ? l10n.createDeliveryNoteBtn
                  : l10n.createAndPrint),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.clientLabelColon} ${widget.point.clientName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('${l10n.addressLabelColon} ${widget.point.address}'),
        Text('${l10n.driverLabelColon} ${widget.driver.name}'),
        Text(
            '${l10n.truckLabelColon} ${widget.driver.vehicleNumber ?? l10n.notSpecified}'),
        Text(l10n.departureTimeValue),
      ],
    );
  }

  Widget _buildDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              l10n.deliveryDateLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deliveryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: Theme.of(context).primaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _deliveryDate = picked;
                    _validatePeriodLock();
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('dd/MM/yyyy').format(_deliveryDate)),
            ),
          ],
        ),
        if (_periodLockError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _periodLockError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentTermSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentTermsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 30, label: Text(l10n.days30)),
              ButtonSegment(value: 60, label: Text(l10n.days60)),
              ButtonSegment(value: 90, label: Text(l10n.days90)),
              ButtonSegment(value: -1, label: Text(l10n.manualEntry)),
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
        const SizedBox(height: 8),
        if (_customPaymentDate)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('${l10n.payUntilLabel} '),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _manualPaymentDate ??
                        _deliveryDate.add(const Duration(days: 30)),
                    firstDate: _deliveryDate,
                    lastDate: _deliveryDate.add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: Theme.of(context).primaryColor,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _manualPaymentDate = picked;
                    });
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
            '${l10n.payUntilLabel} ${DateFormat('dd/MM/yyyy').format(_effectivePaymentDueDate)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildItemsTable() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.items}:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 520),
            child: Table(
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l10n.itemLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l10n.cartonsLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l10n.pricePerUnitLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l10n.totalLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountField() {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(l10n.discountLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildPaymentReceivedSection() {
    final l10n = AppLocalizations.of(context)!;
    final taxInvoiceReceiptEnabled = AppConfig.enableTaxInvoiceReceipt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.paymentMethodLabel}:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _paymentMethod,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 'מזומן', child: Text(l10n.cash)),
            DropdownMenuItem(value: "צ'ק", child: Text(l10n.cheque)),
            DropdownMenuItem(
                value: 'העברה בנקאית', child: Text(l10n.bankTransfer)),
            DropdownMenuItem(
                value: 'כרטיס אשראי', child: Text(l10n.creditCard)),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _paymentMethod = val);
          },
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.paymentReceivedCheckbox,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: taxInvoiceReceiptEnabled ? null : Colors.grey,
            ),
          ),
          subtitle: Text(
            taxInvoiceReceiptEnabled
                ? l10n.paymentReceivedHint
                : '${l10n.paymentReceivedHint}\nUnder construction',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          value: taxInvoiceReceiptEnabled ? _paymentReceived : false,
          onChanged: taxInvoiceReceiptEnabled
              ? (val) => setState(() => _paymentReceived = val ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildTotals() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTotalRow(
          '${l10n.netBeforeVat}:',
          '₪${_subtotalBeforeVAT.toStringAsFixed(2)}',
          valueStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildTotalRow(
          '${l10n.vatLabelCalc} (18%):',
          '₪${_vatAmount.toStringAsFixed(2)}',
          valueStyle: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 2),
        _buildTotalRow(
          '${l10n.totalToPay}:',
          '₪${_totalWithVAT.toStringAsFixed(2)}',
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          valueStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 4,
      spacing: 12,
      children: [
        Text(label, style: labelStyle ?? const TextStyle(fontSize: 16)),
        Text(value, style: valueStyle ?? const TextStyle(fontSize: 16)),
      ],
    );
  }
}
