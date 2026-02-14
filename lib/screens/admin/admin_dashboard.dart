import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import 'analytics_screen.dart';
import 'migration_screen.dart';

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
  String? _selectedCompanyFilter; // Фильтр по компании
  List<String> _availableCompanies = []; // Список доступных компаний

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final users = await authService.getAllUsers();
    if (!mounted) return;

    print('🔍 [Admin] Total users loaded: ${users.length}');
    for (final user in users) {
      print(
          '  - ${user.name} (${user.email}): role=${user.role}, companyId=${user.companyId}, isDriver=${user.isDriver}');
    }

    final currentUser = authService.userModel;
    if (currentUser == null) return;

    print(
        '🔍 [Admin] Current user: ${currentUser.name}, isSuperAdmin=${currentUser.isSuperAdmin}, companyId=${currentUser.companyId}');

    // Фильтруем суперадминов ТОЛЬКО если текущий пользователь НЕ суперадмин
    var filteredUsers = currentUser.isSuperAdmin
        ? users // Суперадмин видит всех
        : users
            .where((user) => user.isSuperAdmin != true)
            .toList(); // Обычный админ не видит суперадминов

    print('🔍 [Admin] After filtering super admins: ${filteredUsers.length}');

    // Если обычный админ - показываем только его компанию
    if (!currentUser.isSuperAdmin && currentUser.companyId != null) {
      filteredUsers = filteredUsers
          .where((user) => user.companyId == currentUser.companyId)
          .toList();
      print('🔍 [Admin] After filtering by company: ${filteredUsers.length}');
    }

    // Собираем уникальные компании (только для суперадмина)
    final companies = currentUser.isSuperAdmin
        ? (filteredUsers
            .where((u) => u.companyId != null && u.companyId!.isNotEmpty)
            .map((u) => u.companyId!)
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

  String _getLocalizedRole(String role, AppLocalizations l10n) {
    switch (role) {
      case 'admin':
        return l10n.roleAdmin;
      case 'dispatcher':
        return l10n.roleDispatcher;
      case 'driver':
        return l10n.roleDriver;
      case 'warehouse_keeper':
        return 'מחסנאי / Warehouse Keeper';
      default:
        return role;
    }
  }

  Future<void> _showEditUserDialog(UserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();

    // Проверка прав
    final currentUser = authService.userModel;
    if (currentUser == null) return;

    if (!currentUser.isSuperAdmin && user.companyId != currentUser.companyId) {
      _showErrorDialog(l10n.noPermissionToEdit);
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();
    String selectedRole = user.role;
    final palletCapacityController = TextEditingController(
      text: user.palletCapacity?.toString() ?? '',
    );
    final truckWeightController = TextEditingController(
      text: user.truckWeight?.toString() ?? '',
    );
    final vehicleNumberController = TextEditingController(
      text: user.vehicleNumber ?? '',
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.editUser(user.name)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: '${l10n.password} (${l10n.leaveEmptyToKeep})',
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: l10n.role,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'driver', child: Text(l10n.driver)),
                      DropdownMenuItem(
                          value: 'dispatcher', child: Text(l10n.dispatcher)),
                      const DropdownMenuItem(
                          value: 'warehouse_keeper',
                          child: Text('מחסנאי / Warehouse Keeper')),
                      DropdownMenuItem(
                          value: 'admin', child: Text(l10n.systemManager)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value ?? 'driver';
                      });
                    },
                  ),
                  if (selectedRole == 'driver') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: vehicleNumberController,
                      decoration: InputDecoration(
                        labelText: l10n.vehicleNumber,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: palletCapacityController,
                      decoration: InputDecoration(
                        labelText: l10n.palletCapacity,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: truckWeightController,
                      decoration: InputDecoration(
                        labelText: l10n.truckWeight,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.delete),
                      content: Text(l10n.deleteUser(user.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );

                  if (confirmDelete == true && context.mounted) {
                    Navigator.pop(context, false);
                    await _deleteUser(user.uid);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.delete),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );

      if (result == true) {
        await _updateUser(
          user.uid,
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text.trim(),
          selectedRole,
          palletCapacityController.text.trim(),
          truckWeightController.text.trim(),
          vehicleNumberController.text.trim(),
        );
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      palletCapacityController.dispose();
      truckWeightController.dispose();
      vehicleNumberController.dispose();
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
      _showErrorDialog(l10n.fillAllFields);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog('${l10n.updateError}: $errorCode');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('${l10n.updateError}: $e');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userDeleted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog('${l10n.deleteError}: $errorCode');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('${l10n.deleteError}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final currentUser = authService.userModel;
    if (currentUser == null) return;

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final companyIdController = TextEditingController();
    final vehicleNumberController = TextEditingController();
    String selectedRole = 'driver';
    final palletCapacityController = TextEditingController();
    final truckWeightController = TextEditingController();

    // Для обычного админа - используем его companyId
    final bool isSuperAdmin = currentUser.isSuperAdmin;
    if (!isSuperAdmin && currentUser.companyId != null) {
      companyIdController.text = currentUser.companyId!;
    }

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.addNewUser),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  // Поле companyId только для суперадмина
                  if (isSuperAdmin) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: companyIdController,
                      decoration: InputDecoration(
                        labelText: l10n.companyId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: l10n.role,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'driver', child: Text(l10n.driver)),
                      DropdownMenuItem(
                        value: 'dispatcher',
                        child: Text(l10n.dispatcher),
                      ),
                      const DropdownMenuItem(
                        value: 'warehouse_keeper',
                        child: Text('מחסנאי / Warehouse Keeper'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(l10n.systemManager),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value ?? 'driver';
                      });
                    },
                  ),
                  if (selectedRole == 'driver') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: vehicleNumberController,
                      decoration: InputDecoration(
                        labelText: l10n.vehicleNumber,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: palletCapacityController,
                      decoration: InputDecoration(
                        labelText: l10n.palletCapacity,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: truckWeightController,
                      decoration: InputDecoration(
                        labelText: l10n.truckWeight,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.add),
              ),
            ],
          ),
        ),
      );

      if (result == true) {
        await _addUser(
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text,
          companyIdController.text.trim(),
          selectedRole,
          palletCapacityController.text.trim(),
          truckWeightController.text.trim(),
          vehicleNumberController.text.trim(),
        );
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      companyIdController.dispose();
      palletCapacityController.dispose();
      truckWeightController.dispose();
      vehicleNumberController.dispose();
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
      _showErrorDialog(l10n.fillAllFields);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();
      // companyId теперь приходит из формы

      // Парсим дополнительные поля для водителей
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

      // Создаем пользователя через существующий метод
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
        // Обновляем список пользователей
        await _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userAddedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
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
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('${l10n.errorCreatingUser}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showDriverSelectionDialog() async {
    final l10n = AppLocalizations.of(context)!;

    // Получаем список водителей (проверяем isDriver вместо role)
    final drivers = _users.where((user) => user.isDriver).toList();

    if (drivers.isEmpty) {
      _showErrorDialog(l10n.noDriversAvailable);
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
                          '${l10n.truckWeight}: ${driver.truckWeight!.toStringAsFixed(1)}ט'),
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
          title: Text(l10n.admin),
          backgroundColor: Colors.blue,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.addUser,
              onPressed: _showAddUserDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              onPressed: _isLoading ? null : _loadUsers,
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: l10n.analytics,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Data Migration',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MigrationScreen()),
                );
              },
            ),
            PopupMenuButton<String>(
              tooltip: l10n.settings,
              onSelected: (value) {
                if (value == 'logout') {
                  authService.signOut();
                } else if (value == 'he' || value == 'ru' || value == 'en') {
                  localeService.setLocale(value);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'he', child: Text(l10n.hebrew)),
                PopupMenuItem(value: 'ru', child: Text(l10n.russian)),
                PopupMenuItem(value: 'en', child: Text(l10n.english)),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '${l10n.viewAs}:',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(width: 16),
                            DropdownButton<String>(
                              value: authService.viewAsRole ?? 'admin',
                              items: [
                                DropdownMenuItem(
                                    value: 'admin',
                                    child: Text(l10n.roleAdmin)),
                                DropdownMenuItem(
                                    value: 'dispatcher',
                                    child: Text(l10n.roleDispatcher)),
                                const DropdownMenuItem(
                                    value: 'warehouse_keeper',
                                    child: Text('מחסנאי / Warehouse')),
                                DropdownMenuItem(
                                    value: 'driver',
                                    child: Text(l10n.roleDriver)),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;

                                if (value == 'driver') {
                                  final selectedDriver =
                                      await _showDriverSelectionDialog();
                                  if (selectedDriver != null) {
                                    authService.setViewAsRole(value,
                                        driverId: selectedDriver['id']);
                                    if (mounted) {
                                      setState(() {
                                        _selectedDriverName =
                                            selectedDriver['name'];
                                      });
                                    }
                                  }
                                } else {
                                  authService.setViewAsRole(value);
                                  if (mounted) {
                                    setState(() {
                                      _selectedDriverName = null;
                                    });
                                  }
                                }
                              },
                            ),
                            const Spacer(),
                            if (_lastUpdatedText.isNotEmpty)
                              Text(
                                '${l10n.lastUpdated}: $_lastUpdatedText',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                          ],
                        ),
                        // Фильтр по компаниям (только для суперадмина)
                        if (authService.userModel?.isSuperAdmin == true &&
                            _availableCompanies.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${l10n.companyId}:',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _selectedCompanyFilter ?? 'all',
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(
                                          '${l10n.total} (${_users.length})'),
                                    ),
                                    ..._availableCompanies.map((company) {
                                      final count = _users
                                          .where((u) => u.companyId == company)
                                          .length;
                                      return DropdownMenuItem(
                                        value: company,
                                        child: Text('$company ($count)'),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCompanyFilter = value;
                                      _applyCompanyFilter();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if ((authService.viewAsRole ?? 'admin') == 'driver' &&
                      (_selectedDriverName ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${l10n.driver}: ${_selectedDriverName ?? ''}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? Center(
                            child: Text(l10n.noUsersFound),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  onTap: () => _showEditUserDialog(user),
                                  leading: Icon(
                                    user.role == 'driver'
                                        ? Icons.local_shipping
                                        : user.role == 'dispatcher'
                                            ? Icons.assignment
                                            : user.role == 'warehouse_keeper'
                                                ? Icons.inventory_2
                                                : Icons.admin_panel_settings,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    '${user.email} • ${_getLocalizedRole(user.role, l10n)}${user.role == 'driver' && user.vehicleNumber != null ? ' • 🚗 ${user.vehicleNumber}' : ''}',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  trailing: user.role == 'driver'
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (user.palletCapacity != null)
                                              Text(
                                                '${user.palletCapacity} ${l10n.pallets}',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (user.truckWeight != null)
                                              Text(
                                                '${user.truckWeight!.toStringAsFixed(1)}ט',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
