import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/billing_state.dart';
import '../services/checkout_service.dart';
import 'checkout_ui_helper.dart';
import 'billing_support_actions.dart';
import '../screens/admin/subscription_screen.dart';
import 'stream_loading_gate.dart';

/// Обёртка для проверки billing status компании (C3 — единая state machine).
class BillingGuard extends StatefulWidget {
  final String companyId;
  final bool isSuperAdmin;
  final Widget child;

  const BillingGuard({
    super.key,
    required this.companyId,
    required this.isSuperAdmin,
    required this.child,
  });

  @override
  State<BillingGuard> createState() => _BillingGuardState();
}

class _BillingGuardState extends State<BillingGuard> {
  int _attempt = 0;

  void _retry() => setState(() => _attempt++);

  @override
  Widget build(BuildContext context) {
    if (widget.isSuperAdmin) return widget.child;

    if (widget.companyId.isEmpty) {
      return _BlockedScreen(status: 'no_company', companyId: '');
    }

    return StreamLoadingGate<DocumentSnapshot>(
      key: ValueKey(_attempt),
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .snapshots(),
      onTimeout: (_) => _VerificationFailedScreen(onRetry: _retry),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _VerificationFailedScreen(onRetry: _retry);
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return _VerificationFailedScreen(onRetry: _retry);
        }

        final rawData = doc.data();
        if (rawData == null) {
          return _VerificationFailedScreen(onRetry: _retry);
        }

        final data = Map<String, dynamic>.from(rawData as Map);
        final eval = BillingState.evaluateFromMap(data);

        if (!eval.allowsAccess) {
          return _BlockedScreen(
            status: eval.blockUiKey,
            companyId: widget.companyId,
          );
        }

        switch (eval.displayPhase) {
          case BillingDisplayPhase.trial:
            return _TrialBanner(
              trialUntil: eval.trialUntil!,
              companyId: widget.companyId,
              child: widget.child,
            );
          case BillingDisplayPhase.grace:
            return _GraceBanner(
              daysLeft: eval.graceDaysRemaining(DateTime.now()),
              companyId: widget.companyId,
              child: widget.child,
            );
          case BillingDisplayPhase.active:
            return widget.child;
          case BillingDisplayPhase.blocked:
            return _VerificationFailedScreen(onRetry: _retry);
        }
      },
    );
  }
}

class _VerificationFailedScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const _VerificationFailedScreen({required this.onRetry});

  @override
  State<_VerificationFailedScreen> createState() =>
      _VerificationFailedScreenState();
}

class _VerificationFailedScreenState extends State<_VerificationFailedScreen> {
  Timer? _autoRetry;

  @override
  void initState() {
    super.initState();
    _autoRetry = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) widget.onRetry();
    });
  }

  @override
  void dispose() {
    _autoRetry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 72, color: Colors.orange[300]),
              const SizedBox(height: 24),
              Text(
                l10n.billingGuardVerifyFailedTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.billingGuardVerifyFailedBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.billingGuardRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  final String status;
  final String companyId;
  const _BlockedScreen({required this.status, this.companyId = ''});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, title, subtitle) = switch (status) {
      'suspended' || 'blocked' => (
          Icons.block,
          l10n.billingGuardAccessSuspendedTitle,
          l10n.billingGuardAccessSuspendedBody,
        ),
      'cancelled' => (
          Icons.cancel,
          l10n.billingGuardAccountCancelledTitle,
          l10n.billingGuardAccountCancelledBody,
        ),
      'trial_expired' || 'payment_required' => (
          Icons.timer_off,
          l10n.billingGuardTrialEndedTitle,
          l10n.billingGuardTrialEndedBody,
        ),
      'no_company' => (
          Icons.business_outlined,
          l10n.billingGuardNoAccessTitle,
          l10n.billingGuardNoAccessBody,
        ),
      _ => (
          Icons.error,
          l10n.billingGuardNoAccessTitle,
          l10n.billingGuardNoAccessBody,
        ),
    };

    final showPayButton = (status == 'suspended' ||
            status == 'trial_expired' ||
            status == 'payment_required') &&
        companyId.isNotEmpty;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (showPayButton) _PayNowButton(companyId: companyId),
              if (showPayButton) const SizedBox(height: 12),
              if (companyId.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          SubscriptionScreen(companyId: companyId),
                    ),
                  ),
                  icon: const Icon(Icons.subscriptions),
                  label: Text(l10n.subscription),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () => BillingSupportActions.showSupportDialog(context),
                icon: const Icon(Icons.support_agent),
                label: Text(l10n.billingGuardContactSupport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  final DateTime trialUntil;
  final String companyId;
  final Widget child;
  const _TrialBanner({
    required this.trialUntil,
    required this.companyId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysLeft = trialUntil.difference(DateTime.now()).inDays;
    final color = daysLeft <= 3 ? Colors.orange : Colors.blue;
    final dateStr =
        '${trialUntil.day}.${trialUntil.month}.${trialUntil.year}';

    return Column(
      children: [
        MaterialBanner(
          backgroundColor: color.shade50,
          content: Text(
            l10n.billingGuardTrialBanner(daysLeft, dateStr),
            style: TextStyle(color: color.shade900),
          ),
          actions: [
            TextButton(
              onPressed: () => BillingSupportActions.startUpgradeCheckout(
                context,
                companyId: companyId,
              ),
              child: Text(
                l10n.billingGuardUpgrade,
                style: TextStyle(color: color.shade700),
              ),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _GraceBanner extends StatelessWidget {
  final int daysLeft;
  final String companyId;
  final Widget child;
  const _GraceBanner(
      {required this.daysLeft, required this.companyId, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        MaterialBanner(
          backgroundColor: Colors.red.shade50,
          leading: const Icon(Icons.warning_amber, color: Colors.red),
          content: Text(
            l10n.billingGuardGraceBanner(daysLeft),
            style: TextStyle(color: Colors.red.shade900),
          ),
          actions: [
            _PayNowButton(companyId: companyId, compact: true),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Reusable "Pay Now" button that triggers hosted checkout.
class _PayNowButton extends StatefulWidget {
  final String companyId;
  final bool compact;
  const _PayNowButton({required this.companyId, this.compact = false});

  @override
  State<_PayNowButton> createState() => _PayNowButtonState();
}

class _PayNowButtonState extends State<_PayNowButton> {
  bool _isLoading = false;

  Future<void> _pay() async {
    if (_isLoading) return;
    if (widget.companyId.isEmpty) {
      BillingSupportActions.startUpgradeCheckout(context, companyId: '');
      return;
    }
    setState(() => _isLoading = true);

    try {
      await CheckoutUiHelper.run(
        context: context,
        checkout: () => CheckoutService().createAndOpen(
          companyId: widget.companyId,
          userId: FirebaseAuth.instance.currentUser?.uid,
        ),
        onOpened: () {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.billingGuardCheckoutOpened),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.compact) {
      return TextButton(
        onPressed: _isLoading ? null : _pay,
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(
                l10n.billingGuardPayNow,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

    return FilledButton.icon(
      onPressed: _isLoading ? null : _pay,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.payment),
      label: Text(l10n.billingGuardPayNow),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
}
