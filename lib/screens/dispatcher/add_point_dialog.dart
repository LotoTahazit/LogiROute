// lib/screens/dispatcher/add_point_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/client_model.dart';
import '../../models/delivery_point.dart';
import '../../services/client_service.dart';
import '../../services/route_service.dart';
import '../../services/api_config_service.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';

class AddPointDialog extends StatefulWidget {
  const AddPointDialog({super.key});

  @override
  State<AddPointDialog> createState() => _AddPointDialogState();
}

class _AddPointDialogState extends State<AddPointDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientService = ClientService();
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

  /// Генерирует множественные варианты адреса для геокодирования (подход как в Waze)
  List<String> _generateAddressVariants(String originalAddress) {
    List<String> variants = [];
    
    // 1. Как ввел пользователь (приоритет)
    variants.add(originalAddress);
    
    // 2. С добавлением страны на иврите
    variants.add('$originalAddress, ישראל');
    
    // 3. С добавлением страны на английском
    variants.add('$originalAddress, Israel');
    
    // 4. Стандартизация формата: номер дома, улица, город (как рекомендует Waze)
    String standardizedFormat = _standardizeAddressFormat(originalAddress);
    if (standardizedFormat != originalAddress) {
      variants.add(standardizedFormat);
      variants.add('$standardizedFormat, ישראל');
    }
    
    // 5. Попытка с разными городами (если не указан)
    if (!originalAddress.contains('תל אביב') && !originalAddress.contains('Tel Aviv')) {
      variants.add('$originalAddress, תל אביב, ישראל');
    }
    if (!originalAddress.contains('ירושלים') && !originalAddress.contains('Jerusalem')) {
      variants.add('$originalAddress, ירושלים, ישראל');
    }
    if (!originalAddress.contains('חיפה') && !originalAddress.contains('Haifa')) {
      variants.add('$originalAddress, חיפה, ישראל');
    }
    
    // 6. Упрощенный формат (только номер и улица)
    String simplified = _simplifyAddress(originalAddress);
    if (simplified != originalAddress) {
      variants.add(simplified);
      variants.add('$simplified, תל אביב, ישראל');
    }
    
    // 7. Транслитерация известных улиц (как запасной вариант)
    List<String> transliteratedVariants = _getTransliteratedVariants(originalAddress);
    variants.addAll(transliteratedVariants);
    
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
        String translated = address.replaceAll(hebrewStreet, streetTranslations[hebrewStreet]!);
        variants.add(translated);
        variants.add('$translated, Tel Aviv, Israel');
      }
    }
    
    return variants;
  }

  /// Геокодирование через Google Geocoding API напрямую (поддерживает иврит лучше)
  Future<Map<String, double>?> _geocodeViaGoogleAPI(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String url = '${ApiConfigService.googleGeocodingApiUrl}?address=$encodedAddress&key=${ApiConfigService.googleMapsApiKey}';
    
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
          final location = data['results'][0]['geometry']['location'];
          return {
            'latitude': location['lat'],
            'longitude': location['lng'],
          };
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
    _selectedClient = client;
    _numberController.text = client.clientNumber;
    _nameController.text = client.name;
    _addressController.text = client.address;
    _phoneController.text = client.phone ?? '';
    _contactController.text = client.contactPerson ?? '';
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
        
        // Сначала пробуем Google Geocoding API (лучше работает с ивритом)
        for (String variant in addressVariants) {
          debugPrint('🌐 [Google API] Trying variant: "$variant"');
          final result = await _geocodeViaGoogleAPI(variant);
          
          if (result != null) {
            latitude = result['latitude']!;
            longitude = result['longitude']!;
            debugPrint('✅ [Google API] Success with "$variant": ($latitude, $longitude)');
            geocodingSuccess = true;
            break;
          }
        }
        
        // Если Google API не помог, пробуем нативный geocoding (запасной вариант)
        if (!geocodingSuccess) {
          debugPrint('⚠️ [Geocoding] Google API failed, trying native geocoding...');
          for (String variant in addressVariants) {
            try {
              debugPrint('📱 [Native] Trying variant: "$variant"');
              final locations = await geocoding.locationFromAddress(variant);
              
              if (locations.isNotEmpty) {
                latitude = locations.first.latitude;
                longitude = locations.first.longitude;
                debugPrint('✅ [Native] Success with "$variant": ($latitude, $longitude)');
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
        debugPrint('❌ [Geocoding] All ${addressVariants.length} attempts failed for "$addressToGeocode": $e');
        debugPrint('🔍 [Geocoding] Tried variants: ${addressVariants.join(", ")}');
        
        // Показываем диалог с инструкциями
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.addressNotFound),
            content: Text(l10n.addressNotFoundDescription(_addressController.text)),
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
          );

      // Если клиента не было — добавляем в Firestore
      if (_selectedClient == null) {
        await _clientService.addClient(client);
      }

      final point = DeliveryPoint(
        id: '',
        clientName: client.name,
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
      );

      await _routeService.addDeliveryPoint(point);

      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${l10n.pointAdded}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
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
                  decoration: const InputDecoration(labelText: 'טלפון / Phone'),
                ),

                /// 🔹 Контактное лицо
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'איש קשר / Contact'),
                ),

                const SizedBox(height: 12),

                /// 🔹 Приоритет
                DropdownButtonFormField<String>(
                  value: _urgency,
                  decoration: const InputDecoration(labelText: 'Priority / עדיפות'),
                  items: [
                    DropdownMenuItem(value: 'normal', child: Text('Normal / רגיל')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent / דחוף')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _urgency = value);
                    }
                  },
                ),

                const SizedBox(height: 12),

                /// 🔹 Паллеты
                TextFormField(
                  controller: _palletsController,
                  decoration: InputDecoration(labelText: l10n.pallets),
                  keyboardType: TextInputType.number,
                ),

                /// 🔹 Коробки
                TextFormField(
                  controller: _boxesController,
                  decoration: InputDecoration(labelText: l10n.boxes),
                  keyboardType: TextInputType.number,
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
    );
  }
}
