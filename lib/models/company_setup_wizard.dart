import 'launch_card_meta.dart';
import 'onboarding_section.dart';

/// Статус шага мастера первого запуска компании.
enum SetupWizardStepStatus {
  notStarted,
  inProgress,
  completed,
  skipped;

  String get firestoreValue => name;

  static SetupWizardStepStatus fromString(String? raw) {
    switch (raw) {
      case 'inProgress':
        return SetupWizardStepStatus.inProgress;
      case 'completed':
        return SetupWizardStepStatus.completed;
      case 'skipped':
        return SetupWizardStepStatus.skipped;
      default:
        return SetupWizardStepStatus.notStarted;
    }
  }
}

/// 10 шагов мастера настройки компании.
enum SetupWizardStepId {
  companyInfo,
  importClients,
  importProducts,
  addDrivers,
  warehouseSetup,
  accountingSetup,
  gpsCheck,
  firstRoute,
  testDelivery,
  ready;

  static const ordered = SetupWizardStepId.values;

  int get stepIndex => ordered.indexOf(this);

  /// Обязательные шаги (нельзя пропустить).
  bool get isRequired {
    switch (this) {
      case SetupWizardStepId.companyInfo:
      case SetupWizardStepId.addDrivers:
      case SetupWizardStepId.gpsCheck:
      case SetupWizardStepId.firstRoute:
      case SetupWizardStepId.testDelivery:
        return true;
      case SetupWizardStepId.ready:
      case SetupWizardStepId.importClients:
      case SetupWizardStepId.importProducts:
      case SetupWizardStepId.warehouseSetup:
      case SetupWizardStepId.accountingSetup:
        return false;
    }
  }

  bool get canSkip => !isRequired && this != SetupWizardStepId.ready;

  String get storageKey => name;
}

class CompanySetupWizardState {
  final bool wizardCompleted;
  final int currentStepIndex;
  final Map<SetupWizardStepId, SetupWizardStepStatus> steps;
  final Map<OnboardingSectionId, LaunchCardMeta> cardMeta;
  final String? onboardingMode;
  final DateTime? completedAt;

  const CompanySetupWizardState({
    this.wizardCompleted = false,
    this.currentStepIndex = 0,
    Map<SetupWizardStepId, SetupWizardStepStatus>? steps,
    Map<OnboardingSectionId, LaunchCardMeta>? cardMeta,
    this.onboardingMode,
    this.completedAt,
  })  : steps = steps ?? const {},
        cardMeta = cardMeta ?? const {};

  factory CompanySetupWizardState.initial() {
    return CompanySetupWizardState(
      steps: {
        for (final s in SetupWizardStepId.ordered)
          s: SetupWizardStepStatus.notStarted,
      },
    );
  }

  SetupWizardStepId get currentStep =>
      SetupWizardStepId.ordered[currentStepIndex.clamp(0, 9)];

  SetupWizardStepStatus statusOf(SetupWizardStepId id) =>
      steps[id] ?? SetupWizardStepStatus.notStarted;

  bool get allRequiredDone {
    for (final s in SetupWizardStepId.ordered) {
      if (s == SetupWizardStepId.ready) continue;
      if (!s.isRequired) continue;
      final st = statusOf(s);
      if (st != SetupWizardStepStatus.completed &&
          st != SetupWizardStepStatus.skipped) {
        return false;
      }
    }
    return true;
  }

  /// Auto-sync по сигналам: только upgrade (notStarted/inProgress → completed).
  /// completed/skipped не трогаем; signal=false никогда не понижает статус.
  static Map<SetupWizardStepId, SetupWizardStepStatus>? applySignalUpgrades(
    Map<SetupWizardStepId, SetupWizardStepStatus> steps,
    Map<SetupWizardStepId, bool> signals,
  ) {
    final next = Map<SetupWizardStepId, SetupWizardStepStatus>.from(steps);
    var changed = false;
    for (final e in signals.entries) {
      if (!e.value) continue;
      final st = next[e.key] ?? SetupWizardStepStatus.notStarted;
      if (st == SetupWizardStepStatus.notStarted ||
          st == SetupWizardStepStatus.inProgress) {
        next[e.key] = SetupWizardStepStatus.completed;
        changed = true;
      }
    }
    return changed ? next : null;
  }

  LaunchCardMeta metaOf(OnboardingSectionId card) =>
      cardMeta[card] ?? const LaunchCardMeta();

  CompanySetupWizardState copyWith({
    bool? wizardCompleted,
    int? currentStepIndex,
    Map<SetupWizardStepId, SetupWizardStepStatus>? steps,
    Map<OnboardingSectionId, LaunchCardMeta>? cardMeta,
    String? onboardingMode,
    DateTime? completedAt,
  }) {
    return CompanySetupWizardState(
      wizardCompleted: wizardCompleted ?? this.wizardCompleted,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      cardMeta: cardMeta ?? this.cardMeta,
      onboardingMode: onboardingMode ?? this.onboardingMode,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory CompanySetupWizardState.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return CompanySetupWizardState.initial();
    final rawSteps = map['steps'] as Map<String, dynamic>? ?? {};
    final parsed = <SetupWizardStepId, SetupWizardStepStatus>{};
    for (final id in SetupWizardStepId.ordered) {
      parsed[id] =
          SetupWizardStepStatus.fromString(rawSteps[id.storageKey] as String?);
    }
    final completedTs = map['completedAt'];
    return CompanySetupWizardState(
      wizardCompleted: map['wizardCompleted'] == true,
      currentStepIndex: (map['currentStepIndex'] as num?)?.toInt() ?? 0,
      steps: parsed,
      cardMeta: LaunchCardMeta.parseCardMeta(
        map['cardMeta'] as Map<String, dynamic>?,
      ),
      onboardingMode: map['onboardingMode'] as String?,
      completedAt: completedTs is DateTime
          ? completedTs
          : null, // Timestamp parsed in service
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wizardCompleted': wizardCompleted,
      'currentStepIndex': currentStepIndex,
      'steps': {
        for (final e in steps.entries) e.key.storageKey: e.value.firestoreValue,
      },
      if (cardMeta.isNotEmpty)
        'cardMeta': LaunchCardMeta.cardMetaToFirestore(cardMeta),
      if (onboardingMode != null) 'onboardingMode': onboardingMode,
      if (completedAt != null) 'completedAt': completedAt,
    };
  }
}
