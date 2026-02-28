import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/company_selection_service.dart';
import '../services/fcm_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/dispatcher/dispatcher_dashboard.dart';
import '../screens/driver/driver_dashboard.dart';
import '../screens/warehouse/warehouse_dashboard.dart';
import 'module_guard.dart';
import 'billing_guard.dart';

/// Единый роутер по ролям.
/// Заменяет switch в AuthWrapper — одна точка входа для всех ролей.
///
/// Логика:
/// - super_admin / admin → AdminDashboard (без billing guard)
/// - dispatcher → BillingGuard + ModuleGuard(logistics) + DispatcherDashboard
/// - driver → BillingGuard + ModuleGuard(logistics) + DriverDashboard
/// - warehouse_keeper → BillingGuard + ModuleGuard(warehouse) + WarehouseDashboard
/// - unknown → LoginScreen
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authService.currentUser == null) {
      return const LoginScreen();
    }

    // Auth user exists but no Firestore profile — account not provisioned
    if (authService.userModel == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'החשבון לא נמצא במערכת',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                authService.currentUser!.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => authService.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('יציאה'),
              ),
            ],
          ),
        ),
      );
    }

    // Initialize FCM for authenticated user
    FcmService().initialize(authService.currentUser!.uid);

    final role = authService.userRole;
    final viewAs = authService.viewAsRole ?? role;
    final companyService = context.read<CompanySelectionService>();
    final companyId = companyService.getEffectiveCompanyId(authService) ?? '';
    final isSuperAdmin = role == 'super_admin';

    return _routeForRole(
      viewAs: viewAs,
      companyId: companyId,
      isSuperAdmin: isSuperAdmin,
    );
  }

  Widget _routeForRole({
    required String? viewAs,
    required String companyId,
    required bool isSuperAdmin,
  }) {
    switch (viewAs) {
      case 'admin':
      case 'super_admin':
        return const AdminDashboard();

      case 'dispatcher':
        return BillingGuard(
          companyId: companyId,
          isSuperAdmin: isSuperAdmin,
          child: ModuleGuard(
            companyId: companyId,
            requiredModule: 'logistics',
            child: const DispatcherDashboard(),
          ),
        );

      case 'driver':
        return BillingGuard(
          companyId: companyId,
          isSuperAdmin: false,
          child: ModuleGuard(
            companyId: companyId,
            requiredModule: 'logistics',
            child: const DriverDashboard(),
          ),
        );

      case 'warehouse_keeper':
        return BillingGuard(
          companyId: companyId,
          isSuperAdmin: false,
          child: ModuleGuard(
            companyId: companyId,
            requiredModule: 'warehouse',
            child: const WarehouseDashboard(),
          ),
        );

      default:
        return const LoginScreen();
    }
  }
}
