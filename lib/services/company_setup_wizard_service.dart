import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/company_settings.dart';
import '../models/company_setup_wizard.dart';
import '../models/launch_card_meta.dart';
import '../models/onboarding_section.dart';
import 'firestore_paths.dart';
import 'onboarding_step_signals.dart';
import '../models/usage_event.dart';
import 'usage_analytics_service.dart';

/// Прогресс мастера: companies/{companyId}/settings/setup_wizard
class CompanySetupWizardService {
  CompanySetupWizardService({required this.companyId});

  final String companyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirestorePaths(firestore: _firestore)
          .companySettings(companyId)
          .doc('setup_wizard');

  Stream<CompanySetupWizardState> watchState() {
    return _docRef.snapshots().map((snap) {
      if (!snap.exists) return CompanySetupWizardState.initial();
      return _fromFirestore(snap.data()!);
    });
  }

  Future<CompanySetupWizardState> getState() async {
    final snap = await _docRef.get();
    if (!snap.exists) return CompanySetupWizardState.initial();
    return _fromFirestore(snap.data()!);
  }

  CompanySetupWizardState _fromFirestore(Map<String, dynamic> data) {
    final base = CompanySetupWizardState.fromMap(data);
    final ts = data['completedAt'];
    DateTime? completedAt;
    if (ts is Timestamp) completedAt = ts.toDate();
    return base.copyWith(completedAt: completedAt);
  }

  /// Делегирование карточки Launch Center (роль или userId).
  Future<CompanySetupWizardState> assignCard(
    OnboardingSectionId card, {
    String? assignedRole,
    String? assignedUserId,
    String? notes,
  }) async {
    final current = await getState();
    final meta = Map<OnboardingSectionId, LaunchCardMeta>.from(current.cardMeta);
    final prev = meta[card] ?? const LaunchCardMeta();
    meta[card] = prev.copyWith(
      assignedRole: assignedRole,
      assignedUserId: assignedUserId,
      notes: notes,
      clearRole: assignedRole == null,
      clearUserId: assignedUserId == null,
    );
    final next = current.copyWith(cardMeta: meta);
    await _save(next);
    return next;
  }

  static const _demoCompanyId = 'demo-foods-israel';

  Future<void> _save(CompanySetupWizardState state) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final payload = state.toMap();
    payload.remove('completedAt');
    if (state.completedAt != null) {
      payload['completedAt'] = Timestamp.fromDate(state.completedAt!);
    }
    payload['updatedAt'] = FieldValue.serverTimestamp();
    payload['updatedBy'] = uid;
    if (companyId == _demoCompanyId) payload['isDemo'] = true;
    await _docRef.set(payload, SetOptions(merge: true));
  }

  Future<CompanySetupWizardState> startStep(SetupWizardStepId step) async {
    final current = await getState();
    final steps = Map<SetupWizardStepId, SetupWizardStepStatus>.from(
      current.steps,
    );
    steps[step] = SetupWizardStepStatus.inProgress;
    final next = current.copyWith(
      currentStepIndex: step.stepIndex,
      steps: steps,
    );
    await _save(next);
    unawaited(UsageAnalyticsService.trackFromAuth(
      companyId: companyId,
      event: UsageEventName.onboardingStepOpened,
      entityType: 'setup_wizard_step',
      entityId: step.name,
      metadata: {'step': step.name},
    ));
    return next;
  }

  Future<CompanySetupWizardState> completeStep(SetupWizardStepId step) async {
    final current = await getState();
    final steps = Map<SetupWizardStepId, SetupWizardStepStatus>.from(
      current.steps,
    );
    steps[step] = SetupWizardStepStatus.completed;

    var nextIndex = step.stepIndex + 1;
    if (nextIndex > SetupWizardStepId.ready.stepIndex) {
      nextIndex = SetupWizardStepId.ready.stepIndex;
    }

    var next = current.copyWith(
      steps: steps,
      currentStepIndex: nextIndex,
    );

    if (step == SetupWizardStepId.ready ||
        (next.allRequiredDone && nextIndex >= SetupWizardStepId.ready.stepIndex)) {
      steps[SetupWizardStepId.ready] = SetupWizardStepStatus.completed;
      next = next.copyWith(
        wizardCompleted: true,
        completedAt: DateTime.now(),
        currentStepIndex: SetupWizardStepId.ready.stepIndex,
        steps: steps,
      );
    }

    await _save(next);
    unawaited(UsageAnalyticsService.trackFromAuth(
      companyId: companyId,
      event: UsageEventName.onboardingStepCompleted,
      entityType: 'setup_wizard_step',
      entityId: step.name,
      metadata: {'step': step.name},
    ));
    return next;
  }

  Future<CompanySetupWizardState> skipStep(SetupWizardStepId step) async {
    if (!step.canSkip) {
      throw ArgumentError('Step ${step.name} cannot be skipped');
    }
    final current = await getState();
    final steps = Map<SetupWizardStepId, SetupWizardStepStatus>.from(
      current.steps,
    );
    steps[step] = SetupWizardStepStatus.skipped;
    final nextIndex =
        (step.stepIndex + 1).clamp(0, SetupWizardStepId.ready.stepIndex);
    final next = current.copyWith(
      steps: steps,
      currentStepIndex: nextIndex,
    );
    await _save(next);
    return next;
  }

  Future<void> goToStep(SetupWizardStepId step) async {
    final current = await getState();
    await _save(current.copyWith(currentStepIndex: step.stepIndex));
  }

  Future<bool> needsWizard() async {
    final s = await getState();
    return !s.wizardCompleted;
  }

  /// Авто-завершение шагов по сигналам Firestore (только upgrade, без downgrade).
  Future<CompanySetupWizardState> syncFromSignals({
    CompanySettings? companySettings,
  }) async {
    final current = await getState();
    if (current.wizardCompleted) return current;

    await _backfillMissingMembers();

    final detected = await OnboardingStepSignals(
      companyId: companyId,
      companySettings: companySettings,
    ).checkAll();

    final upgraded = CompanySetupWizardState.applySignalUpgrades(
      current.steps,
      detected,
    );
    if (upgraded == null) return current;

    var next = current.copyWith(steps: upgraded);
    if (next.allRequiredDone) {
      final steps = Map<SetupWizardStepId, SetupWizardStepStatus>.from(
        next.steps,
      );
      steps[SetupWizardStepId.ready] = SetupWizardStepStatus.completed;
      next = next.copyWith(
        steps: steps,
        wizardCompleted: true,
        completedAt: DateTime.now(),
        currentStepIndex: SetupWizardStepId.ready.stepIndex,
      );
    }
    await _save(next);
    return next;
  }

  /// users/ без members/ — legacy createUser; чинит список команды и онбординг.
  Future<void> _backfillMissingMembers() async {
    final usersSnap = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .limit(50)
        .get();
    if (usersSnap.docs.isEmpty) return;

    final paths = FirestorePaths(firestore: _firestore);
    final createdBy = FirebaseAuth.instance.currentUser?.uid ?? 'sync';
    final batch = _firestore.batch();
    var pending = 0;

    for (final doc in usersSnap.docs) {
      final role = doc.data()['role'] as String?;
      if (role == null || role.isEmpty || role == 'pending') continue;
      final memberRef = paths.members(companyId).doc(doc.id);
      final memberSnap = await memberRef.get();
      if (memberSnap.exists) continue;
      batch.set(memberRef, {
        'role': role,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });
      pending++;
    }
    if (pending > 0) await batch.commit();
  }

  /// Начальное состояние wizard при provision компании (companyInfo уже заполнен).
  static Map<String, dynamic> initialFirestorePayload({
    String companyInfoStatus = 'completed',
    String? updatedBy,
    String? onboardingMode,
  }) {
    final steps = <String, String>{
      for (final step in SetupWizardStepId.ordered) step.name: 'notStarted',
    };
    steps[SetupWizardStepId.companyInfo.name] = companyInfoStatus;
    return {
      'wizardCompleted': false,
      'currentStepIndex': SetupWizardStepId.importClients.stepIndex,
      'steps': steps,
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (onboardingMode != null) 'onboardingMode': onboardingMode,
    };
  }
}
