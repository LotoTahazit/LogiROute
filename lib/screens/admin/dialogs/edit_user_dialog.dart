import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/dialog_helper.dart';

/// Диалог редактирования пользователя
class EditUserDialog extends StatefulWidget {
  final UserModel user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _palletCapacityController;
  late final TextEditingController _truckWeightController;
  late final TextEditingController _vehicleNumberController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _selectedRole = widget.user.role;
    _palletCapacityController = TextEditingController(
      text: widget.user.palletCapacity?.toString() ?? '',
    );
    _truckWeightController = TextEditingController(
      text: widget.user.truckWeight?.toString() ?? '',
    );
    _vehicleNumberController = TextEditingController(
      text: widget.user.vehicleNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _palletCapacityController.dispose();
    _truckWeightController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editUser(widget.user.name)),
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
                labelText: '${l10n.password} (${l10n.leaveEmptyToKeep})',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
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
        TextButton(
          onPressed: () async {
            final confirmed = await DialogHelper.showDeleteConfirmation(
              context: context,
              title: l10n.delete,
              content: l10n.deleteUser(widget.user.name),
            );

            if (confirmed && context.mounted) {
              Navigator.pop(context, {'action': 'delete'});
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(l10n.delete),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'action': 'update',
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text.trim(),
              'role': _selectedRole,
              'palletCapacity': _palletCapacityController.text.trim(),
              'truckWeight': _truckWeightController.text.trim(),
              'vehicleNumber': _vehicleNumberController.text.trim(),
            });
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
