import 'company_setup_wizard.dart';
import 'onboarding_section.dart';

/// Чистая логика Launch Center (тестируемая без UI).
class LaunchCenterLogic {
  const LaunchCenterLogic._();

  static bool canSeeLaunchCenter(String role) {
    switch (role) {
      case 'owner':
      case 'admin':
      case 'super_admin':
        return true;
      default:
        return false;
    }
  }

  static bool canAssignCards(String role) => canSeeLaunchCenter(role);

  static SetupWizardStepStatus effectiveStepStatus({
    required OnboardingSectionId card,
    required CompanySetupWizardState state,
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) {
    if (card == OnboardingSectionId.goLive) {
      if (state.wizardCompleted) return SetupWizardStepStatus.completed;
      return SetupWizardStepStatus.notStarted;
    }
    if (card.isSignalOnly) {
      if (cardSignals[card] == true) return SetupWizardStepStatus.completed;
      return SetupWizardStepStatus.notStarted;
    }
    final steps = card.wizardSteps;
    if (steps.isEmpty) return SetupWizardStepStatus.notStarted;

    final effective = steps
        .map((id) => _upgradeWithSignal(
              state.statusOf(id),
              stepSignals[id] == true,
            ))
        .toList();

    if (effective.every((s) => s == SetupWizardStepStatus.completed)) {
      return SetupWizardStepStatus.completed;
    }
    if (effective.every((s) =>
        s == SetupWizardStepStatus.completed ||
        s == SetupWizardStepStatus.skipped)) {
      return effective.any((s) => s == SetupWizardStepStatus.skipped)
          ? SetupWizardStepStatus.skipped
          : SetupWizardStepStatus.completed;
    }
    if (effective.any((s) =>
        s == SetupWizardStepStatus.inProgress ||
        s == SetupWizardStepStatus.completed ||
        s == SetupWizardStepStatus.skipped)) {
      return SetupWizardStepStatus.inProgress;
    }
    return SetupWizardStepStatus.notStarted;
  }

  static SetupWizardStepStatus _upgradeWithSignal(
    SetupWizardStepStatus stored,
    bool signal,
  ) {
    if (stored == SetupWizardStepStatus.completed ||
        stored == SetupWizardStepStatus.skipped) {
      return stored;
    }
    if (signal) return SetupWizardStepStatus.completed;
    return stored;
  }

  static OnboardingSectionStatus cardStatus(
    OnboardingSectionId card,
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) {
    if (card == OnboardingSectionId.goLive) {
      if (state.wizardCompleted) return OnboardingSectionStatus.completed;
      if (allRequiredCardsDone(
        state,
        stepSignals: stepSignals,
        cardSignals: cardSignals,
      )) {
        return OnboardingSectionStatus.inProgress;
      }
      return OnboardingSectionStatus.notStarted;
    }

    final effective = effectiveStepStatus(
      card: card,
      state: state,
      stepSignals: stepSignals,
      cardSignals: cardSignals,
    );
    return _wizardToSectionStatus(effective);
  }

  static OnboardingSectionStatus _wizardToSectionStatus(
    SetupWizardStepStatus s,
  ) {
    switch (s) {
      case SetupWizardStepStatus.completed:
        return OnboardingSectionStatus.completed;
      case SetupWizardStepStatus.skipped:
        return OnboardingSectionStatus.skipped;
      case SetupWizardStepStatus.inProgress:
        return OnboardingSectionStatus.inProgress;
      case SetupWizardStepStatus.notStarted:
        return OnboardingSectionStatus.notStarted;
    }
  }

  static bool isCardDone(
    OnboardingSectionId card,
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) {
    final s = cardStatus(
      card,
      state,
      stepSignals: stepSignals,
      cardSignals: cardSignals,
    );
    return s == OnboardingSectionStatus.completed ||
        s == OnboardingSectionStatus.skipped;
  }

  static bool allRequiredCardsDone(
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) {
    for (final card in OnboardingSectionId.ordered) {
      if (!card.isRequired) continue;
      if (!isCardDone(
        card,
        state,
        stepSignals: stepSignals,
        cardSignals: cardSignals,
      )) {
        return false;
      }
    }
    return true;
  }

  static int completedCardCount(
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) =>
      OnboardingSectionId.ordered
          .where((c) => cardStatus(
                c,
                state,
                stepSignals: stepSignals,
                cardSignals: cardSignals,
              ) ==
              OnboardingSectionStatus.completed)
          .length;

  static int progressPercent(
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) {
    final total = OnboardingSectionId.ordered.length;
    final done = completedCardCount(
      state,
      stepSignals: stepSignals,
      cardSignals: cardSignals,
    );
    return ((done / total) * 100).round();
  }

  static OnboardingSectionId? nextRecommendedCard(
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) {
    for (final card in OnboardingSectionId.ordered) {
      final s = cardStatus(
        card,
        state,
        stepSignals: stepSignals,
        cardSignals: cardSignals,
      );
      if (s != OnboardingSectionStatus.completed &&
          s != OnboardingSectionStatus.skipped) {
        return card;
      }
    }
    return null;
  }

  static bool isCompanyReady(
    CompanySetupWizardState state, {
    required Map<SetupWizardStepId, bool> stepSignals,
    required Map<OnboardingSectionId, bool> cardSignals,
  }) =>
      allRequiredCardsDone(
        state,
        stepSignals: stepSignals,
        cardSignals: cardSignals,
      );
}
