import 'package:flutter/material.dart';

/// Экран "Модуль недоступен" — показывается когда модуль отключён по тарифу
class ModuleAccessDenied extends StatelessWidget {
  final String moduleName;
  final String? description;

  const ModuleAccessDenied({
    super.key,
    required this.moduleName,
    this.description,
  });

  String _getModuleTitle(String module) {
    switch (module) {
      case 'warehouse':
        return 'מחסן — Warehouse';
      case 'logistics':
        return 'לוגיסטיקה — Logistics';
      case 'dispatcher':
        return 'דיספצ\'ר — Dispatcher';
      case 'accounting':
        return 'הנהלת חשבונות — Accounting';
      case 'reports':
        return 'דוחות — Reports';
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
              _getModuleTitle(moduleName),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description ?? 'מודול זה אינו זמין בתוכנית הנוכחית שלך',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: навигация к странице тарифов
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('שדרג תוכנית'),
            ),
          ],
        ),
      ),
    );
  }
}
