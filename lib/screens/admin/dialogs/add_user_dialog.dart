import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/company_provision_service.dart';
import '../../../services/company_selection_service.dart';

/// Диалог добавления нового пользователя
class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key, this.initialRole = 'driver'});

  final String initialRole;

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyIdController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _palletCapacityController = TextEditingController();
  final _truckWeightController = TextEditingController();
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    final authService = context.read<AuthService>();
    final currentUser = authService.userModel;
    if (currentUser != null) {
      if (currentUser.isSuperAdmin) {
        final selected =
            context.read<CompanySelectionService>().selectedCompanyId;
        if (selected != null && selected.isNotEmpty) {
          _companyIdController.text = selected;
        }
      } else if (currentUser.companyId != null) {
        _companyIdController.text = currentUser.companyId ?? '';
      }
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
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return AlertDialog(
      title: Text(l10n.addNewUser),
      insetPadding: EdgeInsets.all(narrow ? 8 : 24),
      content: SizedBox(
        width: narrow ? MediaQuery.sizeOf(context).width * 0.85 : 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.required : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.required : null,
              ),
              if (isSuperAdmin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyIdController,
                  decoration: InputDecoration(
                    labelText: l10n.companyIdSlug,
                    hintText: l10n.companyIdSlugHint,
                    border: const OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    final id = (v ?? '').trim().toLowerCase();
                    if (id.isEmpty) return l10n.required;
                    if (!CompanyProvisionService.isValidCompanyId(id)) {
                      return l10n.invalidCompanyId;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.role,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'driver', child: Text(l10n.driver)),
                  DropdownMenuItem(
                      value: 'dispatcher', child: Text(l10n.dispatcher)),
                  DropdownMenuItem(
                      value: 'warehouse_keeper',
                      child: Text(l10n.roleWarehouseKeeper)),
                  DropdownMenuItem(
                      value: 'accountant', child: Text(l10n.roleAccountant)),
                  DropdownMenuItem(
                      value: 'admin', child: Text(l10n.systemManager)),
                  if (isSuperAdmin)
                    DropdownMenuItem(value: 'owner', child: Text(l10n.roleOwner)),
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
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final companyId = _companyIdController.text.trim().toLowerCase();
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'companyId': companyId,
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
