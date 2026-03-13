import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/admin/billing/billing_portal_screen.dart';

/// Module access denied screen
class ModuleAccessDenied extends StatelessWidget {
  final String moduleName;
  final String? description;

  const ModuleAccessDenied({
    super.key,
    required this.moduleName,
    this.description,
  });

  String _getModuleTitle(String module, AppLocalizations l10n) {
    switch (module) {
      case 'warehouse':
        return l10n.moduleWarehouseTitle;
      case 'logistics':
        return l10n.moduleLogisticsTitle;
      case 'dispatcher':
        return l10n.moduleDispatcherTitle;
      case 'accounting':
        return l10n.moduleAccountingTitle;
      case 'reports':
        return l10n.moduleReportsTitle;
      default:
        return module;
    }
  }

  IconData _getModuleIcon(String module) {
    switch (module) {
      case 'warehouse':
        return Icons.warehouse;
      case 'logistics':
        return Icons.local_shipping;
      case 'dispatcher':
        return Icons.map;
      case 'accounting':
        return Icons.receipt_long;
      case 'reports':
        return Icons.analytics;
      default:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getModuleIcon(moduleName),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.lock_outline,
              size: 32,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getModuleTitle(moduleName, l10n),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description ?? l10n.moduleNotAvailable,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BillingPortalScreen()),
                );
              },
              icon: const Icon(Icons.upgrade),
              label: Text(l10n.upgradePlanButton),
            ),
          ],
        ),
      ),
    );
  }
}
