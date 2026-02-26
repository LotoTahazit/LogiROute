import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

/// Диалог добавления нового пользователя
class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyIdController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _palletCapacityController = TextEditingController();
  final _truckWeightController = TextEditingController();
  String _selectedRole = 'driver';

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final currentUser = authService.userModel;
    if (currentUser != null &&
        !currentUser.isSuperAdmin &&
        currentUser.companyId != null) {
      _companyIdController.text = currentUser.companyId ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyIdController.dispose();
    _vehicleNumberController.dispose();
    _palletCapacityController.dispose();
    _truckWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final isSuperAdmin = authService.userModel?.isSuperAdmin ?? false;

    return AlertDialog(
      title: Text(l10n.addNewUser),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.password,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            if (isSuperAdmin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _companyIdController,
                decoration: InputDecoration(
                  labelText: l10n.companyId,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: l10n.role,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'driver', child: Text(l10n.driver)),
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
                  _selectedRole = value ?? 'driver';
                });
              },
            ),
            if (_selectedRole == 'driver') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _vehicleNumberController,
                decoration: InputDecoration(
                  labelText: l10n.vehicleNumber,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _palletCapacityController,
                decoration: InputDecoration(
                  labelText: l10n.palletCapacity,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _truckWeightController,
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
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'companyId': _companyIdController.text.trim(),
              'role': _selectedRole,
              'palletCapacity': _palletCapacityController.text.trim(),
              'truckWeight': _truckWeightController.text.trim(),
              'vehicleNumber': _vehicleNumberController.text.trim(),
            });
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
