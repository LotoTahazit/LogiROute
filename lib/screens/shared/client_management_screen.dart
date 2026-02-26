import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/dialog_helper.dart';
import '../../l10n/app_localizations.dart';
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
      try {
        await _clientService.updateClient(client.id, result);
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
