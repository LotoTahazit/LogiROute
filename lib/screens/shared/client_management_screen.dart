import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../services/web_geocoding_service.dart';
import '../../l10n/app_localizations.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final ClientService _clientService = ClientService();
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _clientService.getAllClients();
      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          return client.name.toLowerCase().contains(query.toLowerCase()) ||
              client.clientNumber.contains(query) ||
              client.address.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _editClient(ClientModel client) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<ClientModel>(
      context: context,
      builder: (context) => _EditClientDialog(client: client),
    );

    if (result != null) {
      try {
        await _clientService.updateClient(client.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clientUpdated),
              backgroundColor: Colors.green,
            ),
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteClient(ClientModel client) async {
    final l10n = AppLocalizations.of(context)!;

    // Подтверждение удаления
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.delete} ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _clientService.deleteClient(client.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${client.name} ${l10n.delete}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientManagement),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.search,
                hintText: l10n.searchClientHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterClients,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? Center(child: Text(l10n.noClientsFound))
                    : ListView.builder(
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(client.clientNumber),
                              ),
                              title: Text(
                                client.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client.address),
                                  if (client.phone != null &&
                                      client.phone!.isNotEmpty)
                                    Text('📞 ${client.phone}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editClient(client),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteClient(client),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _EditClientDialog extends StatefulWidget {
  final ClientModel client;

  const _EditClientDialog({required this.client});

  @override
  State<_EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<_EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _contactController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isGeocoding = false;
  bool _manualCoordinates = false;

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

  /// Генерирует варианты адреса с сокращениями
  List<String> _generateAddressVariants(String originalAddress) {
    List<String> variants = [];

    // 1. Оригинальный адрес
    variants.add(originalAddress);

    // 2. С сокращениями
    String abbreviated = _applyStreetAbbreviations(originalAddress);
    if (abbreviated != originalAddress) {
      variants.add(abbreviated);
      debugPrint('✂️ [Abbreviation] "$originalAddress" → "$abbreviated"');
    }

    // 3. С добавлением страны
    variants.add('$originalAddress, ישראל');
    if (abbreviated != originalAddress) {
      variants.add('$abbreviated, ישראל');
    }

    // 4. Убираем префиксы "רחוב", "שדרות" и пробуем снова
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

    return variants;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _numberController = TextEditingController(text: widget.client.clientNumber);
    _addressController = TextEditingController(text: widget.client.address);
    _phoneController = TextEditingController(text: widget.client.phone ?? '');
    _contactController =
        TextEditingController(text: widget.client.contactPerson ?? '');
    _latitudeController =
        TextEditingController(text: widget.client.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.client.longitude.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() => _isGeocoding = true);

    try {
      double latitude;
      double longitude;
      String addressToGeocode = _addressController.text.trim();

      // Если включен ручной режим - используем введенные координаты
      if (_manualCoordinates) {
        latitude = double.parse(_latitudeController.text);
        longitude = double.parse(_longitudeController.text);
        debugPrint(
            '✅ [Edit Client] Using manual coordinates: ($latitude, $longitude)');
      } else {
        latitude = widget.client.latitude;
        longitude = widget.client.longitude;

        // ✅ ОПТИМИЗАЦИЯ: Геокодируем ТОЛЬКО если адрес изменился
        final addressChanged = addressToGeocode != widget.client.address;

        if (addressChanged) {
          debugPrint(
              '🗺️ [Edit Client] Address changed, geocoding: "$addressToGeocode"');

          // Генерируем варианты адреса с сокращениями
          final addressVariants = _generateAddressVariants(addressToGeocode);
          debugPrint(
              '🔍 [Edit Client] Generated ${addressVariants.length} variants');

          bool geocodingSuccess = false;

          // Используем тот же метод геокодирования что и в add_point_dialog
          try {
            // На Web используем Google Maps JavaScript API
            if (kIsWeb) {
              for (String variant in addressVariants) {
                debugPrint('🌐 [WebJS] Trying variant: "$variant"');
                final result = await WebGeocodingService.geocode(variant);

                if (result != null) {
                  latitude = result.latitude;
                  longitude = result.longitude;
                  debugPrint(
                    '✅ [Edit Client] Success with "$variant": ($latitude, $longitude)',
                  );
                  // Обновляем поля координат
                  _latitudeController.text = latitude.toString();
                  _longitudeController.text = longitude.toString();
                  geocodingSuccess = true;
                  break;
                }
              }

              if (!geocodingSuccess) {
                throw Exception('All variants failed');
              }
            } else {
              // На мобильных используем нативный geocoding
              for (String variant in addressVariants) {
                try {
                  debugPrint('📱 [Native] Trying variant: "$variant"');
                  final locations =
                      await geocoding.locationFromAddress(variant);

                  if (locations.isNotEmpty) {
                    latitude = locations.first.latitude;
                    longitude = locations.first.longitude;
                    debugPrint(
                      '✅ [Edit Client] Success with "$variant": ($latitude, $longitude)',
                    );
                    // Обновляем поля координат
                    _latitudeController.text = latitude.toString();
                    _longitudeController.text = longitude.toString();
                    geocodingSuccess = true;
                    break;
                  }
                } catch (e) {
                  debugPrint('❌ [Native] Failed variant "$variant": $e');
                  continue;
                }
              }

              if (!geocodingSuccess) {
                throw Exception('All variants failed');
              }
            }
          } catch (e) {
            debugPrint('❌ [Edit Client] Geocoding failed: $e');

            if (mounted) {
              // Предлагаем ввести координаты вручную
              final useManual = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.addressNotFound),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addressNotFoundDescription(
                            _addressController.text),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Вы можете ввести координаты вручную или исправить адрес.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.fixAddress),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ввести координаты вручную'),
                    ),
                  ],
                ),
              );

              if (useManual == true) {
                setState(() {
                  _manualCoordinates = true;
                  _isGeocoding = false;
                });
                return;
              }
            }

            setState(() => _isGeocoding = false);
            return;
          }
        } else {
          debugPrint(
              '✅ [Edit Client] Address unchanged, keeping coordinates: ($latitude, $longitude)');
        }
      }

      final updatedClient = ClientModel(
        id: widget.client.id,
        clientNumber: _numberController.text,
        name: _nameController.text,
        address: _addressController.text,
        latitude: latitude,
        longitude: longitude,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        contactPerson:
            _contactController.text.isEmpty ? null : _contactController.text,
      );

      if (mounted) {
        Navigator.pop(context, updatedClient);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.geocodingError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editClient),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    labelText: l10n.clientNumber,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.clientName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    border: const OutlineInputBorder(),
                    helperText: l10n.addressWillBeGeocoded,
                  ),
                  maxLines: 2,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: l10n.contactPerson,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Переключатель ручного ввода координат
                SwitchListTile(
                  title: const Text('Ввести координаты вручную'),
                  subtitle:
                      const Text('Используйте если геокодирование не работает'),
                  value: _manualCoordinates,
                  onChanged: (value) {
                    setState(() => _manualCoordinates = value);
                  },
                ),
                if (_manualCoordinates) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Широта (Latitude)',
                      border: OutlineInputBorder(),
                      helperText: 'Например: 31.9539907',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.required;
                      if (double.tryParse(value!) == null) {
                        return 'Введите число';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Долгота (Longitude)',
                      border: OutlineInputBorder(),
                      helperText: 'Например: 34.8062546',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.required;
                      if (double.tryParse(value!) == null) {
                        return 'Введите число';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGeocoding ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isGeocoding ? null : _saveClient,
          child: _isGeocoding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
