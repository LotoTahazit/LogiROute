import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
import '../features/owner_dashboard/widgets/owner_dashboard_shell.dart';

/// Единый роутер по ролям.
/// Заменяет switch в AuthWrapper — одна точка входа для всех ролей.
///
/// Логика:
/// - super_admin / admin → AdminDashboard (без billing guard)
/// - owner → BillingGuard + OwnerDashboardShell
/// - dispatcher → BillingGuard + ModuleGuard(logistics) + DispatcherDashboard
/// - driver → BillingGuard + ModuleGuard(logistics) + DriverDashboard
/// - warehouse_keeper → BillingGuard + ModuleGuard(warehouse) + WarehouseDashboard
/// - unknown → LoginScreen
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  String? _lastInitializedUid;

  void _initFcmIfNeeded(String uid) {
    if (_lastInitializedUid != uid) {
      _lastInitializedUid = uid;
      FcmService().initialize(uid);
    }
  }

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
                label: Text(AppLocalizations.of(context)!.logout),
              ),
            ],
          ),
        ),
      );
    }

    // Initialize FCM for authenticated user (only once per uid)
    _initFcmIfNeeded(authService.currentUser!.uid);

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
      case 'owner':
        return BillingGuard(
          companyId: companyId,
          isSuperAdmin: false,
          child: const OwnerDashboardShell(),
        );

      case 'accountant':
        return BillingGuard(
          companyId: companyId,
          isSuperAdmin: false,
          child: const OwnerDashboardShell(),
        );

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

      case 'pending':
        return const _PendingApprovalScreen();

      default:
        return const LoginScreen();
    }
  }
}

/// Экран ожидания одобрения — для пользователей с ролью 'pending'.
///
/// Показывается после регистрации, пока super_admin не назначит
/// компанию и роль.
class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final l10n = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top, size: 72, color: Colors.orange[400]),
                const SizedBox(height: 24),
                Text(
                  l10n.pendingApprovalTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.pendingApprovalBody,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => authService.signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
