import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client_model.dart';
import '../../models/delivery_point.dart';
import '../../models/box_type.dart';
import '../../services/client_service.dart';
import '../../services/route_service.dart';
import '../../services/web_geocoding_service.dart';
import '../../services/address_geocoding_service.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/box_type_selector.dart';
import '../shared/dialogs/create_client_dialog.dart';

class AddPointDialog extends StatefulWidget {
  const AddPointDialog({super.key});

  @override
  State<AddPointDialog> createState() => _AddPointDialogState();
}

class _AddPointDialogState extends State<AddPointDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _palletsController = TextEditingController();
  final TextEditingController _boxesController = TextEditingController();

  ClientModel? _selectedClient;
  bool _isLoading = false;
  List<ClientModel> _searchResults = [];
  String _urgency = 'normal';
  List<BoxType> _selectedBoxTypes = []; // Выбранные типы коробок
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateCalculatedFields();
  }

  /// Автоматически рассчитывает количество картонов и миштахов
  Future<void> _updateCalculatedFields() async {
    if (_selectedBoxTypes.isEmpty) {
      _palletsController.text = '0';
      _boxesController.text = '0';
      return;
    }

    try {
      // ✅ Используем CompanyContext для получения effectiveCompanyId
      final companyCtx = CompanyContext.of(context);
      final companyId = companyCtx.effectiveCompanyId ?? '';
      final inventoryService = InventoryService(companyId: companyId);
      final inventory = await inventoryService.getInventory();

      int fullPallets = 0; // Полные миштахи
      int remainderBoxes = 0; // Остатки коробок (не заполнившие целый миштах)
      int totalBoxes = 0;

      for (final boxType in _selectedBoxTypes) {
        // Находим товар в инвентаре
        final inventoryItem = inventory.firstWhere(
          (item) => item.type == boxType.type && item.number == boxType.number,
          orElse: () => throw Exception(
            'ITEM_NOT_FOUND:${boxType.type}:${boxType.number}',
          ),
        );

        final quantity = boxType.quantity;
        final perPallet = inventoryItem.quantityPerPallet;

        if (perPallet > 0) {
          fullPallets += quantity ~/ perPallet;
          remainderBoxes += quantity % perPallet;
        } else {
          remainderBoxes += quantity;
        }

        totalBoxes += quantity;

        debugPrint(
          '🔍 [Calc] ${boxType.type} ${boxType.number}: qty=$quantity, perPallet=$perPallet, full=${quantity ~/ (perPallet > 0 ? perPallet : 1)}, remainder=${perPallet > 0 ? quantity % perPallet : quantity}',
        );
      }

      // Остатки от всех товаров складываются на общие миштахи
      // До 20 шт остатков = 1 миштах (стандарт)
      int remainderPallets =
          remainderBoxes > 0 ? (remainderBoxes / 20).ceil() : 0;

      int totalPallets = fullPallets + remainderPallets;

      if (mounted) {
        debugPrint(
          '📊 [Calc] totalBoxes: $totalBoxes, fullPallets: $fullPallets, remainderBoxes: $remainderBoxes, totalPallets: $totalPallets',
        );
        setState(() {
          _palletsController.text = totalPallets.toString();
          _boxesController.text = totalBoxes.toString();
        });
      }
    } catch (e) {
      debugPrint('❌ [Calculation] Error calculating fields: $e');
    }
  }

  /// Address geocoding helpers moved to AddressGeocodingService

  /// Генерирует множественные варианты адреса для геокодирования (подход как в Waze)
  List<String> _generateAddressVariants(String originalAddress) {
    return AddressGeocodingService.generateAddressVariants(originalAddress);
  }

  /// Геокодирование через Google Geocoding API напрямую (поддерживает иврит лучше)
  Future<Map<String, double>?> _geocodeViaGoogleAPI(String address) async {
    return AddressGeocodingService.geocodeViaGoogleAPI(address);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Проверяет наличие дубликатов заказов для клиента
  /// Возвращает список совпадающих точек или пустой список
  Future<List<DeliveryPoint>> _checkForDuplicates(
      String clientNumber, String companyId) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore
        .collection('companies')
        .doc(companyId)
        .collection('logistics')
        .doc('_root')
        .collection('delivery_points');

    final List<DeliveryPoint> duplicates = [];

    try {
      // Проверяем только активные точки (pending/assigned/in_progress)
      // Без completedAt — дешевле индекс, быстрее запрос
      final activeSnapshot = await collection
          .where('clientNumber', isEqualTo: clientNumber)
          .where('status', whereIn: ['pending', 'assigned', 'in_progress'])
          .limit(10)
          .get();

      for (final doc in activeSnapshot.docs) {
        duplicates.add(DeliveryPoint.fromMap(doc.data(), doc.id));
      }
    } catch (e) {
      debugPrint('⚠️ [Duplicate Check] Error: $e');
    }

    return duplicates;
  }

  /// Проверяет совпадение товаров между текущим заказом и существующим
  bool _hasMatchingProducts(List<BoxType> current, List<BoxType>? existing) {
    if (existing == null || existing.isEmpty) return false;
    if (current.isEmpty) return false;

    // Полное совпадение: все товары и количества совпадают
    if (current.length != existing.length) return false;

    final currentSet =
        current.map((b) => '${b.type}|${b.number}|${b.quantity}').toSet();
    final existingSet =
        existing.map((b) => '${b.type}|${b.number}|${b.quantity}').toSet();

    return currentSet.difference(existingSet).isEmpty &&
        existingSet.difference(currentSet).isEmpty;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    _palletsController.dispose();
    _boxesController.dispose();
    super.dispose();
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) return;
    // ✅ Используем CompanyContext для получения effectiveCompanyId
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    final clientService = ClientService(companyId: companyId);
    final results = await clientService.searchClients(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _fillClientData(ClientModel client) {
    setState(() {
      _selectedClient = client;
      _numberController.text = client.clientNumber;
      _nameController.text = client.name;
      _addressController.text = client.address;
      _phoneController.text = client.phone ?? '';
      _contactController.text = client.contactPerson ?? '';
    });
  }

  Future<void> _savePoint() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';

    setState(() => _isLoading = true);
    try {
      double latitude = 0;
      double longitude = 0;

      // Если у клиента уже есть координаты — используем их
      if (_selectedClient != null &&
          _selectedClient!.latitude != 0 &&
          _selectedClient!.longitude != 0 &&
          _addressController.text.trim() == _selectedClient!.address) {
        latitude = _selectedClient!.latitude;
        longitude = _selectedClient!.longitude;
        debugPrint(
          '✅ [Geocoding] Using client coordinates: ($latitude, $longitude)',
        );
      } else {
        // Геокодирование адреса
        String addressToGeocode = _addressController.text.trim();
        List<String> addressVariants =
            []; // Вынесли в верхнюю область видимости

        try {
          // Пробуем геокодирование с разными вариантами адреса
          debugPrint('🗺️ [Geocoding] Original address: "$addressToGeocode"');

          // Профессиональный подход как в Waze - множественные варианты без привязки к языку
          addressVariants = _generateAddressVariants(addressToGeocode);

          bool geocodingSuccess = false;

          // На Web используем Google Maps JavaScript API (обходит CORS)
          if (kIsWeb) {
            debugPrint(
              '🌐 [Web] Using Google Maps JavaScript API (kIsWeb=true)...',
            );
            for (String variant in addressVariants) {
              debugPrint('🌐 [WebJS] Trying variant: "$variant"');
              try {
                final result = await WebGeocodingService.geocode(variant);

                if (result != null) {
                  latitude = result.latitude;
                  longitude = result.longitude;
                  debugPrint(
                    '✅ [WebJS] Success with "$variant": ($latitude, $longitude)',
                  );
                  geocodingSuccess = true;
                  break;
                } else {
                  debugPrint('❌ [WebJS] No result for "$variant"');
                }
              } catch (e) {
                debugPrint('❌ [WebJS] Exception for "$variant": $e');
              }
            }

            // На web НЕ используем fallback на native/REST API
            if (!geocodingSuccess) {
              debugPrint('❌ [Web] All WebJS geocoding attempts failed');
            }
          } else {
            // На мобильных платформах пробуем Google Geocoding API
            for (String variant in addressVariants) {
              debugPrint('🌐 [Google API] Trying variant: "$variant"');
              final result = await _geocodeViaGoogleAPI(variant);

              if (result != null) {
                latitude = result['latitude']!;
                longitude = result['longitude']!;
                debugPrint(
                  '✅ [Google API] Success with "$variant": ($latitude, $longitude)',
                );
                geocodingSuccess = true;
                break;
              }
            }
          }

          // Если Google API не помог, пробуем нативный geocoding (только для мобильных платформ)
          if (!geocodingSuccess && !kIsWeb) {
            debugPrint(
              '⚠️ [Geocoding] Google API failed, trying native geocoding...',
            );
            for (String variant in addressVariants) {
              try {
                debugPrint('📱 [Native] Trying variant: "$variant"');
                final locations = await geocoding.locationFromAddress(variant);

                if (locations.isNotEmpty) {
                  latitude = locations.first.latitude;
                  longitude = locations.first.longitude;
                  debugPrint(
                    '✅ [Native] Success with "$variant": ($latitude, $longitude)',
                  );
                  geocodingSuccess = true;
                  break;
                }
              } catch (e) {
                debugPrint('❌ [Native] Failed variant "$variant": $e');
                continue;
              }
            }
          }

          if (!geocodingSuccess) {
            throw Exception('All geocoding variants failed');
          }
        } catch (e) {
          // Логируем ошибку геокодирования
          debugPrint(
            '❌ [Geocoding] All ${addressVariants.length} attempts failed for "$addressToGeocode": $e',
          );
          debugPrint(
            '🔍 [Geocoding] Tried variants: ${addressVariants.join(", ")}',
          );

          // Показываем диалог с инструкциями
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.addressNotFound),
              content: Text(
                l10n.addressNotFoundDescription(_addressController.text),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.fixAddress),
                ),
              ],
            ),
          );

          // Обязательно прерываем операцию - никаких fallback координат!
          setState(() => _isLoading = false);
          return;
        }
      } // end else (geocoding)

      // Если клиент выбран — используем его, если нет — создаём нового
      ClientModel client = _selectedClient ??
          ClientModel(
            id: '',
            clientNumber: _numberController.text,
            name: _nameController.text,
            address: _addressController.text,
            latitude: latitude,
            longitude: longitude,
            phone: _phoneController.text,
            contactPerson: _contactController.text,
            companyId: companyId,
          );

      // Если клиента не было — добавляем в Firestore
      if (_selectedClient == null) {
        final clientService = ClientService(companyId: companyId);
        await clientService.addClient(client);
      }

      // Проверяем дубликаты заказов
      if (client.clientNumber.isNotEmpty) {
        final duplicates =
            await _checkForDuplicates(client.clientNumber, companyId);
        if (duplicates.isNotEmpty) {
          // Проверяем полное совпадение товаров
          final exactMatches = duplicates
              .where(
                (d) => _hasMatchingProducts(_selectedBoxTypes, d.boxTypes),
              )
              .toList();

          final hasExactMatch = exactMatches.isNotEmpty;

          if (mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      hasExactMatch ? Icons.warning : Icons.info_outline,
                      color: hasExactMatch ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text('⚠️ הזמנה כפולה אפשרית'),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasExactMatch
                            ? 'נמצאה הזמנה זהה לחלוטין עבור ${client.name}!'
                            : 'נמצאו הזמנות קיימות עבור ${client.name}:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasExactMatch
                              ? Colors.red
                              : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...duplicates.take(5).map((d) {
                        final statusText =
                            d.status == 'completed' ? 'הושלם' : 'פעיל';
                        final products = d.boxTypes
                                ?.map((b) =>
                                    '${b.type} ${b.number} x${b.quantity}')
                                .join(', ') ??
                            '';
                        final isExact =
                            _hasMatchingProducts(_selectedBoxTypes, d.boxTypes);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${isExact ? "🔴" : "🟡"} [$statusText] $products',
                            style: TextStyle(
                              fontSize: 13,
                              color: isExact ? Colors.red.shade700 : null,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text(
                        'בדוק שזו לא הזמנה כפולה!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('ביטול'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasExactMatch ? Colors.red : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('המשך בכל זאת'),
                  ),
                ],
              ),
            );

            if (proceed != true) {
              setState(() => _isLoading = false);
              return;
            }
          }
        }
      }

      // Проверяем доступность товара на складе
      if (_selectedBoxTypes.isNotEmpty) {
        final inventoryService = InventoryService(companyId: companyId);
        final availability = await inventoryService.checkAvailability(
          _selectedBoxTypes,
        );

        if (!availability['available']) {
          final insufficient = availability['insufficient'] as List<String>;

          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.insufficientStock),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cannotCreateOrderInsufficientStock,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...insufficient.map((item) {
                      // Проверяем, является ли это кодом ошибки
                      if (item.startsWith('Exception: ITEM_NOT_FOUND:')) {
                        final parts = item
                            .replaceFirst('Exception: ITEM_NOT_FOUND:', '')
                            .split(':');
                        if (parts.length == 2) {
                          return Text(
                              '• ${l10n.itemNotFoundInInventory}: ${parts[0]} ${parts[1]}');
                        }
                      } else if (item
                          .startsWith('Exception: PRODUCT_CODE_NOT_FOUND:')) {
                        final code = item.replaceFirst(
                            'Exception: PRODUCT_CODE_NOT_FOUND:', '');
                        return Text('• ${l10n.productCodeNotFound}: $code');
                      }

                      // Парсим данные: type|number|productCode|available|requested
                      final parts = item.split('|');
                      if (parts.length == 5) {
                        final type = parts[0];
                        final number = parts[1];
                        final productCode = parts[2];
                        final available = parts[3];
                        final requested = parts[4];

                        // Форматируем с локализацией
                        return Text(
                            '• $type $number (${l10n.productCode}: $productCode): ${l10n.available} $available, ${l10n.requested} $requested');
                      }
                      return Text('• $item');
                    }),
                    const SizedBox(height: 16),
                    Text(
                      l10n.pleaseContactWarehouseKeeper,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.understood),
                  ),
                ],
              ),
            );
          }

          setState(() => _isLoading = false);
          return; // Блокируем создание заказа
        }
      }

      final point = DeliveryPoint(
        id: '',
        companyId: companyId,
        clientName: client.name,
        clientNumber: client.clientNumber,
        address: client.address,
        latitude: latitude,
        longitude: longitude,
        pallets: int.tryParse(_palletsController.text) ?? 0,
        boxes: int.tryParse(_boxesController.text) ?? 0,
        urgency: _urgency,
        status: 'pending',
        driverId: null,
        driverName: null,
        driverCapacity: null,
        boxTypes: _selectedBoxTypes.isNotEmpty ? _selectedBoxTypes : null,
        eta: null,
      );

      final routeService = RouteService(companyId: companyId);
      await routeService.addDeliveryPoint(point);

      // Списываем товар со склада
      if (_selectedBoxTypes.isNotEmpty) {
        final inventoryService = InventoryService(companyId: companyId);
        final user = authService.userModel;
        await inventoryService.deductStock(
          _selectedBoxTypes,
          user?.name ?? 'Unknown',
          reason: 'order_creation',
        );
      }

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(SnackBar(content: Text('✅ ${l10n.pointAdded}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'NotoSansHebrew',
          fontFamilyFallback: const [
            'Noto Sans Hebrew',
            'NotoSansHebrew',
            'Arial',
          ],
        ),
      ),
      child: AlertDialog(
        title: Text(l10n.addPoint),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔹 Номер клиента
                  TextFormField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      labelText: l10n.clientNumberLabel,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchClients(_numberController.text),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.clientNumberRequired;
                      }
                      if (value.length != 6) {
                        return l10n.clientNumberLength;
                      }
                      return null;
                    },
                    onChanged: (val) {
                      if (val.length >= 2) _searchClients(val);
                    },
                  ),

                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final client = _searchResults[index];
                          return ListTile(
                            title: Text(
                              client.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${client.clientNumber} • ${client.address}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            onTap: () {
                              _fillClientData(client);
                              setState(() => _searchResults.clear());
                            },
                          );
                        },
                      ),
                    ),

                  /// 🔹 Кнопка создания нового клиента
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () async {
                        final companyCtx = CompanyContext.of(context);
                        final companyId = companyCtx.effectiveCompanyId ?? '';
                        final created = await showDialog<ClientModel>(
                          context: context,
                          builder: (_) =>
                              CreateClientDialog(companyId: companyId),
                        );
                        if (created != null && mounted) {
                          _fillClientData(created);
                        }
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: Text(l10n.createClient),
                    ),
                  ),

                  /// 🔹 Имя клиента
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.clientName),
                    validator: (value) =>
                        value == null || value.isEmpty ? l10n.required : null,
                    onChanged: (val) {
                      if (val.length >= 2) _searchClients(val);
                    },
                  ),

                  /// 🔹 Адрес
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: l10n.address),
                    validator: (value) =>
                        value == null || value.isEmpty ? l10n.required : null,
                  ),

                  /// 🔹 Телефон
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'טלפון / Phone',
                    ),
                  ),

                  /// 🔹 Контактное лицо
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'איש קשר / Contact',
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 Приоритет
                  DropdownButtonFormField<String>(
                    initialValue: _urgency,
                    decoration: const InputDecoration(
                      labelText: 'Priority / עדיפות',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('Normal / רגיל'),
                      ),
                      DropdownMenuItem(
                        value: 'urgent',
                        child: Text('Urgent / דחוף'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _urgency = value);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 Паллеты (автоматически рассчитываются, можно изменить)
                  TextFormField(
                    controller: _palletsController,
                    style: const TextStyle(
                      fontFamily: 'NotoSansHebrew',
                      fontFamilyFallback: [
                        'Noto Sans Hebrew',
                        'NotoSansHebrew',
                        'Arial',
                      ],
                    ),
                    decoration: InputDecoration(
                      labelText: '${l10n.pallets} (מחושב אוטומטית)',
                      labelStyle: const TextStyle(
                        fontFamily: 'NotoSansHebrew',
                        fontFamilyFallback: [
                          'Noto Sans Hebrew',
                          'NotoSansHebrew',
                          'Arial',
                        ],
                      ),
                      helperText: 'ניתן לערוך',
                      helperStyle: const TextStyle(
                        fontFamily: 'NotoSansHebrew',
                        fontFamilyFallback: [
                          'Noto Sans Hebrew',
                          'NotoSansHebrew',
                          'Arial',
                        ],
                      ),
                      suffixIcon: const Icon(
                        Icons.calculate_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  /// 🔹 Коробки (автоматически рассчитываются, можно изменить)
                  TextFormField(
                    controller: _boxesController,
                    style: const TextStyle(
                      fontFamily: 'NotoSansHebrew',
                      fontFamilyFallback: [
                        'Noto Sans Hebrew',
                        'NotoSansHebrew',
                        'Arial',
                      ],
                    ),
                    decoration: InputDecoration(
                      labelText: '${l10n.boxes} (מחושב אוטומטית)',
                      labelStyle: const TextStyle(
                        fontFamily: 'NotoSansHebrew',
                        fontFamilyFallback: [
                          'Noto Sans Hebrew',
                          'NotoSansHebrew',
                          'Arial',
                        ],
                      ),
                      helperText: 'ניתן לערוך',
                      helperStyle: const TextStyle(
                        fontFamily: 'NotoSansHebrew',
                        fontFamilyFallback: [
                          'Noto Sans Hebrew',
                          'NotoSansHebrew',
                          'Arial',
                        ],
                      ),
                      suffixIcon: const Icon(
                        Icons.calculate_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 Типы коробок
                  BoxTypeSelector(
                    selectedBoxTypes: _selectedBoxTypes,
                    onChanged: (boxTypes) {
                      setState(() {
                        _selectedBoxTypes = boxTypes;
                      });
                      _updateCalculatedFields(); // Автоматический пересчет
                      _scrollToBottom(); // Прокрутка вниз после добавления товара
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _savePoint,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
