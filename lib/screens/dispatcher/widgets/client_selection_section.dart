import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../l10n/app_localizations.dart';

/// Секция выбора клиента
class ClientSelectionSection extends StatelessWidget {
  final TextEditingController numberController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController contactController;
  final ClientModel? selectedClient;
  final List<ClientModel> searchResults;
  final Function(String query) onSearch;
  final Function(ClientModel client) onClientSelected;

  const ClientSelectionSection({
    super.key,
    required this.numberController,
    required this.nameController,
    required this.phoneController,
    required this.contactController,
    required this.selectedClient,
    required this.searchResults,
    required this.onSearch,
    required this.onClientSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פרטי לקוח', // Client Info
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: numberController,
          decoration: InputDecoration(
            labelText: l10n.clientNumber,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.search),
          ),
          onChanged: onSearch,
        ),
        if (searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final client = searchResults[index];
                return ListTile(
                  title: Text(client.name),
                  subtitle: Text('${client.clientNumber} • ${client.address}'),
                  onTap: () => onClientSelected(client),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.clientName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: l10n.phone,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: contactController,
          decoration: InputDecoration(
            labelText: l10n.contactPerson,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
