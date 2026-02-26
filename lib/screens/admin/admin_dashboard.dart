import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../services/company_selection_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/dialog_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../widgets/company_selector_widget.dart';
import 'widgets/admin_app_bar_actions.dart';
import 'widgets/user_list_widget.dart';
import 'widgets/admin_filters_widget.dart';
import 'dialogs/add_user_dialog.dart';
import 'dialogs/edit_user_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _lastUpdatedText = '';
  String? _selectedDriverName;
  String? _selectedCompanyFilter;
  List<String> _availableCompanies = [];

  // Сохраняем сервисы чтобы использовать в dispose
  CompanySelectionService? _companyService;

  @override
  void initState() {
    super.initState();
    _companyService = context.read<CompanySelectionService>();
    _loadUsers();
    _initializeCompanySelection();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _companyService?.addListener(_onCompanyChanged);
    });
  }

  @override
  void dispose() {
    _companyService?.removeListener(_onCompanyChanged);
    super.dispose();
  }

  void _onCompanyChanged() {
    if (!mounted) return;
    _loadUsers();
  }

  Future<void> _initializeCompanySelection() async {
    final authService = context.read<AuthService>();
    final companyService = context.read<CompanySelectionService>();

    final userModel = authService.userModel;
    if (userModel == null) {
      debugPrint(
          '⚠️ [AdminDashboard] userModel is null in _initializeCompanySelection');
      return;
    }

    if (userModel.isSuperAdmin) {
      await companyService.loadCompanies();
      if (companyService.selectedCompanyId != null) {
        authService.setVirtualCompanyId(companyService.selectedCompanyId);
      }
    } else {
      final companyId = userModel.companyId;
      if (companyId != null && companyId.isNotEmpty) {
        companyService.setDefaultCompany(companyId);
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final companyService = context.read<CompanySelectionService>();

    final users = await authService.getAllUsers();
    if (!mounted) return;

    final currentUser = authService.userModel;
    if (currentUser == null) return;

    var filteredUsers = currentUser.isSuperAdmin
        ? users
        : users.where((user) => user.isSuperAdmin != true).toList();

    if (currentUser.isSuperAdmin) {
      final selectedCompanyId = companyService.selectedCompanyId;
      if (selectedCompanyId != null) {
        filteredUsers = filteredUsers
            .where((user) => user.companyId == selectedCompanyId)
            .toList();
      }
    } else if (currentUser.companyId != null) {
      filteredUsers = filteredUsers
          .where((user) => user.companyId == currentUser.companyId)
          .toList();
    }

    final companies = currentUser.isSuperAdmin
        ? (filteredUsers
            .where((u) => u.companyId != null && u.companyId!.isNotEmpty)
            .map((u) => u.companyId ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort())
        : <String>[];

    setState(() {
      _users = filteredUsers;
      _availableCompanies = companies;
      _applyCompanyFilter();
      _isLoading = false;
      _lastUpdatedText = '🕓 ${TimeOfDay.now().format(context)}';
    });
  }

  void _applyCompanyFilter() {
    if (_selectedCompanyFilter == null || _selectedCompanyFilter == 'all') {
      _filteredUsers = _users;
    } else {
      _filteredUsers = _users
          .where((user) => user.companyId == _selectedCompanyFilter)
          .toList();
    }
  }

  Future<void> _showEditUserDialog(UserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final currentUser = authService.userModel;
    if (currentUser == null) return;

    if (!currentUser.isSuperAdmin && user.companyId != currentUser.companyId) {
      await DialogHelper.showInfo(
        context: context,
        title: l10n.error,
        content: l10n.noPermissionToEdit,
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        await _deleteUser(user.uid);
      } else if (result['action'] == 'update') {
        await _updateUser(
          user.uid,
          result['name'],
          result['email'],
          result['password'],
          result['role'],
          result['palletCapacity'],
          result['truckWeight'],
          result['vehicleNumber'],
        );
      }
    }
  }

  Future<void> _updateUser(
    String uid,
    String name,
    String email,
    String password,
    String role,
    String palletCapacityStr,
    String truckWeightStr,
    String vehicleNumberStr,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (name.isEmpty || email.isEmpty) {
      await DialogHelper.showInfo(
        context: context,
        title: l10n.error,
        content: l10n.fillAllFields,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();

      int? palletCapacity;
      double? truckWeight;
      String? vehicleNumber;

      if (role == 'driver') {
        if (palletCapacityStr.isNotEmpty) {
          palletCapacity = int.tryParse(palletCapacityStr);
        }
        if (truckWeightStr.isNotEmpty) {
          truckWeight = double.tryParse(truckWeightStr);
        }
        if (vehicleNumberStr.isNotEmpty) {
          vehicleNumber = vehicleNumberStr;
        }
      }

      final errorCode = await authService.updateUser(
        uid: uid,
        newEmail: email,
        newPassword: password.isNotEmpty ? password : null,
        newRole: role,
        newName: name,
        palletCapacity: palletCapacity,
        truckWeight: truckWeight,
        vehicleNumber: vehicleNumber,
      );

      if (errorCode == null) {
        await _loadUsers();
        if (mounted) {
          SnackbarHelper.showSuccess(context, l10n.userUpdated);
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, '${l10n.updateError}: $errorCode');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '${l10n.updateError}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();
      final errorCode = await authService.deleteUser(uid);

      if (errorCode == null) {
        await _loadUsers();
        if (mounted) {
          SnackbarHelper.showSuccess(context, l10n.userDeleted);
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, '${l10n.deleteError}: $errorCode');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, '${l10n.deleteError}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );

    if (result != null) {
      await _addUser(
        result['name'],
        result['email'],
        result['password'],
        result['companyId'],
        result['role'],
        result['palletCapacity'],
        result['truckWeight'],
        result['vehicleNumber'],
      );
    }
  }

  Future<void> _addUser(
    String name,
    String email,
    String password,
    String companyId,
    String role,
    String palletCapacityStr,
    String truckWeightStr,
    String vehicleNumberStr,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      await DialogHelper.showInfo(
        context: context,
        title: l10n.error,
        content: l10n.fillAllFields,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();

      int? palletCapacity;
      double? truckWeight;
      String? vehicleNumber;

      if (role == 'driver') {
        if (palletCapacityStr.isNotEmpty) {
          palletCapacity = int.tryParse(palletCapacityStr) ?? 0;
        }
        if (truckWeightStr.isNotEmpty) {
          truckWeight = double.tryParse(truckWeightStr) ?? 4.0;
        }
        if (vehicleNumberStr.isNotEmpty) {
          vehicleNumber = vehicleNumberStr;
        }
      }

      final errorCode = await authService.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        companyId: companyId,
        palletCapacity: palletCapacity,
        truckWeight: truckWeight,
        vehicleNumber: vehicleNumber,
      );

      if (errorCode == null) {
        await _loadUsers();
        // ✅ Обновляем список компаний для супер админа
        if (authService.userModel?.isSuperAdmin == true && mounted) {
          final companyService = context.read<CompanySelectionService>();
          await companyService.loadCompanies();
        }
        if (mounted) {
          SnackbarHelper.showSuccess(context, l10n.userAddedSuccessfully);
        }
      } else {
        String errorMessage = l10n.errorCreatingUser;
        switch (errorCode) {
          case 'email-already-in-use':
            errorMessage = l10n.emailAlreadyInUse;
            break;
          case 'weak-password':
            errorMessage = l10n.weakPassword;
            break;
          case 'invalid-email':
            errorMessage = l10n.invalidEmail;
            break;
          default:
            errorMessage = '${l10n.error}: $errorCode';
        }
        if (mounted) {
          await DialogHelper.showInfo(
            context: context,
            title: l10n.error,
            content: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await DialogHelper.showInfo(
          context: context,
          title: l10n.error,
          content: '${l10n.errorCreatingUser}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, String>?> _showDriverSelectionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final drivers = _users.where((user) => user.isDriver).toList();

    if (drivers.isEmpty) {
      await DialogHelper.showInfo(
        context: context,
        title: l10n.error,
        content: l10n.noDriversAvailable,
      );
      return null;
    }

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.selectDriver}:'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.blue),
                title: Text(
                  driver.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.email),
                    if (driver.palletCapacity != null)
                      Text('${l10n.palletCapacity}: ${driver.palletCapacity}'),
                    if (driver.truckWeight != null)
                      Text(
                        '${l10n.truckWeight}: ${driver.truckWeight!.toStringAsFixed(1)}ט',
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context, {
                    'id': driver.uid,
                    'name': driver.name,
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final localeService = context.watch<LocaleService>();

    return Directionality(
      textDirection: localeService.locale.languageCode == 'he'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(l10n.admin),
              const SizedBox(width: 16),
              const CompanySelectorWidget(),
            ],
          ),
          backgroundColor: Colors.blue,
          elevation: 0,
          actions: [
            AdminAppBarActions(
              onAddUser: _showAddUserDialog,
              onRefresh: _loadUsers,
              isLoading: _isLoading,
              authService: authService,
              localeService: localeService,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  AdminFiltersWidget(
                    authService: authService,
                    viewAsRole: authService.viewAsRole,
                    selectedDriverName: _selectedDriverName,
                    selectedCompanyFilter: _selectedCompanyFilter,
                    availableCompanies: _availableCompanies,
                    totalUsers: _users.length,
                    lastUpdatedText: _lastUpdatedText,
                    onViewAsRoleChanged: (role) async {
                      if (role != null && role.startsWith('driver:')) {
                        // ✅ Формат: "driver:id:name" - водитель уже выбран
                        final parts = role.split(':');
                        final driverId = parts[1];
                        final driverName = parts.sublist(2).join(':');
                        if (mounted) {
                          setState(() {
                            _selectedDriverName = driverName;
                          });
                        }
                        authService.setViewAsRole(
                          'driver',
                          driverId: driverId,
                        );
                      } else {
                        authService.setViewAsRole(role);
                        if (mounted) {
                          setState(() {
                            _selectedDriverName = null;
                          });
                        }
                      }
                    },
                    onCompanyFilterChanged: (companyId) {
                      setState(() {
                        _selectedCompanyFilter = companyId;
                        _applyCompanyFilter();
                      });
                    },
                    onDriverSelectionRequired: _showDriverSelectionDialog,
                  ),
                  Expanded(
                    child: UserListWidget(
                      users: _filteredUsers,
                      onUserTap: _showEditUserDialog,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
