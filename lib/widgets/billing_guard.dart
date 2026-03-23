import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../services/checkout_service.dart';

/// Обёртка для проверки billing status компании.
/// Если suspended/cancelled или trial истёк — показывает экран блокировки.
/// Если trial активен — показывает баннер "Trial до ...".
/// Если grace — показывает баннер с предупреждением об оплате.
class BillingGuard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // super_admin обходит все проверки
    if (isSuperAdmin || companyId.isEmpty) return child;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final rawData = snapshot.data?.data();
        final data = rawData != null
            ? Map<String, dynamic>.from(rawData as Map)
            : <String, dynamic>{};
        final status = data['billingStatus'] as String? ?? 'active';
        final trialUntil = data['trialUntil'] as Timestamp?;

        // suspended / cancelled → полная блокировка
        if (status == 'suspended' || status == 'cancelled') {
          return _BlockedScreen(status: status, companyId: companyId);
        }

        // trial с истёкшим сроком → блокировка
        if (status == 'trial') {
          if (trialUntil == null ||
              trialUntil.toDate().isBefore(DateTime.now())) {
            return const _BlockedScreen(status: 'trial_expired', companyId: '');
          }
          // trial активен — показываем баннер
          return _TrialBanner(
            trialUntil: trialUntil.toDate(),
            child: child,
          );
        }

        // grace — показываем предупреждение об оплате
        if (status == 'grace') {
          final paidUntil = data['paidUntil'] as Timestamp?;
          final graceDays = (data['gracePeriodDays'] as num?)?.toInt() ?? 7;
          DateTime graceEnd;
          if (paidUntil != null) {
            graceEnd = paidUntil.toDate().add(Duration(days: graceDays));
          } else {
            graceEnd = DateTime.now().add(const Duration(days: 3));
          }
          final daysLeft = graceEnd.difference(DateTime.now()).inDays;
          return _GraceBanner(
            daysLeft: daysLeft,
            companyId: companyId,
            child: child,
          );
        }

        // active — всё ок
        return child;
      },
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
      'suspended' => (
          Icons.block,
          l10n.billingGuardAccessSuspendedTitle,
          l10n.billingGuardAccessSuspendedBody,
        ),
      'cancelled' => (
          Icons.cancel,
          l10n.billingGuardAccountCancelledTitle,
          l10n.billingGuardAccountCancelledBody,
        ),
      'trial_expired' => (
          Icons.timer_off,
          l10n.billingGuardTrialEndedTitle,
          l10n.billingGuardTrialEndedBody,
        ),
      _ => (
          Icons.error,
          l10n.billingGuardNoAccessTitle,
          l10n.billingGuardNoAccessBody,
        ),
    };

    final showPayButton =
        (status == 'suspended' || status == 'trial_expired') &&
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
              OutlinedButton.icon(
                onPressed: () {},
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
  final Widget child;
  const _TrialBanner({required this.trialUntil, required this.child});

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
              onPressed: () {},
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
    setState(() => _isLoading = true);

    try {
      await CheckoutService().createAndOpen(companyId: widget.companyId);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingGuardCheckoutOpened),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.billingGuardCheckoutError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
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
