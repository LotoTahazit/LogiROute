import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/company_settings.dart';

/// Единая state machine billing (C3).
///
/// Stored statuses в Firestore: `active`, `trial`, `grace`, `suspended`, `cancelled`.
/// `blocked` — legacy alias для `suspended` (не писать в новые документы).
/// `trial_expired` / `past_due` — **не** stored; только UI/audit labels.
enum BillingDisplayPhase { active, trial, grace, blocked }

class BillingEvaluation {
  final bool allowsAccess;
  final BillingDisplayPhase displayPhase;
  final String storedStatus;
  final String? blockReason;
  final DateTime? trialUntil;
  final DateTime? graceUntil;

  const BillingEvaluation({
    required this.allowsAccess,
    required this.displayPhase,
    required this.storedStatus,
    this.blockReason,
    this.trialUntil,
    this.graceUntil,
  });

  /// UI key для blocked screens (`suspended`, `cancelled`, `payment_required`).
  String get blockUiKey {
    if (storedStatus == 'cancelled') return 'cancelled';
    if (storedStatus == 'suspended' || storedStatus == 'blocked') {
      return 'suspended';
    }
    if (blockReason == 'grace_expired' && storedStatus == 'trial') {
      return 'trial_expired';
    }
    return 'payment_required';
  }

  int graceDaysRemaining(DateTime now) {
    if (graceUntil == null) return 0;
    final d = graceUntil!.difference(now).inDays;
    return d < 0 ? 0 : d;
  }
}

class BillingState {
  BillingState._();

  static const canonicalStatuses = [
    'active',
    'trial',
    'grace',
    'suspended',
    'cancelled',
  ];

  /// Legacy alias — treat as suspended.
  static const legacyBlockedStatus = 'blocked';

  static const defaultGraceDays = 7;

  static BillingEvaluation evaluateFromSettings(
    CompanySettings settings, {
    DateTime? now,
  }) {
    return evaluateFromMap(
      {
        'billingStatus': settings.billingStatus,
        'trialUntil': settings.trialEndsAt,
        'trialEndsAt': settings.trialEndsAt,
        'paidUntil': settings.paidUntil,
        'gracePeriodDays': settings.gracePeriodDays,
      },
      now: now,
    );
  }

  static BillingEvaluation evaluateFromMap(
    Map<String, dynamic>? data, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (data == null) {
      return const BillingEvaluation(
        allowsAccess: false,
        displayPhase: BillingDisplayPhase.blocked,
        storedStatus: '',
        blockReason: 'missing_data',
      );
    }

    final status = data['billingStatus'] as String?;
    if (status == null || status.isEmpty) {
      return const BillingEvaluation(
        allowsAccess: false,
        displayPhase: BillingDisplayPhase.blocked,
        storedStatus: '',
        blockReason: 'missing_status',
      );
    }

    if (status == legacyBlockedStatus ||
        status == 'suspended' ||
        status == 'cancelled') {
      return BillingEvaluation(
        allowsAccess: false,
        displayPhase: BillingDisplayPhase.blocked,
        storedStatus: status,
        blockReason: status,
      );
    }

    if (status == 'active') {
      return BillingEvaluation(
        allowsAccess: true,
        displayPhase: BillingDisplayPhase.active,
        storedStatus: status,
      );
    }

    final graceDays = _graceDays(data);

    if (status == 'grace') {
      final anchor = _dateFrom(data['paidUntil']) ?? _dateFrom(data['trialUntil']);
      if (anchor == null) {
        return BillingEvaluation(
          allowsAccess: false,
          displayPhase: BillingDisplayPhase.blocked,
          storedStatus: status,
          blockReason: 'missing_paidUntil',
        );
      }
      final until = anchor.add(Duration(days: graceDays));
      if (clock.isBefore(until)) {
        return BillingEvaluation(
          allowsAccess: true,
          displayPhase: BillingDisplayPhase.grace,
          storedStatus: status,
          graceUntil: until,
        );
      }
      return BillingEvaluation(
        allowsAccess: false,
        displayPhase: BillingDisplayPhase.blocked,
        storedStatus: status,
        blockReason: 'grace_expired',
        graceUntil: until,
      );
    }

    if (status == 'trial') {
      final trialUntil =
          _dateFrom(data['trialUntil']) ?? _dateFrom(data['trialEndsAt']);
      if (trialUntil == null) {
        return BillingEvaluation(
          allowsAccess: false,
          displayPhase: BillingDisplayPhase.blocked,
          storedStatus: status,
          blockReason: 'missing_trialUntil',
        );
      }
      if (clock.isBefore(trialUntil)) {
        return BillingEvaluation(
          allowsAccess: true,
          displayPhase: BillingDisplayPhase.trial,
          storedStatus: status,
          trialUntil: trialUntil,
        );
      }
      final until = trialUntil.add(Duration(days: graceDays));
      if (clock.isBefore(until)) {
        return BillingEvaluation(
          allowsAccess: true,
          displayPhase: BillingDisplayPhase.grace,
          storedStatus: status,
          trialUntil: trialUntil,
          graceUntil: until,
        );
      }
      return BillingEvaluation(
        allowsAccess: false,
        displayPhase: BillingDisplayPhase.blocked,
        storedStatus: status,
        blockReason: 'grace_expired',
        trialUntil: trialUntil,
        graceUntil: until,
      );
    }

    return BillingEvaluation(
      allowsAccess: false,
      displayPhase: BillingDisplayPhase.blocked,
      storedStatus: status,
      blockReason: 'unknown_status',
    );
  }

  static int _graceDays(Map<String, dynamic> data) {
    final raw = data['gracePeriodDays'];
    if (raw is num && raw.toInt() > 0) return raw.toInt();
    return defaultGraceDays;
  }

  static DateTime? _dateFrom(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
