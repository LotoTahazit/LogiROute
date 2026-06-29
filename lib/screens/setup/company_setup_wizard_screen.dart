import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/company_setup_wizard.dart';
import '../../models/onboarding_section.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/company_setup_wizard_service.dart';
import '../../utils/snackbar_helper.dart';
import '../admin/company_settings_screen.dart';
import '../admin/dialogs/add_user_dialog.dart';
import '../admin/product_management_screen.dart';
import '../dispatcher/dispatcher_dashboard.dart';
import '../shared/client_management_screen.dart';
import '../warehouse/warehouse_dashboard.dart';
import 'warehouse_setup_questionnaire_screen.dart';

Future<bool> submitAddUserDialogResult(
  BuildContext context,
  Map<String, dynamic> result, {
  required String fallbackCompanyId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = (result['name'] as String?)?.trim() ?? '';
  final email = (result['email'] as String?)?.trim() ?? '';
  final password = result['password'] as String? ?? '';
  final role = (result['role'] as String?) ?? 'driver';
  var companyId =
      (result['companyId'] as String?)?.trim().toLowerCase() ?? '';
  if (companyId.isEmpty) companyId = fallbackCompanyId;

  if (name.isEmpty || email.isEmpty || password.isEmpty || companyId.isEmpty) {
    SnackbarHelper.showWarning(context, l10n.fillAllFields);
    return false;
  }

  int? palletCapacity;
  double? truckWeight;
  String? vehicleNumber;
  if (role == 'driver') {
    final pc = (result['palletCapacity'] as String?)?.trim() ?? '';
    if (pc.isNotEmpty) palletCapacity = int.tryParse(pc) ?? 0;
    final tw = (result['truckWeight'] as String?)?.trim() ?? '';
    if (tw.isNotEmpty) truckWeight = double.tryParse(tw) ?? 4.0;
    final vn = (result['vehicleNumber'] as String?)?.trim() ?? '';
    if (vn.isNotEmpty) vehicleNumber = vn;
  }

  final errorCode = await context.read<AuthService>().createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        companyId: companyId,
        palletCapacity: palletCapacity,
        truckWeight: truckWeight,
        vehicleNumber: vehicleNumber,
      );

  if (!context.mounted) return false;
  if (errorCode == null) {
    SnackbarHelper.showSuccess(context, l10n.userAddedSuccessfully);
    return true;
  }

  var errorMessage = l10n.errorCreatingUser;
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
  }
  SnackbarHelper.showError(context, errorMessage);
  return false;
}

/// Открывает экран действия для шага мастера (wizard + onboarding center).
Future<void> openSetupWizardStepScreen(
  BuildContext context, {
  required String companyId,
  required SetupWizardStepId step,
}) async {
  switch (step) {
    case SetupWizardStepId.companyInfo:
    case SetupWizardStepId.accountingSetup:
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const CompanySettingsScreen()),
      );
      break;
    case SetupWizardStepId.importClients:
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ClientManagementScreen(
            companyId: companyId,
            openImportOnReady: true,
          ),
        ),
      );
      break;
    case SetupWizardStepId.importProducts:
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
      );
      break;
    case SetupWizardStepId.addDrivers:
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const AddUserDialog(initialRole: 'driver'),
      );
      if (result != null && context.mounted) {
        await submitAddUserDialogResult(
          context,
          result,
          fallbackCompanyId: companyId,
        );
      }
      break;
    case SetupWizardStepId.warehouseSetup:
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => WarehouseSetupQuestionnaireScreen(companyId: companyId),
        ),
      );
      break;
    case SetupWizardStepId.firstRoute:
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const DispatcherDashboard()),
      );
      break;
    case SetupWizardStepId.gpsCheck:
    case SetupWizardStepId.testDelivery:
    case SetupWizardStepId.ready:
      break;
  }
}

/// Открывает экран действия для карточки Launch Center.
Future<void> openLaunchCardScreen(
  BuildContext context, {
  required String companyId,
  required OnboardingSectionId card,
}) async {
  switch (card) {
    case OnboardingSectionId.companyDetails:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.companyInfo,
      );
      break;
    case OnboardingSectionId.firstOwnerAdmin:
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const AddUserDialog(initialRole: 'owner'),
      );
      if (result != null && context.mounted) {
        await submitAddUserDialogResult(
          context,
          result,
          fallbackCompanyId: companyId,
        );
      }
      break;
    case OnboardingSectionId.clients:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.importClients,
      );
      break;
    case OnboardingSectionId.products:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.importProducts,
      );
      break;
    case OnboardingSectionId.drivers:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.addDrivers,
      );
      break;
    case OnboardingSectionId.warehouse:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.warehouseSetup,
      );
      break;
    case OnboardingSectionId.accounting:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.accountingSetup,
      );
      break;
    case OnboardingSectionId.gps:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.gpsCheck,
      );
      break;
    case OnboardingSectionId.firstRoute:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.firstRoute,
      );
      break;
    case OnboardingSectionId.testDelivery:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.testDelivery,
      );
      break;
    case OnboardingSectionId.goLive:
      await openSetupWizardStepScreen(
        context,
        companyId: companyId,
        step: SetupWizardStepId.ready,
      );
      break;
  }
}

/// Мастер первого запуска компании — оболочка над существующими экранами.
class CompanySetupWizardScreen extends StatefulWidget {
  const CompanySetupWizardScreen({super.key, this.companyId});

  final String? companyId;

  @override
  State<CompanySetupWizardScreen> createState() =>
      _CompanySetupWizardScreenState();
}

class _CompanySetupWizardScreenState extends State<CompanySetupWizardScreen> {
  CompanySetupWizardService? _service;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyId = widget.companyId ??
        CompanyContext.of(context).effectiveCompanyId ??
        '';
    if (companyId.isNotEmpty && _service?.companyId != companyId) {
      _service = CompanySetupWizardService(companyId: companyId);
    }
  }

  String _stepTitle(AppLocalizations l10n, SetupWizardStepId id) {
    switch (id) {
      case SetupWizardStepId.companyInfo:
        return l10n.setupWizardStepCompanyInfo;
      case SetupWizardStepId.importClients:
        return l10n.setupWizardStepImportClients;
      case SetupWizardStepId.importProducts:
        return l10n.setupWizardStepImportProducts;
      case SetupWizardStepId.addDrivers:
        return l10n.setupWizardStepAddDrivers;
      case SetupWizardStepId.warehouseSetup:
        return l10n.setupWizardStepWarehouse;
      case SetupWizardStepId.accountingSetup:
        return l10n.setupWizardStepAccounting;
      case SetupWizardStepId.gpsCheck:
        return l10n.setupWizardStepGps;
      case SetupWizardStepId.firstRoute:
        return l10n.setupWizardStepFirstRoute;
      case SetupWizardStepId.testDelivery:
        return l10n.setupWizardStepTestDelivery;
      case SetupWizardStepId.ready:
        return l10n.setupWizardStepReady;
    }
  }

  String _stepHint(AppLocalizations l10n, SetupWizardStepId id) {
    switch (id) {
      case SetupWizardStepId.companyInfo:
        return l10n.setupWizardHintCompanyInfo;
      case SetupWizardStepId.importClients:
        return l10n.setupWizardHintImportClients;
      case SetupWizardStepId.importProducts:
        return l10n.setupWizardHintImportProducts;
      case SetupWizardStepId.addDrivers:
        return l10n.setupWizardHintAddDrivers;
      case SetupWizardStepId.warehouseSetup:
        return l10n.setupWizardHintWarehouse;
      case SetupWizardStepId.accountingSetup:
        return l10n.setupWizardHintAccounting;
      case SetupWizardStepId.gpsCheck:
        return l10n.setupWizardHintGps;
      case SetupWizardStepId.firstRoute:
        return l10n.setupWizardHintFirstRoute;
      case SetupWizardStepId.testDelivery:
        return l10n.setupWizardHintTestDelivery;
      case SetupWizardStepId.ready:
        return l10n.setupWizardHintReady;
    }
  }

  String _statusLabel(AppLocalizations l10n, SetupWizardStepStatus s) {
    switch (s) {
      case SetupWizardStepStatus.notStarted:
        return l10n.setupWizardStatusNotStarted;
      case SetupWizardStepStatus.inProgress:
        return l10n.setupWizardStatusInProgress;
      case SetupWizardStepStatus.completed:
        return l10n.setupWizardStatusCompleted;
      case SetupWizardStepStatus.skipped:
        return l10n.setupWizardStatusSkipped;
    }
  }

  IconData _statusIcon(SetupWizardStepStatus s) {
    switch (s) {
      case SetupWizardStepStatus.completed:
        return Icons.check_circle;
      case SetupWizardStepStatus.inProgress:
        return Icons.play_circle_outline;
      case SetupWizardStepStatus.skipped:
        return Icons.skip_next;
      case SetupWizardStepStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  Color _statusColor(SetupWizardStepStatus s, ThemeData theme) {
    switch (s) {
      case SetupWizardStepStatus.completed:
        return Colors.green;
      case SetupWizardStepStatus.inProgress:
        return theme.colorScheme.primary;
      case SetupWizardStepStatus.skipped:
        return Colors.orange;
      case SetupWizardStepStatus.notStarted:
        return Colors.grey;
    }
  }

  Future<void> _openStep(SetupWizardStepId step) async {
    if (_service == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _service!.startStep(step);
      if (!mounted) return;
      await openSetupWizardStepScreen(
        context,
        companyId: _service!.companyId,
        step: step,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeStep(SetupWizardStepId step) async {
    if (_service == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _service!.completeStep(step);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skipStep(SetupWizardStepId step) async {
    if (_service == null || _busy || !step.canSkip) return;
    setState(() => _busy = true);
    try {
      await _service!.skipStep(step);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildReadyCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.celebration, size: 56, color: Colors.green.shade700),
            const SizedBox(height: 16),
            Text(
              l10n.setupWizardReadyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.setupWizardReadyBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepActions(
    AppLocalizations l10n,
    SetupWizardStepId step,
    SetupWizardStepStatus status,
  ) {
    if (step == SetupWizardStepId.ready) return const SizedBox.shrink();

    final hasOpen = step != SetupWizardStepId.gpsCheck &&
        step != SetupWizardStepId.testDelivery;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasOpen)
          FilledButton.icon(
            onPressed: _busy ? null : () => _openStep(step),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.setupWizardOpenStep),
          ),
        OutlinedButton(
          onPressed: _busy ? null : () => _completeStep(step),
          child: Text(l10n.setupWizardMarkComplete),
        ),
        if (step.canSkip)
          TextButton(
            onPressed: _busy ? null : () => _skipStep(step),
            child: Text(l10n.setupWizardSkip),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final service = _service;

    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.setupWizardTitle)),
        body: Center(child: Text(l10n.noCompanySelected)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setupWizardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.setupWizardContinueLater),
          ),
        ],
      ),
      body: StreamBuilder<CompanySetupWizardState>(
        stream: service.watchState(),
        builder: (context, snap) {
          final state = snap.data ?? CompanySetupWizardState.initial();
          final current = state.currentStep;
          final completedCount = SetupWizardStepId.ordered
              .where((s) =>
                  state.statusOf(s) == SetupWizardStepStatus.completed ||
                  state.statusOf(s) == SetupWizardStepStatus.skipped)
              .length;

          if (state.wizardCompleted || state.statusOf(SetupWizardStepId.ready) ==
              SetupWizardStepStatus.completed) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildReadyCard(l10n, theme),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.setupWizardProgress(completedCount, 10),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: completedCount / 10),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _stepTitle(l10n, current),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_stepHint(l10n, current)),
                      const SizedBox(height: 16),
                      _buildStepActions(
                        l10n,
                        current,
                        state.statusOf(current),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...SetupWizardStepId.ordered.map((step) {
                final st = state.statusOf(step);
                final isCurrent = step == current;
                return ListTile(
                  selected: isCurrent,
                  leading: Icon(
                    _statusIcon(st),
                    color: _statusColor(st, theme),
                  ),
                  title: Text(_stepTitle(l10n, step)),
                  subtitle: Text(_statusLabel(l10n, st)),
                  trailing: step.isRequired
                      ? null
                      : Icon(Icons.flag_outlined,
                          size: 16, color: Colors.grey.shade500),
                  onTap: _busy
                      ? null
                      : () => service.goToStep(step),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Баннер «завершите настройку» для Owner / Admin dashboard.
class SetupWizardBanner extends StatelessWidget {
  const SetupWizardBanner({super.key, required this.companyId});

  final String companyId;

  void _openWizard(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanySetupWizardScreen(companyId: companyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = CompanySetupWizardService(companyId: companyId);

    return StreamBuilder<CompanySetupWizardState>(
      stream: service.watchState(),
      builder: (context, snap) {
        final state = snap.data ?? CompanySetupWizardState.initial();
        if (state.wizardCompleted) return const SizedBox.shrink();

        return MaterialBanner(
          backgroundColor: Colors.blue.shade50,
          leading: Icon(Icons.rocket_launch, color: Colors.blue.shade800),
          content: Text(l10n.setupWizardBannerTitle),
          actions: [
            TextButton(
              onPressed: () => _openWizard(context),
              child: Text(l10n.setupWizardBannerAction),
            ),
          ],
        );
      },
    );
  }
}
