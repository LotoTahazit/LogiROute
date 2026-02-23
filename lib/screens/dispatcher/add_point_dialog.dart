// lib/screens/dispatcher/add_point_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/client_model.dart';
import '../../models/delivery_point.dart';
import '../../models/box_type.dart';
import '../../services/client_service.dart';
import '../../services/route_service.dart';
import '../../services/api_config_service.dart';
import '../../services/web_geocoding_service.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/box_type_selector.dart';

class AddPointDialog extends StatefulWidget {
  const AddPointDialog({super.key});

  @override
  State<AddPointDialog> createState() => _AddPointDialogState();
}

class _AddPointDialogState extends State<AddPointDialog> {
  final _formKey = GlobalKey<FormState>();
  late final ClientService _clientService;
  final _routeService = RouteService();

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

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final companyId = authService.userModel?.companyId ?? '';
    _clientService = ClientService(companyId: companyId);
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
      final inventoryService = InventoryService();
      final inventory = await inventoryService.getInventory();

      int totalPallets = 0;
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

        // Рассчитываем количество миштахов
        if (inventoryItem.quantityPerPallet > 0) {
          totalPallets += (quantity / inventoryItem.quantityPerPallet).ceil();
        }

        // Картоним = общее количество единиц товара (1 единица = 1 картон)
        totalBoxes += quantity;

        debugPrint(
          '🔍 [Calculation] Item: ${boxType.type} ${boxType.number}, quantity: $quantity',
        );
        debugPrint('✅ [Calculation] Added $quantity boxes (units) to total');
      }

      if (mounted) {
        debugPrint(
          '📊 [Calculation] Final totalBoxes: $totalBoxes, totalPallets: $totalPallets',
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

  /// Заменяет полные названия улиц на сокращения (как в Google Maps)
  String _applyStreetAbbreviations(String address) {
    String result = address;

    // 1. Известные сокращения (самые частые)
    final knownAbbreviations = {
      'בעל שם טוב': 'בעלש"ט',
      'הבעל שם טוב': 'הבעלש"ט',
      'בן גוריון': 'בן גוריון',
      'דוד המלך': 'דוד המלך',
    };

    for (final entry in knownAbbreviations.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // 2. Автоматические сокращения по правилам иврита
    // Паттерн: "слово1 слово2 слово3" → "слово1 первая_буква2"первая_буква3"
    // Например: "רבי עקיבא" → "רבי ע", "משה רבנו" → "משה ר"

    // Ищем паттерны типа "רבי X", "משה X", "אליהו X" и т.д.
    final patterns = [
      RegExp(r'רבי\s+(\S)(\S+)'), // רבי עקיבא → רבי ע
      RegExp(r'משה\s+(\S)(\S+)'), // משה רבנו → משה ר
      RegExp(r'אליהו\s+(\S)(\S+)'), // אליהו הנביא → אליהו ה
      RegExp(r'דוד\s+(\S)(\S+)'), // דוד המלך → דוד ה
      RegExp(r'שלמה\s+(\S)(\S+)'), // שלמה המלך → שלמה ה
      RegExp(r'יהודה\s+(\S)(\S+)'), // יהודה הלוי → יהודה ה
    ];

    for (final pattern in patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        final prefix = match.group(0)!.split(' ')[0]; // רבי, משה и т.д.
        final firstLetter = match.group(1)!; // Первая буква второго слова
        return '$prefix $firstLetter'; // רבי ע
      });
    }

    return result;
  }

  /// Генерирует множественные варианты адреса для геокодирования (подход как в Waze)
  List<String> _generateAddressVariants(String originalAddress) {
    List<String> variants = [];

    // 1. Как ввел пользователь (приоритет)
    variants.add(originalAddress);

    // 2. С сокращениями улиц (как в Google Maps)
    String abbreviated = _applyStreetAbbreviations(originalAddress);
    if (abbreviated != originalAddress) {
      variants.add(abbreviated);
    }

    // 3. С добавлением страны на иврите
    variants.add('$originalAddress, ישראל');
    if (abbreviated != originalAddress) {
      variants.add('$abbreviated, ישראל');
    }

    // 4. С добавлением страны на английском
    variants.add('$originalAddress, Israel');
    if (abbreviated != originalAddress) {
      variants.add('$abbreviated, Israel');
    }

    // 5. Стандартизация формата: номер дома, улица, город (как рекомендует Waze)
    String standardizedFormat = _standardizeAddressFormat(originalAddress);
    if (standardizedFormat != originalAddress) {
      variants.add(standardizedFormat);
      variants.add('$standardizedFormat, ישראל');

      // Со стандартизацией + сокращения
      String standardizedAbbreviated =
          _applyStreetAbbreviations(standardizedFormat);
      if (standardizedAbbreviated != standardizedFormat) {
        variants.add(standardizedAbbreviated);
        variants.add('$standardizedAbbreviated, ישראל');
      }
    }

    // 6. Попытка с разными городами (если не указан)
    // ✅ Холон первым (приоритет для Y.C. Plast)
    if (!originalAddress.contains('חולון') &&
        !originalAddress.contains('Holon')) {
      variants.add('$originalAddress, חולון, ישראל');
      if (abbreviated != originalAddress) {
        variants.add('$abbreviated, חולון, ישראל');
      }
    }
    if (!originalAddress.contains('ראשון לציון') &&
        !originalAddress.contains('Rishon')) {
      variants.add('$originalAddress, ראשון לציון, ישראל');
    }
    if (!originalAddress.contains('תל אביב') &&
        !originalAddress.contains('Tel Aviv')) {
      variants.add('$originalAddress, תל אביב, ישראל');
    }
    if (!originalAddress.contains('פתח תקווה') &&
        !originalAddress.contains('Petah Tikva')) {
      variants.add('$originalAddress, פתח תקווה, ישראל');
    }
    if (!originalAddress.contains('ירושלים') &&
        !originalAddress.contains('Jerusalem')) {
      variants.add('$originalAddress, ירושלים, ישראל');
    }
    if (!originalAddress.contains('חיפה') &&
        !originalAddress.contains('Haifa')) {
      variants.add('$originalAddress, חיפה, ישראל');
    }
    if (!originalAddress.contains('באר שבע') &&
        !originalAddress.contains('Beer Sheva')) {
      variants.add('$originalAddress, באר שבע, ישראל');
    }

    // 7. Упрощенный формат (только номер и улица)
    String simplified = _simplifyAddress(originalAddress);
    if (simplified != originalAddress) {
      variants.add(simplified);
      variants.add('$simplified, תל אביב, ישראל');

      // Упрощенный + сокращения
      String simplifiedAbbreviated = _applyStreetAbbreviations(simplified);
      if (simplifiedAbbreviated != simplified) {
        variants.add(simplifiedAbbreviated);
        variants.add('$simplifiedAbbreviated, תל אביב, ישראל');
      }
    }

    // 7.5. Убираем префиксы "רחוב", "שדרות" и пробуем снова
    String withoutPrefix = originalAddress
        .replaceAll('רחוב ', '')
        .replaceAll('רח\' ', '')
        .replaceAll('שדרות ', '')
        .replaceAll('שד\' ', '')
        .trim();

    if (withoutPrefix != originalAddress) {
      variants.add(withoutPrefix);
      variants.add('$withoutPrefix, ישראל');

      // С сокращениями без префикса
      String withoutPrefixAbbr = _applyStreetAbbreviations(withoutPrefix);
      if (withoutPrefixAbbr != withoutPrefix) {
        variants.add(withoutPrefixAbbr);
        variants.add('$withoutPrefixAbbr, ישראל');
      }
    }

    // 8. Транслитерация известных улиц (как запасной вариант)
    List<String> transliteratedVariants = _getTransliteratedVariants(
      originalAddress,
    );
    variants.addAll(transliteratedVariants);

    debugPrint(
        '🔍 [Address Variants] Generated ${variants.length} variants for "$originalAddress"');
    if (abbreviated != originalAddress) {
      debugPrint(
          '✂️ [Abbreviation] Applied: "$originalAddress" → "$abbreviated"');
    }

    // Удаляем дубликаты и возвращаем
    return variants.toSet().toList();
  }

  /// Стандартизирует формат адреса: номер дома, улица, город
  String _standardizeAddressFormat(String address) {
    // Ищем номер дома в начале
    RegExp houseNumberRegex = RegExp(r'^(\d+)\s*(.+)$');
    Match? match = houseNumberRegex.firstMatch(address);

    if (match != null) {
      String number = match.group(1)!;
      String rest = match.group(2)!.trim();
      return '$number $rest';
    }

    return address;
  }

  /// Упрощает адрес до минимума: номер дома и улица
  String _simplifyAddress(String address) {
    // Убираем лишние слова
    String simplified = address
        .replaceAll(RegExp(r'\s*,\s*'), ' ')
        .replaceAll('רחוב', '')
        .replaceAll('שדרות', '')
        .replaceAll('רח', '')
        .replaceAll('שד', '')
        .trim();

    return simplified;
  }

  /// Возвращает варианты с транслитерацией известных улиц
  List<String> _getTransliteratedVariants(String address) {
    List<String> variants = [];

    // Словарь известных улиц и их транслитераций
    Map<String, String> streetTranslations = {
      'רחוב החלוצים': 'HaHalutzim Street',
      'רחוב הכרמל': 'Carmel Street',
      'רחוב דיזנגוף': 'Dizengoff Street',
      'רחוב הרצל': 'Herzl Street',
      'שדרות בן גוריון': 'Ben Gurion Boulevard',
      'רחוב אלנבי': 'Allenby Street',
      'רחוב רוטשילד': 'Rothschild Boulevard',
      'שדרות': 'Boulevard',
    };

    for (String hebrewStreet in streetTranslations.keys) {
      if (address.contains(hebrewStreet)) {
        String translated = address.replaceAll(
          hebrewStreet,
          streetTranslations[hebrewStreet]!,
        );
        variants.add(translated);
        variants.add('$translated, Tel Aviv, Israel');
      }
    }

    return variants;
  }

  /// Геокодирование через Google Geocoding API напрямую (поддерживает иврит лучше)
  Future<Map<String, double>?> _geocodeViaGoogleAPI(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String url =
        '${ApiConfigService.googleGeocodingApiUrl}?address=$encodedAddress&key=${ApiConfigService.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        AppConfig.geocodingTimeout,
        onTimeout: () {
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final formattedAddress = result['formatted_address'] as String;

          // ✅ ПРОВЕРКА: Логируем полный адрес от Google
          debugPrint('🗺️ [Google API] Input: "$address"');
          debugPrint('🗺️ [Google API] Result: "$formattedAddress"');
          debugPrint(
              '🗺️ [Google API] Coords: (${location['lat']}, ${location['lng']})');

          // ✅ ПРОВЕРКА: Если в запросе был конкретный город, проверяем что результат содержит этот город
          final cityChecks = {
            'חולון': ['חולון', 'Holon'],
            'Holon': ['חולון', 'Holon'],
            'ראשון לציון': ['ראשון לציון', 'Rishon'],
            'Rishon': ['ראשון לציון', 'Rishon'],
            'תל אביב': ['תל אביב', 'Tel Aviv'],
            'Tel Aviv': ['תל אביב', 'Tel Aviv'],
            'פתח תקווה': ['פתח תקווה', 'Petah Tikva'],
            'Petah Tikva': ['פתח תקווה', 'Petah Tikva'],
          };

          for (final entry in cityChecks.entries) {
            if (address.contains(entry.key)) {
              final cityFound =
                  entry.value.any((city) => formattedAddress.contains(city));
              if (!cityFound) {
                debugPrint(
                    '⚠️ [Google API] WARNING: Requested ${entry.key} but got: $formattedAddress');
                return null; // Пропускаем неправильный результат
              }
            }
          }

          return {'latitude': location['lat'], 'longitude': location['lng']};
        } else {
          debugPrint('❌ [Google API] Status: ${data['status']}');
        }
      } else {
        debugPrint('❌ [Google API] HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Google API] Error: $e');
    }

    return null;
  }

  @override
  void dispose() {
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
    final results = await _clientService.searchClients(query);
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

    setState(() => _isLoading = true);
    try {
      double latitude = 0;
      double longitude = 0;

      // Геокодирование адреса
      String addressToGeocode = _addressController.text.trim();
      List<String> addressVariants = []; // Вынесли в верхнюю область видимости

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
        final l10n = AppLocalizations.of(context)!;
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

      // Если клиент выбран — используем его, если нет — создаём нового
      final authService = context.read<AuthService>();
      final companyId = authService.userModel?.companyId ?? '';

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
        await _clientService.addClient(client);
      }

      // Проверяем доступность товара на складе
      if (_selectedBoxTypes.isNotEmpty) {
        final inventoryService = InventoryService();
        final availability = await inventoryService.checkAvailability(
          _selectedBoxTypes,
        );

        if (!availability['available']) {
          final insufficient = availability['insufficient'] as List<String>;
          final l10n = AppLocalizations.of(context)!;

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

      await _routeService.addDeliveryPoint(point);

      // Списываем товар со склада
      if (_selectedBoxTypes.isNotEmpty) {
        final inventoryService = InventoryService();
        final authService = AuthService();
        final user = authService.userModel;
        await inventoryService.deductStock(
          _selectedBoxTypes,
          user?.name ?? 'Unknown',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ ${l10n.pointAdded}')));
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
