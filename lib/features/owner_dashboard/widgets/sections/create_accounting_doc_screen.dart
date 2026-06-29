import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/company_settings.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/invoice_service.dart';
import '../../models/accounting_doc.dart';
import '../../models/role_hierarchy.dart';
import '../../services/permissions_service.dart';
import 'accounting_helpers.dart';
import 'create_doc_form_dialog.dart';

/// Опция типа документа для боковой навигации.
class CreateDocTypeOption {
  final AccountingDocType type;
  final IconData icon;
  final String label;
  final String hint;
  final bool enabled;

  const CreateDocTypeOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.hint,
    this.enabled = true,
  });
}

List<CreateDocTypeOption> buildCreateDocTypeOptions(
  AppLocalizations l10n,
  PermissionsService permissions,
) {
  bool allowed(AccountingDocType t) =>
      permissions.canCreateAccountingDoc(_docTypeKey(t));

  return [
    CreateDocTypeOption(
      type: AccountingDocType.taxInvoice,
      icon: Icons.receipt_long_outlined,
      label: l10n.taxInvoice,
      hint: l10n.taxInvoice,
      enabled: allowed(AccountingDocType.taxInvoice),
    ),
    CreateDocTypeOption(
      type: AccountingDocType.receipt,
      icon: Icons.receipt_outlined,
      label: l10n.receipt,
      hint: l10n.receipt,
      enabled: allowed(AccountingDocType.receipt),
    ),
    CreateDocTypeOption(
      type: AccountingDocType.taxInvoiceReceipt,
      icon: Icons.description_outlined,
      label: l10n.taxInvoiceReceipt,
      hint: l10n.taxInvoiceReceipt,
      enabled: AppConfig.enableTaxInvoiceReceipt &&
          allowed(AccountingDocType.taxInvoiceReceipt),
    ),
    CreateDocTypeOption(
      type: AccountingDocType.deliveryNote,
      icon: Icons.local_shipping_outlined,
      label: l10n.settingsDeliveryNote,
      hint: l10n.settingsDeliveryNote,
      enabled: allowed(AccountingDocType.deliveryNote),
    ),
    CreateDocTypeOption(
      type: AccountingDocType.creditNote,
      icon: Icons.money_off_outlined,
      label: l10n.creditNote,
      hint: l10n.creditNote,
      enabled: allowed(AccountingDocType.creditNote),
    ),
  ].where((o) => allowed(o.type)).toList();
}

String _docTypeKey(AccountingDocType type) {
  switch (type) {
    case AccountingDocType.taxInvoice:
      return 'tax_invoice';
    case AccountingDocType.receipt:
      return 'receipt';
    case AccountingDocType.taxInvoiceReceipt:
      return 'tax_invoice_receipt';
    case AccountingDocType.creditNote:
      return 'credit_note';
    case AccountingDocType.deliveryNote:
      return 'delivery_note';
  }
}

/// Секция Owner Dashboard: выбор типа + форма (пункт меню «צור מסמך»).
class CreateAccountingDocSection extends StatefulWidget {
  final String companyId;
  final CompanySettings companySettings;

  const CreateAccountingDocSection({
    super.key,
    required this.companyId,
    required this.companySettings,
  });

  @override
  State<CreateAccountingDocSection> createState() =>
      _CreateAccountingDocSectionState();
}

class _CreateAccountingDocSectionState extends State<CreateAccountingDocSection> {
  late final InvoiceService _invoiceService;
  late AccountingDocType _selectedType;
  late List<CreateDocTypeOption> _options;
  late PermissionsService _permissions;
  int _formGeneration = 0;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService(companyId: widget.companyId);
    _initPermissions();
  }

  void _initPermissions() {
    final auth = context.read<AuthService>();
    _permissions = PermissionsService.forUser(
      actualRole: auth.userModel?.role,
      viewAsRole: auth.viewAsRole,
      userCompanyId: widget.companyId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initPermissions();
    final l10n = AppLocalizations.of(context)!;
    _options = buildCreateDocTypeOptions(l10n, _permissions);
    _selectedType = _options.isNotEmpty
        ? _options.first.type
        : AccountingDocType.taxInvoice;
  }

  void _onTypeSelected(AccountingDocType type) {
    if (type == _selectedType) return;
    setState(() => _selectedType = type);
  }

  void _onSaved() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.documentCreatedSuccess)),
    );
    setState(() => _formGeneration++);
  }

  @override
  Widget build(BuildContext context) {
    return CreateAccountingDocPanel(
      companyId: widget.companyId,
      invoiceService: _invoiceService,
      permissions: _permissions,
      accountingLockedUntil: widget.companySettings.accountingLockedUntil,
      selectedType: _selectedType,
      options: _options,
      formGeneration: _formGeneration,
      onTypeSelected: _onTypeSelected,
      onSaved: _onSaved,
    );
  }
}

/// Модальный экран — только для редактирования черновика из списка.
class CreateAccountingDocScreen extends StatelessWidget {
  final String companyId;
  final DateTime? accountingLockedUntil;
  final PermissionsService permissions;
  final AccountingDoc editDoc;

  const CreateAccountingDocScreen({
    super.key,
    required this.companyId,
    required this.permissions,
    required this.editDoc,
    this.accountingLockedUntil,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final typeLabel = docTypeLabel(context, editDoc.type);
    final invoiceService = InvoiceService(companyId: companyId);
    final options = buildCreateDocTypeOptions(l10n, permissions);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${l10n.edit} — $typeLabel'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: CreateAccountingDocPanel(
          companyId: companyId,
          invoiceService: invoiceService,
          permissions: permissions,
          accountingLockedUntil: accountingLockedUntil,
          selectedType: editDoc.type,
          options: options,
          editDoc: editDoc,
          isEdit: true,
          onClose: () => Navigator.of(context).pop(),
          onSaved: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }
}

/// Общая разметка: справа выбор типа, слева форма.
class CreateAccountingDocPanel extends StatelessWidget {
  final String companyId;
  final InvoiceService invoiceService;
  final PermissionsService permissions;
  final DateTime? accountingLockedUntil;
  final AccountingDocType selectedType;
  final List<CreateDocTypeOption> options;
  final ValueChanged<AccountingDocType> onTypeSelected;
  final AccountingDoc? editDoc;
  final bool isEdit;
  final int formGeneration;
  final VoidCallback? onClose;
  final VoidCallback? onSaved;

  const CreateAccountingDocPanel({
    super.key,
    required this.companyId,
    required this.invoiceService,
    required this.permissions,
    required this.selectedType,
    required this.options,
    this.accountingLockedUntil,
    this.editDoc,
    this.isEdit = false,
    this.formGeneration = 0,
    this.onTypeSelected = _noopType,
    this.onClose,
    this.onSaved,
  });

  static void _noopType(AccountingDocType _) {}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final typeLabel = docTypeLabel(context, selectedType);

    final body = narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEdit) _buildTypeChips(context),
              Expanded(child: _buildForm(context)),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 220, child: _buildTypeRail(context)),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _buildForm(context)),
            ],
          );

    if (isEdit) return body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.createDocument,
                        style: theme.textTheme.headlineSmall),
                    Text(
                      '${l10n.selectDocType}: $typeLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return CreateDocFormDialog(
      key: ValueKey(
          '${selectedType.name}-${editDoc?.id ?? 'new'}-$formGeneration'),
      embedded: true,
      docType: selectedType,
      companyId: companyId,
      invoiceService: invoiceService,
      accountingLockedUntil: accountingLockedUntil,
      canManageClients: permissions.canManageClients(),
      editDoc: editDoc,
      onClose: onClose,
      onSaved: onSaved,
    );
  }

  Widget _buildTypeRail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.selectDocType,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final o in options) _typeTile(context, o),
        ],
      ),
    );
  }

  Widget _buildTypeChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(o.label),
                selected: o.type == selectedType,
                onSelected: o.enabled && !isEdit
                    ? (_) => onTypeSelected(o.type)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _typeTile(BuildContext context, CreateDocTypeOption o) {
    final theme = Theme.of(context);
    final selected = o.type == selectedType;

    return ListTile(
      leading: Icon(
        o.icon,
        size: 22,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        o.label,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        o.hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      selected: selected,
      dense: true,
      enabled: o.enabled && !isEdit,
      onTap: o.enabled && !isEdit ? () => onTypeSelected(o.type) : null,
    );
  }
}
