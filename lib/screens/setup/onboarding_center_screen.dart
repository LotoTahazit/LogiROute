import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/owner_dashboard/models/role_hierarchy.dart';
import '../../l10n/app_localizations.dart';
import '../../models/company_onboarding_mode.dart';
import '../../models/company_settings.dart';
import '../../models/company_setup_wizard.dart';
import '../../models/launch_card_meta.dart';
import '../../models/launch_center_logic.dart';
import '../../models/onboarding_section.dart';
import '../../services/auth_service.dart';
import '../../services/company_context.dart';
import '../../services/company_setup_wizard_service.dart';
import '../../services/onboarding_step_signals.dart';
import '../../widgets/company_health_strip.dart';
import 'company_setup_wizard_screen.dart';

/// Launch Center — гибкий чеклист поверх [CompanySetupWizardService].
class OnboardingCenterScreen extends StatefulWidget {
  const OnboardingCenterScreen({
    super.key,
    this.companyId,
    this.companySettings,
    this.embedded = false,
  });

  final String? companyId;
  final CompanySettings? companySettings;
  final bool embedded;

  @override
  State<OnboardingCenterScreen> createState() => _OnboardingCenterScreenState();
}

class _OnboardingCenterScreenState extends State<OnboardingCenterScreen> {
  CompanySetupWizardService? _service;
  Map<SetupWizardStepId, bool>? _stepSignals;
  Map<OnboardingSectionId, bool>? _cardSignals;
  bool _syncing = false;
  int _healthRefreshToken = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyId = widget.companyId ??
        CompanyContext.of(context).effectiveCompanyId ??
        '';
    if (companyId.isNotEmpty && _service?.companyId != companyId) {
      _service = CompanySetupWizardService(companyId: companyId);
      _refreshSignals(sync: true);
    }
  }

  String get _userRole {
    final auth = context.read<AuthService>();
    return effectiveAppRole(
      actualRole: auth.userModel?.role ?? '',
      viewAsRole: auth.viewAsRole,
    ).value;
  }

  bool get _canAssign => LaunchCenterLogic.canAssignCards(_userRole);

  Future<void> _refreshSignals({bool sync = false}) async {
    final service = _service;
    if (service == null || !mounted) return;
    setState(() => _syncing = true);
    try {
      if (sync) {
        await service.syncFromSignals(companySettings: widget.companySettings);
      }
      final signals = OnboardingStepSignals(
        companyId: service.companyId,
        companySettings: widget.companySettings,
      );
      final stepSignals = await signals.checkAll();
      final cardSignals = await signals.checkCardSignals();
      if (mounted) {
        setState(() {
          _stepSignals = stepSignals;
          _cardSignals = cardSignals;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
          _healthRefreshToken++;
        });
      }
    }
  }

  Future<void> _openCard(
    OnboardingSectionId card,
    CompanySetupWizardState state,
  ) async {
    final service = _service;
    if (service == null || _syncing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _syncing = true);
    try {
      final step = card.wizardSteps.isNotEmpty ? card.wizardSteps.first : null;
      if (step != null) await service.startStep(step);
      if (!mounted) return;
      await openLaunchCardScreen(
        context,
        companyId: service.companyId,
        card: card,
      );
      if (card == OnboardingSectionId.goLive && mounted) {
        await service.completeStep(SetupWizardStepId.ready);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      await _refreshSignals(sync: true);
    }
  }

  Future<void> _skipCard(OnboardingSectionId card) async {
    final service = _service;
    if (service == null || card.isRequired) return;
    for (final step in card.wizardSteps) {
      if (!step.canSkip) continue;
      await service.skipStep(step);
    }
    await _refreshSignals(sync: true);
  }

  Future<void> _showAssignDialog(
    OnboardingSectionId card,
    LaunchCardMeta meta,
  ) async {
    final service = _service;
    if (service == null || !_canAssign) return;
    final l10n = AppLocalizations.of(context)!;
    var role = meta.assignedRole;
    final notesCtrl = TextEditingController(text: meta.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.launchCenterAssignCard),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: role,
                decoration: InputDecoration(labelText: l10n.launchCenterAssignee),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.launchCenterUnassigned)),
                  ...OnboardingSectionId.assignableRoles.map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(_roleLabel(l10n, r)),
                    ),
                  ),
                ],
                onChanged: (v) => role = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(labelText: l10n.launchCenterNotes),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final notes = notesCtrl.text.trim();
    notesCtrl.dispose();
    if (saved != true || !mounted) return;
    await service.assignCard(
      card,
      assignedRole: role,
      notes: notes.isEmpty ? null : notes,
    );
    if (mounted) setState(() {});
  }

  String _cardTitle(AppLocalizations l10n, OnboardingSectionId id) {
    switch (id) {
      case OnboardingSectionId.companyDetails:
        return l10n.launchCenterCardCompanyDetails;
      case OnboardingSectionId.firstOwnerAdmin:
        return l10n.launchCenterCardFirstOwnerAdmin;
      case OnboardingSectionId.clients:
        return l10n.launchCenterCardClients;
      case OnboardingSectionId.products:
        return l10n.launchCenterCardProducts;
      case OnboardingSectionId.drivers:
        return l10n.launchCenterCardDrivers;
      case OnboardingSectionId.warehouse:
        return l10n.launchCenterCardWarehouse;
      case OnboardingSectionId.accounting:
        return l10n.launchCenterCardAccounting;
      case OnboardingSectionId.gps:
        return l10n.launchCenterCardGps;
      case OnboardingSectionId.firstRoute:
        return l10n.launchCenterCardFirstRoute;
      case OnboardingSectionId.testDelivery:
        return l10n.launchCenterCardTestDelivery;
      case OnboardingSectionId.goLive:
        return l10n.launchCenterCardGoLive;
    }
  }

  String _cardHint(AppLocalizations l10n, OnboardingSectionId id) {
    switch (id) {
      case OnboardingSectionId.companyDetails:
        return l10n.launchCenterHintCompanyDetails;
      case OnboardingSectionId.firstOwnerAdmin:
        return l10n.launchCenterHintFirstOwnerAdmin;
      case OnboardingSectionId.clients:
        return l10n.launchCenterHintClients;
      case OnboardingSectionId.products:
        return l10n.launchCenterHintProducts;
      case OnboardingSectionId.drivers:
        return l10n.launchCenterHintDrivers;
      case OnboardingSectionId.warehouse:
        return l10n.launchCenterHintWarehouse;
      case OnboardingSectionId.accounting:
        return l10n.launchCenterHintAccounting;
      case OnboardingSectionId.gps:
        return l10n.launchCenterHintGps;
      case OnboardingSectionId.firstRoute:
        return l10n.launchCenterHintFirstRoute;
      case OnboardingSectionId.testDelivery:
        return l10n.launchCenterHintTestDelivery;
      case OnboardingSectionId.goLive:
        return l10n.launchCenterHintGoLive;
    }
  }

  String _statusLabel(AppLocalizations l10n, OnboardingSectionStatus s) {
    switch (s) {
      case OnboardingSectionStatus.notStarted:
        return l10n.setupWizardStatusNotStarted;
      case OnboardingSectionStatus.inProgress:
        return l10n.setupWizardStatusInProgress;
      case OnboardingSectionStatus.completed:
        return l10n.setupWizardStatusCompleted;
      case OnboardingSectionStatus.skipped:
        return l10n.setupWizardStatusSkipped;
    }
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'owner':
        return l10n.roleOwner;
      case 'dispatcher':
        return l10n.roleDispatcher;
      case 'warehouse_keeper':
        return l10n.roleWarehouseKeeper;
      case 'accountant':
        return l10n.roleAccountant;
      default:
        return role;
    }
  }

  bool _cardAutoDetected(
    OnboardingSectionId card,
    CompanySetupWizardState state,
  ) {
    if (card.isSignalOnly) {
      return _cardSignals?[card] == true;
    }
    for (final id in card.wizardSteps) {
      final stored = state.statusOf(id);
      final effective = LaunchCenterLogic.effectiveStepStatus(
        card: card,
        state: state,
        stepSignals: _stepSignals ?? {},
        cardSignals: _cardSignals ?? {},
      );
      if (effective == SetupWizardStepStatus.completed &&
          stored != SetupWizardStepStatus.completed &&
          stored != SetupWizardStepStatus.skipped) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = _service;
    if (service == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stepSignals = _stepSignals ?? {};
    final cardSignals = _cardSignals ?? {};

    final body = StreamBuilder<CompanySetupWizardState>(
      stream: service.watchState(),
      builder: (context, snap) {
        final state = snap.data ?? CompanySetupWizardState.initial();
        final total = OnboardingSectionId.ordered.length;
        final done = LaunchCenterLogic.completedCardCount(
          state,
          stepSignals: stepSignals,
          cardSignals: cardSignals,
        );
        final percent = LaunchCenterLogic.progressPercent(
          state,
          stepSignals: stepSignals,
          cardSignals: cardSignals,
        );
        final nextCard = LaunchCenterLogic.nextRecommendedCard(
          state,
          stepSignals: stepSignals,
          cardSignals: cardSignals,
        );
        final minutesLeft = OnboardingSectionId.ordered
            .where((c) =>
                LaunchCenterLogic.cardStatus(
                  c,
                  state,
                  stepSignals: stepSignals,
                  cardSignals: cardSignals,
                ) !=
                OnboardingSectionStatus.completed)
            .fold(0, (sum, c) => sum + c.estimatedMinutes);
        final companyReady = LaunchCenterLogic.isCompanyReady(
          state,
          stepSignals: stepSignals,
          cardSignals: cardSignals,
        );
        final mode = CompanyOnboardingMode.fromValue(state.onboardingMode);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CompanyHealthStrip(
              companyId: service.companyId,
              companySettings: widget.companySettings,
              refreshToken: _healthRefreshToken,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.onboardingCenterSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_userRole == 'super_admin')
                  Chip(
                    label: Text(
                      mode == CompanyOnboardingMode.doneForYou
                          ? l10n.launchCenterModeDoneForYou
                          : l10n.launchCenterModeSelfSetup,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              percent: percent,
              done: done,
              total: total,
              nextLabel: nextCard == null
                  ? l10n.launchCenterCompanyReady
                  : _cardTitle(l10n, nextCard),
              minutesLeft: minutesLeft,
              l10n: l10n,
              onNextTap: nextCard == null
                  ? null
                  : () => _openCard(nextCard, state),
            ),
            if (companyReady && !state.wizardCompleted) ...[
              const SizedBox(height: 12),
              _ReadinessCard(
                title: l10n.onboardingCenterAlmostReadyTitle,
                body: l10n.onboardingCenterAlmostReadyBody,
                color: Colors.orange.shade50,
                icon: Icons.hourglass_top,
                iconColor: Colors.orange.shade800,
              ),
            ],
            if (companyReady) ...[
              const SizedBox(height: 12),
              _ReadinessCard(
                title: l10n.launchCenterCompanyReadyTitle,
                body: state.wizardCompleted
                    ? l10n.onboardingCenterCanStartBody
                    : l10n.launchCenterCompanyReadyBody,
                color: Colors.green.shade50,
                icon: Icons.celebration,
                iconColor: Colors.green.shade800,
              ),
            ],
            const SizedBox(height: 16),
            ...OnboardingSectionId.ordered.map((card) {
              final status = LaunchCenterLogic.cardStatus(
                card,
                state,
                stepSignals: stepSignals,
                cardSignals: cardSignals,
              );
              final auto = _cardAutoDetected(card, state);
              final meta = state.metaOf(card);
              final canOpen = status != OnboardingSectionStatus.completed &&
                  status != OnboardingSectionStatus.skipped;
              return _LaunchCardTile(
                title: _cardTitle(l10n, card),
                hint: _cardHint(l10n, card),
                statusLabel: _statusLabel(l10n, status),
                status: status,
                required: card.isRequired,
                estimatedMinutes: card.estimatedMinutes,
                assigneeLabel: meta.assignedRole != null
                    ? _roleLabel(l10n, meta.assignedRole!)
                    : (meta.assignedUserId != null
                        ? meta.assignedUserId!
                        : null),
                autoDetected: auto,
                canOpen: canOpen,
                canAssign: _canAssign,
                canSkip: !card.isRequired &&
                    card.wizardSteps.any((s) => s.canSkip) &&
                    canOpen,
                l10n: l10n,
                onOpen: () => _openCard(card, state),
                onAssign: () => _showAssignDialog(card, meta),
                onSkip: () => _skipCard(card),
              );
            }),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _syncing ? null : () => _refreshSignals(sync: true),
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(l10n.onboardingCenterRefresh),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanySetupWizardScreen(
                        companyId: widget.companyId ??
                            CompanyContext.of(context).effectiveCompanyId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.rocket_launch),
                  label: Text(l10n.onboardingCenterOpenWizard),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingCenterTitle)),
      body: body,
    );
  }
}

class _LaunchCardTile extends StatelessWidget {
  const _LaunchCardTile({
    required this.title,
    required this.hint,
    required this.statusLabel,
    required this.status,
    required this.required,
    required this.estimatedMinutes,
    required this.l10n,
    required this.canOpen,
    required this.canAssign,
    required this.canSkip,
    required this.onOpen,
    required this.onAssign,
    required this.onSkip,
    this.assigneeLabel,
    this.autoDetected = false,
  });

  final String title;
  final String hint;
  final String statusLabel;
  final OnboardingSectionStatus status;
  final bool required;
  final int estimatedMinutes;
  final String? assigneeLabel;
  final bool autoDetected;
  final bool canOpen;
  final bool canAssign;
  final bool canSkip;
  final AppLocalizations l10n;
  final VoidCallback onOpen;
  final VoidCallback onAssign;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(status), color: _colorFor(status, context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          _Badge(
                            label: required
                                ? l10n.launchCenterRequired
                                : l10n.launchCenterOptional,
                            emphasized: required,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(hint,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusChip(label: statusLabel),
                          _Badge(
                            label: l10n.launchCenterEstimatedMin(estimatedMinutes),
                          ),
                          if (assigneeLabel != null)
                            _Badge(
                              label:
                                  '${l10n.launchCenterAssignee}: $assigneeLabel',
                            ),
                        ],
                      ),
                      if (autoDetected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.onboardingCenterAutoDetected,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canAssign)
                  TextButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: Text(l10n.launchCenterAssign),
                  ),
                if (canSkip)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(l10n.setupWizardSkip),
                  ),
                if (canOpen)
                  FilledButton.tonal(
                    onPressed: onOpen,
                    child: Text(l10n.setupWizardOpenStep),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(OnboardingSectionStatus s) {
    switch (s) {
      case OnboardingSectionStatus.completed:
        return Icons.check_circle;
      case OnboardingSectionStatus.skipped:
        return Icons.skip_next;
      case OnboardingSectionStatus.inProgress:
        return Icons.play_circle_outline;
      case OnboardingSectionStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  Color? _colorFor(OnboardingSectionStatus s, BuildContext context) {
    switch (s) {
      case OnboardingSectionStatus.completed:
        return Colors.green;
      case OnboardingSectionStatus.skipped:
        return Colors.grey;
      case OnboardingSectionStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case OnboardingSectionStatus.notStarted:
        return null;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.percent,
    required this.done,
    required this.total,
    required this.nextLabel,
    required this.minutesLeft,
    required this.l10n,
    this.onNextTap,
  });

  final int percent;
  final int done;
  final int total;
  final String nextLabel;
  final int minutesLeft;
  final AppLocalizations l10n;
  final VoidCallback? onNextTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percent / 100,
                        strokeWidth: 5,
                      ),
                      Center(
                        child: Text(
                          '$percent%',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.onboardingCenterCompletedSteps(done, total),
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        l10n.onboardingCenterEstimatedTime(minutesLeft),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: done / total),
            const SizedBox(height: 12),
            InkWell(
              onTap: onNextTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.onboardingCenterNextStep}: $nextLabel',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (onNextTap != null)
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: emphasized
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
