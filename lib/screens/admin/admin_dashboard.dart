import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import 'analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _lastUpdatedText = '';
  String? _selectedDriverId;
  String? _selectedDriverName;

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
    setState(() {
      _users = users;
      _isLoading = false;
      _lastUpdatedText = '🕓 ${TimeOfDay.now().format(context)}';
    });
  }

  String _getLocalizedRole(String role, AppLocalizations l10n) {
    switch (role) {
      case 'admin':
        return l10n.roleAdmin;
      case 'dispatcher':
        return l10n.roleDispatcher;
      case 'driver':
        return l10n.roleDriver;
      default:
        return role;
    }
  }

  Future<void> _showAddUserDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final companyIdController = TextEditingController();
    String selectedRole = 'driver';
    final palletCapacityController = TextEditingController();
    final truckWeightController = TextEditingController();

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
                  const SizedBox(height: 16),
                  TextField(
                    controller: companyIdController,
                    decoration: InputDecoration(
                      labelText: l10n.companyId ?? 'Company ID',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
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
        );
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      palletCapacityController.dispose();
      truckWeightController.dispose();
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

      if (role == 'driver') {
        if (palletCapacityStr.isNotEmpty) {
          palletCapacity = int.tryParse(palletCapacityStr) ?? 0;
        }
        if (truckWeightStr.isNotEmpty) {
          truckWeight = double.tryParse(truckWeightStr) ?? 4.0;
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

    // Получаем список водителей
    final drivers = _users.where((user) => user.role == 'driver').toList();

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
                    child: Row(
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
                                value: 'admin', child: Text(l10n.roleAdmin)),
                            DropdownMenuItem(
                                value: 'dispatcher',
                                child: Text(l10n.roleDispatcher)),
                            DropdownMenuItem(
                                value: 'driver', child: Text(l10n.roleDriver)),
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
                                    _selectedDriverId = selectedDriver['id'];
                                    _selectedDriverName =
                                        selectedDriver['name'];
                                  });
                                }
                              }
                            } else {
                              authService.setViewAsRole(value);
                              if (mounted) {
                                setState(() {
                                  _selectedDriverId = null;
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
                    child: _users.isEmpty
                        ? Center(
                            child: Text(l10n.noUsersFound),
                          )
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: Icon(
                                    user.role == 'driver'
                                        ? Icons.local_shipping
                                        : user.role == 'dispatcher'
                                            ? Icons.assignment
                                            : Icons.admin_panel_settings,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    '${user.email} • ${_getLocalizedRole(user.role, l10n)}',
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
