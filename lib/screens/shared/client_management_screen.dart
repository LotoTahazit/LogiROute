import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../services/firestore_paths.dart';
import '../../services/client_import_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/zone_utils.dart';
import '../../utils/file_download.dart';
import '../../utils/geocoding_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/import_preview_dialog.dart';
import '../../widgets/column_mapping_dialog.dart';
import 'dialogs/edit_client_dialog.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  late final ClientService _clientService;
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    _clientService = ClientService(companyId: companyId);
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
        SnackbarHelper.showError(context, 'Error loading clients: $e');
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
      builder: (context) => EditClientDialog(client: client),
    );

    if (result != null) {
      if (!mounted) return;
      final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
      try {
        await _clientService.updateClient(client.id, result);
        if (!mounted) return;

        // Если координаты или адрес изменились — обновить все активные точки доставки
        final coordsChanged = client.latitude != result.latitude ||
            client.longitude != result.longitude;
        final addressChanged = client.address != result.address;
        if ((coordsChanged || addressChanged) &&
            result.clientNumber.isNotEmpty) {
          final points = await FirestorePaths.deliveryPointsOf(companyId)
              .where('clientNumber', isEqualTo: result.clientNumber)
              .where('status',
                  whereIn: ['pending', 'assigned', 'in_progress']).get();
          if (!mounted) return;
          for (final doc in points.docs) {
            await doc.reference.update({
              'latitude': result.latitude,
              'longitude': result.longitude,
              'address': result.address,
            });
          }
          debugPrint(
              '\ud83d\udccd [Client] Updated ${points.docs.length} active points: coords=($coordsChanged) address=($addressChanged)');
        }

        if (mounted) {
          SnackbarHelper.showSuccess(context, l10n.clientUpdated);
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error: $e');
        }
      }
    }
  }

  Future<void> _deleteClient(ClientModel client) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await DialogHelper.showDeleteConfirmation(
      context: context,
      title: l10n.delete,
      content: '${l10n.delete} ${client.name}?',
    );

    if (confirm == true) {
      try {
        await _clientService.deleteClient(client.id);
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            '${client.name} ${l10n.delete}',
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error: $e');
        }
      }
    }
  }

  Future<void> _importClients() async {
    final companyCtx = CompanyContext.of(context);
    final companyId = companyCtx.effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final result = await ClientImportService.pickAndParse(context);
    final rows = result.rows;
    if (rows == null || !mounted) return;

    final previewRows = rows
        .map((r) => ImportPreviewRow(
              rowIndex: r.rowIndex,
              values: [
                r.clientNumber,
                r.name,
                r.address,
                r.phone ?? '',
                r.zones.join(','),
              ],
              errors: r.errors,
            ))
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ImportPreviewDialog(
        title: l10n.importClientsTitle,
        columns: [
          l10n.colClientNumber,
          l10n.colName,
          l10n.colAddress,
          l10n.colPhone,
          l10n.colZones
        ],
        rows: previewRows,
      ),
    );
    if (confirmed != true || !mounted) return;

    int added = 0;
    int skipped = 0;
    int updated = 0;
    final errors = <String>[];
    final duplicateMode = result.duplicateMode;

    for (final row in rows.where((r) => r.isValid)) {
      try {
        double lat = row.latitude ?? 0;
        double lng = row.longitude ?? 0;

        // Geocode if no coordinates provided
        if (lat == 0 && lng == 0 && row.address.isNotEmpty) {
          final geo = await GeocodingHelper.geocodeAddress(row.address);
          if (geo != null) {
            lat = geo['latitude']!;
            lng = geo['longitude']!;
          }
        }

        final client = ClientModel(
          id: '',
          clientNumber: row.clientNumber,
          name: row.name,
          address: row.address,
          latitude: lat,
          longitude: lng,
          phone: row.phone,
          contactPerson: row.contactPerson,
          vatId: row.vatId,
          companyId: companyId,
          zones: row.zones,
        );

        await _clientService.addClient(client);
        added++;
      } catch (e) {
        if (e.toString().contains('DUPLICATE')) {
          if (duplicateMode == DuplicateMode.update) {
            try {
              double lat = row.latitude ?? 0;
              double lng = row.longitude ?? 0;
              if (lat == 0 && lng == 0 && row.address.isNotEmpty) {
                final geo = await GeocodingHelper.geocodeAddress(row.address);
                if (geo != null) {
                  lat = geo['latitude']!;
                  lng = geo['longitude']!;
                }
              }
              await _clientService.updateClientByNumber(
                companyId: companyId,
                clientNumber: row.clientNumber,
                name: row.name,
                address: row.address,
                latitude: lat,
                longitude: lng,
                phone: row.phone,
                contactPerson: row.contactPerson,
                vatId: row.vatId,
                zones: row.zones,
              );
              updated++;
            } catch (e2) {
              errors.add(l10n.importRowError(row.rowIndex, e2.toString()));
            }
          } else {
            skipped++;
          }
        } else {
          errors.add(l10n.importRowError(row.rowIndex, e.toString()));
        }
      }
    }

    if (mounted) {
      final msg = updated > 0
          ? l10n.importClientResultUpdated(
              added, updated, skipped, errors.length)
          : l10n.importClientResultMessage(added, skipped, errors.length);
      SnackbarHelper.showSuccess(context, msg);
      _loadClients();
    }
  }

  Future<void> _exportClients() async {
    if (_clients.isEmpty) return;
    final data = _clients
        .map((c) => {
              'clientNumber': c.clientNumber,
              'name': c.name,
              'address': c.address,
              'phone': c.phone ?? '',
              'contactPerson': c.contactPerson ?? '',
              'vatId': c.vatId ?? '',
              'zones': c.zones,
              'latitude': c.latitude,
              'longitude': c.longitude,
            })
        .toList();
    final bytes = ClientImportService.exportClients(data);
    downloadFile(bytes, 'clients_export.xlsx');
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showSuccess(context, l10n.fileExportedSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientManagement),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import') _importClients();
              if (value == 'export') _exportClients();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'import',
                child: Row(children: [
                  const Icon(Icons.upload_file),
                  const SizedBox(width: 8),
                  Text(l10n.importFromExcelMenu),
                ]),
              ),
              if (kIsWeb)
                PopupMenuItem(
                  value: 'export',
                  child: Row(children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text(l10n.exportToExcelMenu),
                  ]),
                ),
              if (kIsWeb)
                PopupMenuItem(
                  value: 'template',
                  child: Row(children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 8),
                    Text(l10n.downloadTemplateMenu),
                  ]),
                ),
            ],
          ),
        ],
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
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ZoneUtils.buildZoneStripe(client.zones,
                                      height: 44),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    child: Text(client.clientNumber),
                                  ),
                                ],
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
                                  if (client.zones.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          ZoneUtils.buildZoneDots(client.zones),
                                          const SizedBox(width: 4),
                                          Text(
                                            client.zones
                                                .map((z) =>
                                                    ZoneUtils.getZoneName(
                                                        z, 'he'))
                                                .join(', '),
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
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
