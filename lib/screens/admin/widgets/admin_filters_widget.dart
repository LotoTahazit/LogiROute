import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

/// Виджет фильтров админ-панели
class AdminFiltersWidget extends StatelessWidget {
  final AuthService authService;
  final String? viewAsRole;
  final String? selectedDriverName;
  final String? selectedCompanyFilter;
  final List<String> availableCompanies;
  final int totalUsers;
  final String lastUpdatedText;
  final Function(String? role) onViewAsRoleChanged;
  final Function(String? companyId) onCompanyFilterChanged;
  final Future<Map<String, String>?> Function() onDriverSelectionRequired;

  const AdminFiltersWidget({
    super.key,
    required this.authService,
    required this.viewAsRole,
    required this.selectedDriverName,
    required this.selectedCompanyFilter,
    required this.availableCompanies,
    required this.totalUsers,
    required this.lastUpdatedText,
    required this.onViewAsRoleChanged,
    required this.onCompanyFilterChanged,
    required this.onDriverSelectionRequired,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${l10n.viewAs}:',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: viewAsRole ?? 'admin',
                items: [
                  DropdownMenuItem(value: 'admin', child: Text(l10n.roleAdmin)),
                  DropdownMenuItem(
                      value: 'dispatcher', child: Text(l10n.roleDispatcher)),
                  const DropdownMenuItem(
                      value: 'warehouse_keeper',
                      child: Text('מחסנאי / Warehouse')),
                  DropdownMenuItem(
                      value: 'driver', child: Text(l10n.roleDriver)),
                ],
                onChanged: (value) async {
                  if (value == null) return;

                  if (value == 'driver') {
                    final selectedDriver = await onDriverSelectionRequired();
                    if (selectedDriver != null) {
                      // ✅ Передаём данные водителя через onViewAsRoleChanged
                      onViewAsRoleChanged(
                          'driver:${selectedDriver['id']}:${selectedDriver['name']}');
                    }
                    // Если пользователь отменил выбор - ничего не делаем
                  } else {
                    onViewAsRoleChanged(value);
                  }
                },
              ),
              const Spacer(),
              if (lastUpdatedText.isNotEmpty)
                Text(
                  '${l10n.lastUpdated}: $lastUpdatedText',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
            ],
          ),
          if (authService.userModel?.isSuperAdmin == true &&
              availableCompanies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${l10n.companyId}:',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCompanyFilter ?? 'all',
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('${l10n.total} ($totalUsers)'),
                      ),
                      ...availableCompanies.map((company) {
                        return DropdownMenuItem(
                          value: company,
                          child: Text(company),
                        );
                      }),
                    ],
                    onChanged: onCompanyFilterChanged,
                  ),
                ),
              ],
            ),
          ],
          if ((viewAsRole ?? 'admin') == 'driver' &&
              (selectedDriverName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.driver}: ${selectedDriverName ?? ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
