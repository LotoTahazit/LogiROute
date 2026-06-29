import 'package:flutter_test/flutter_test.dart';
import 'package:logiroute/services/billing_state.dart';

Map<String, dynamic> _company({
  required String billingStatus,
  DateTime? trialUntil,
  DateTime? paidUntil,
  int gracePeriodDays = 7,
}) {
  return {
    'billingStatus': billingStatus,
    if (trialUntil != null) 'trialUntil': trialUntil,
    if (paidUntil != null) 'paidUntil': paidUntil,
    'gracePeriodDays': gracePeriodDays,
  };
}

void main() {
  final now = DateTime(2026, 6, 21, 12);

  group('BillingState', () {
    test('trial active allows access', () {
      final eval = BillingState.evaluateFromMap(
        _company(
          billingStatus: 'trial',
          trialUntil: now.add(const Duration(days: 5)),
        ),
        now: now,
      );
      expect(eval.allowsAccess, true);
      expect(eval.displayPhase, BillingDisplayPhase.trial);
    });

    test('trial expired but grace valid allows access', () {
      final trialUntil = now.subtract(const Duration(days: 1));
      final eval = BillingState.evaluateFromMap(
        _company(billingStatus: 'trial', trialUntil: trialUntil),
        now: now,
      );
      expect(eval.allowsAccess, true);
      expect(eval.displayPhase, BillingDisplayPhase.grace);
      expect(eval.graceUntil, trialUntil.add(const Duration(days: 7)));
    });

    test('grace expired denies access', () {
      final trialUntil = now.subtract(const Duration(days: 10));
      final eval = BillingState.evaluateFromMap(
        _company(billingStatus: 'trial', trialUntil: trialUntil),
        now: now,
      );
      expect(eval.allowsAccess, false);
      expect(eval.blockReason, 'grace_expired');
    });

    test('grace status with valid paidUntil allows access', () {
      final eval = BillingState.evaluateFromMap(
        _company(
          billingStatus: 'grace',
          paidUntil: now.subtract(const Duration(days: 2)),
        ),
        now: now,
      );
      expect(eval.allowsAccess, true);
      expect(eval.displayPhase, BillingDisplayPhase.grace);
    });

    test('grace status expired denies access', () {
      final eval = BillingState.evaluateFromMap(
        _company(
          billingStatus: 'grace',
          paidUntil: now.subtract(const Duration(days: 10)),
        ),
        now: now,
      );
      expect(eval.allowsAccess, false);
    });

    test('suspended denies access', () {
      final eval = BillingState.evaluateFromMap(
        _company(billingStatus: 'suspended'),
        now: now,
      );
      expect(eval.allowsAccess, false);
    });

    test('cancelled denies access', () {
      final eval = BillingState.evaluateFromMap(
        _company(billingStatus: 'cancelled'),
        now: now,
      );
      expect(eval.allowsAccess, false);
    });

    test('missing billing fields fail closed', () {
      expect(
        BillingState.evaluateFromMap(null, now: now).allowsAccess,
        false,
      );
      expect(
        BillingState.evaluateFromMap({'billingStatus': ''}, now: now)
            .allowsAccess,
        false,
      );
      expect(
        BillingState.evaluateFromMap(
          _company(billingStatus: 'trial', trialUntil: null),
          now: now,
        ).allowsAccess,
        false,
      );
    });

    test('blocked legacy alias denies access', () {
      final eval = BillingState.evaluateFromMap(
        _company(billingStatus: 'blocked'),
        now: now,
      );
      expect(eval.allowsAccess, false);
    });
  });
}
