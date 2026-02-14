import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../models/user_model.dart';
import '../../models/box_type.dart';
import '../../services/price_service.dart';
import '../../services/auth_service.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_print_service.dart';

class CreateStandaloneInvoiceDialog extends StatefulWidget {
  const CreateStandaloneInvoiceDialog({super.key});

  @override
  State<CreateStandaloneInvoiceDialog> createState() =>
      _CreateStandaloneInvoiceDialogState();
}

class _CreateStandaloneInvoiceDialogState
    extends State<CreateStandaloneInvoiceDialog> {
  final PriceService _priceService = PriceService();
  final AuthService _authService = AuthService();
  final InvoiceService _invoiceService = InvoiceService();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _truckNumberController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );

  late DateTime _deliveryDate;
  final List<InvoiceItem> _items = [];
  final Map<int, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    _deliveryDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientNumberController.dispose();
    _addressController.dispose();
    _driverNameController.dispose();
    _truckNumberController.dispose();
    _discountController.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddItemDialog(),
    );

    if (result != null) {
      final type = result['type'] as String;
      final number = result['number'] as String;
      final quantity = result['quantity'] as int;

      // Загружаем цену из базы
      final price = await _priceService.getPrice(type, number);
      final pricePerUnit = price?.priceBeforeVAT ?? 0.0;

      setState(() {
        _items.add(
          InvoiceItem(
            type: type,
            number: number,
            quantity: quantity,
            pricePerUnit: pricePerUnit,
          ),
        );
        // Создаём контроллер для цены
        _priceControllers[_items.length - 1] = TextEditingController(
          text: pricePerUnit.toStringAsFixed(2),
        );
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _priceControllers[index]?.dispose();
      _priceControllers.remove(index);
      _items.removeAt(index);
      // Переиндексируем контроллеры
      final newControllers = <int, TextEditingController>{};
      for (int i = 0; i < _items.length; i++) {
        newControllers[i] = _priceControllers[i + (i >= index ? 1 : 0)]!;
      }
      _priceControllers.clear();
      _priceControllers.addAll(newControllers);
    });
  }

  void _updateItemPrice(int index, double newPrice) {
    setState(() {
      _items[index] = InvoiceItem(
        type: _items[index].type,
        number: _items[index].number,
        quantity: _items[index].quantity,
        pricePerUnit: newPrice,
      );
    });
  }

  double get _subtotalBeforeVAT {
    final total = _items.fold(0.0, (sum, item) => sum + item.totalBeforeVAT);
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    return total - discount;
  }

  double get _vatAmount => _subtotalBeforeVAT * Invoice.VAT_RATE;
  double get _totalWithVAT => _subtotalBeforeVAT + _vatAmount;

  Future<void> _createInvoice() async {
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ נא למלא שם לקוח'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ נא להוסיף לפחות פריט אחד'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = _authService.userModel;

      final departureTime = DateTime(
        _deliveryDate.year,
        _deliveryDate.month,
        _deliveryDate.day,
        7,
        0,
      );

      final invoice = Invoice(
        id: '',
       