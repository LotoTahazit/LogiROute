import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async' show unawaited;
import 'package:provider/provider.dart';
import '../../core/correlation/correlation_context.dart';
import '../../models/client_model.dart';
import '../../models/usage_event.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/firestore_paths.dart';
import '../../services/client_import_service.dart';
import '../../services/import/import_mapping_wizard_launcher.dart';
import '../../models/import_wizard_type.dart';
import '../../services/client_regeocode_service.dart';
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
  final bool embedded;
  final String? companyId;
  final bool openImportOnReady;

  const ClientManagementScreen({
    super.key,
    this.embedded = false,
    this.companyId,
    this.openImportOnReady = false,
  });

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  ClientService? _clientService;
  String? _resolvedCompanyId;
  bool _importPromptShown = false;
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _searchMode = false;
  DocumentSnapshot<Map<String, dynamic>>? _lastClientDoc;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureClientService();
  }

  void _ensureClientService() {
    final companyId = widget.companyId ??
        CompanyContext.of(context).effectiveCompanyId ??
        '';
    if (companyId.isEmpty || companyId == _resolvedCompanyId) return;
    _resolvedCompanyId = companyId;
    _clientService = ClientService(companyId: companyId);
    _loadClients();
  }

  void _maybeOpenImportFromWizard() {
    if (!widget.openImportOnReady || _importPromptShown || _isLoading) {
      return;
    }
    _importPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _importClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients({bool reset = true}) async {
    final service = _clientService;
    if (service == null) {
      setState(() => _isLoading = false);
      return;
    }
    if (reset) {
      setState(() {
        _isLoading = true;
        _lastClientDoc = null;
        _hasMore = false;
        _searchMode = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await service.getClientsPage(
        limit: ClientService.defaultPageSize,
        startAfter: reset ? null : _lastClientDoc,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _clients = page.clients;
        } else {
          _clients = [..._clients, ...page.clients];
        }
        _filteredClients = _clients;
        _lastClientDoc = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoading = false;
        _loadingMore = false;
      });
      _maybeOpenImportFromWizard();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingMore = false;
      });
      if (mounted) {
        SnackbarHelper.showError(context, 'Error loading clients: $e');
      }
    }
  }

  Future<void> _loadMoreClients() async {
    if (!_hasMore || _loadingMore || _searchMode) return;
    await _loadClients(reset: false);
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) {
      await _loadClients();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _clientService!.searchClients(query, null, 50);
      setState(() {
        _searchMode = true;
        _filteredClients = results;
        _hasMore = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterClients(String query) {
    if (query.length >= 2) {
      _searchClients(query);
      return;
    }
    if (_searchMode) {
      _loadClients();
      return;
    }
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
        await _clientService!.updateClient(client.id, result);
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
        await _clientService!.deleteClient(client.id);
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
    final companyId = widget.companyId ??
        _resolvedCompanyId ??
        CompanyContext.of(context).effectiveCompanyId ??
        '';
    if (companyId.isEmpty) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          AppLocalizations.of(context)!.noCompanySelected,
        );
      }
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final result = await ClientImportService.pickAndParse(context);
    if (result.error != null) {
      if (mounted) {
        final msg = result.error == 'read_failed'
            ? l10n.importFileReadFailed
            : l10n.importFileParseFailed;
        SnackbarHelper.showError(context, msg);
      }
      return;
    }
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

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final trace = correlationIf(
      operation: CorrelatedOperation.importExcel,
      companyId: companyId,
      userId: userId,
    );
    final role = context.read<AuthService>().userModel?.role ?? 'unknown';
    final validRows = rows.where((r) => r.isValid).length;
    unawaited(trace?.trackPilot(
      UsageEventName.importStarted,
      role: role,
      metadata: {'source': 'clients', 'rows': validRows},
    ));

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

        await _clientService!.addClient(client);
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
              await _clientService!.updateClientByNumber(
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
      unawaited(trace?.trackPilot(
        UsageEventName.importCompleted,
        role: role,
        metadata: {
          'source': 'clients',
          'added': added,
          'updated': updated,
          'skipped': skipped,
          'errors': errors.length,
        },
      ));
      await trace?.audit(
        moduleKey: 'logistics',
        type: 'data_imported',
        entityCollection: 'clients',
        entityDocId: 'clients_import',
        extra: {'added': added, 'updated': updated, 'skipped': skipped, 'errors': errors.length},
      );
      final msg = updated > 0
          ? l10n.importClientResultUpdated(
              added, updated, skipped, errors.length)
          : l10n.importClientResultMessage(added, skipped, errors.length);
      SnackbarHelper.showSuccess(context, msg);
      _loadClients();
    }
  }

  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      downloadFile(
        ClientImportService.createTemplate(),
        'clients_import_template.xlsx',
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, l10n.templateDownloadedSuccess);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '${l10n.error}: $e');
      }
    }
  }

  Future<void> _exportClients() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportToExcelMenu),
        content: Text(l10n.exportLargeDatasetWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final trace = correlationIf(
      operation: CorrelatedOperation.exportExcel,
      companyId: companyId,
      userId: userId,
    );
    final role = context.read<AuthService>().userModel?.role ?? 'unknown';
    unawaited(trace?.trackPilot(
      UsageEventName.exportStarted,
      role: role,
      metadata: {'source': 'clients'},
    ));
    trace?.log('exportClients start');

    final all = await _clientService!.fetchAllClientsForExport();
    if (all.isEmpty) return;
    if (all.length > 2000 && mounted) {
      SnackbarHelper.showError(context, l10n.exportLargeDatasetNotice(all.length));
    }
    final data = all
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
    downloadFile(ClientImportService.exportClients(data), 'clients_export.xlsx');
    await trace?.audit(
      moduleKey: 'logistics',
      type: 'data_exported',
      entityCollection: 'clients',
      entityDocId: 'clients_export',
      extra: {'count': all.length},
    );
    if (mounted) {
      SnackbarHelper.showSuccess(context, l10n.fileExportedSuccess);
    }
  }

  Future<void> _regeocodeAllClients() async {
    final l10n = AppLocalizations.of(context)!;
    final companyId = CompanyContext.of(context).effectiveCompanyId ?? '';
    if (companyId.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.regeocodeAllClientsMenu),
        content: Text(l10n.regeocodeAllClientsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final progress = ValueNotifier<(int, int)>((0, 1));
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.regeocodeAllClientsMenu),
        content: ValueListenableBuilder<(int, int)>(
          valueListenable: progress,
          builder: (_, value, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: value.$2 > 0 ? value.$1 / value.$2 : null,
              ),
              const SizedBox(height: 12),
              Text(l10n.regeocodeAllClientsProgress(value.$1, value.$2)),
            ],
          ),
        ),
      ),
    );

    ClientRegeocodeReport? report;
    try {
      report = await ClientRegeocodeService(companyId: companyId).regeocodeAll(
        onProgress: (d, t) => progress.value = (d, t),
      );
    } catch (e) {
      progress.dispose();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        SnackbarHelper.showError(context, '$e');
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
    SnackbarHelper.showSuccess(
      context,
      l10n.regeocodeAllClientsResult(
        report.updated,
        report.unchanged,
        report.failed,
        report.skippedNoAddress,
        report.pointsUpdated,
      ),
    );
    _loadClients();
  }

  Widget _buildMenuButton(BuildContext context, bool isAdmin) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'import') _importClients();
        if (value == 'import_wizard') {
          ImportMappingWizardLauncher.open(
            context,
            initialType: ImportWizardType.clients,
          );
        }
        if (value == 'export') _exportClients();
        if (value == 'template') _downloadTemplate();
        if (value == 'regeocode') _regeocodeAllClients();
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
        PopupMenuItem(
          value: 'import_wizard',
          child: Row(children: [
            const Icon(Icons.auto_fix_high),
            const SizedBox(width: 8),
            Text(l10n.importWizardMenu),
          ]),
        ),
        if (kIsWeb && isAdmin)
          PopupMenuItem(
            value: 'regeocode',
            child: Row(children: [
              const Icon(Icons.my_location),
              const SizedBox(width: 8),
              Text(l10n.regeocodeAllClientsMenu),
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
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
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
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.noClientsFound),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: _importClients,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(l10n.importFromExcelMenu),
                                ),
                                if (kIsWeb)
                                  OutlinedButton.icon(
                                    onPressed: _downloadTemplate,
                                    icon: const Icon(Icons.file_download),
                                    label: Text(l10n.downloadTemplateMenu),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(client.address),
                                      if (client.phone != null &&
                                          client.phone!.isNotEmpty)
                                        Text('📞 ${client.phone}'),
                                      if (client.zones.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              ZoneUtils.buildZoneDots(
                                                  client.zones),
                                              const SizedBox(width: 4),
                                              Text(
                                                client.zones
                                                    .map((z) =>
                                                        ZoneUtils.getZoneName(
                                                            z,
                                                            Localizations.localeOf(
                                                                    context)
                                                                .languageCode))
                                                    .join(', '),
                                                style: const TextStyle(
                                                    fontSize: 11),
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
                        if (_hasMore && !_searchMode)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: OutlinedButton.icon(
                              onPressed:
                                  _loadingMore ? null : _loadMoreClients,
                              icon: _loadingMore
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: Text(l10n.reportsLoadMore),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = CompanyContext.of(context).currentUser?.isAdmin ?? false;

    if (_clientService == null) {
      final noCompany = Center(child: Text(l10n.noCompanySelected));
      if (widget.embedded) return noCompany;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clientManagement)),
        body: noCompany,
      );
    }

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Icon(Icons.people_outline,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.clientManagement,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                _buildMenuButton(context, isAdmin),
              ],
            ),
          ),
          Expanded(child: _buildContent(context)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientManagement),
        actions: [_buildMenuButton(context, isAdmin)],
      ),
      body: _buildContent(context),
    );
  }
}
