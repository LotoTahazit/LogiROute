import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/correlation/correlation_context.dart';
import '../models/company_onboarding_mode.dart';
import '../services/auth_service.dart';
import '../services/company_modules_service.dart';
import '../services/company_provision_service.dart';
import '../services/company_setup_wizard_service.dart';
import '../services/cross_module_audit_service.dart';
import '../features/owner_dashboard/utils/company_profile_validator.dart';

/// Входные данные 4-шагового Create Company Flow.
class CreateCompanyFlowInput {
  final String companyId;
  final String nameHebrew;
  final String nameEnglish;
  final String taxId;
  final String plan;
  final int trialDays;
  final String ownerName;
  final String ownerEmail;
  final String? ownerPhone;
  final String initialRole;
  final CompanyOnboardingMode onboardingMode;
  final String createdByUid;

  const CreateCompanyFlowInput({
    required this.companyId,
    required this.nameHebrew,
    required this.nameEnglish,
    required this.taxId,
    required this.plan,
    required this.ownerName,
    required this.ownerEmail,
    required this.initialRole,
    required this.onboardingMode,
    required this.createdByUid,
    this.ownerPhone,
    this.trialDays = 14,
  });
}

/// Результат provision.
class CreateCompanyFlowResult {
  final String companyId;
  final String correlationId;
  final CompanyOnboardingMode onboardingMode;
  final String ownerEmail;
  final String? ownerUserId;
  final String plan;
  final DateTime trialUntil;
  final bool linkedExistingUser;
  final bool emailDeliveryFailed;
  final String? emailErrorCode;

  const CreateCompanyFlowResult({
    required this.companyId,
    required this.correlationId,
    required this.onboardingMode,
    required this.ownerEmail,
    required this.plan,
    required this.trialUntil,
    this.ownerUserId,
    this.linkedExistingUser = false,
    this.emailDeliveryFailed = false,
    this.emailErrorCode,
  });
}

class CreateCompanyFlowException implements Exception {
  final String code;
  final String message;
  const CreateCompanyFlowException(this.code, this.message);
  @override
  String toString() => message;
}

/// Super_admin: создание компании + первый owner/admin + onboarding mode.
class CreateCompanyFlowService {
  final FirebaseFirestore _firestore;
  final CompanyProvisionService _provision;

  CreateCompanyFlowService({
    FirebaseFirestore? firestore,
    CompanyProvisionService? provision,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _provision = provision ?? CompanyProvisionService(firestore: firestore);

  static String? validateInput(CreateCompanyFlowInput input) {
    final id = input.companyId.trim().toLowerCase();
    if (!CompanyProvisionService.isValidCompanyId(id)) {
      return 'invalid_company_id';
    }
    if (input.nameHebrew.trim().isEmpty) return 'missing_name';
    final taxErr = CompanyProfileValidator.validateIsraeliTaxId(input.taxId);
    if (taxErr != null) return 'invalid_tax_id';
    if (!CompanyModulesService.planModules.containsKey(input.plan)) {
      return 'invalid_plan';
    }
    if (input.ownerName.trim().isEmpty) return 'missing_owner_name';
    if (input.ownerEmail.trim().isEmpty) return 'missing_owner_email';
    if (input.initialRole != 'owner' && input.initialRole != 'admin') {
      return 'invalid_initial_role';
    }
    return null;
  }

  Future<CreateCompanyFlowResult> execute({
    required CreateCompanyFlowInput input,
    required AuthService auth,
    String? languageCode,
  }) async {
    final validation = validateInput(input);
    if (validation != null) {
      throw CreateCompanyFlowException(validation, validation);
    }

    final companyId = input.companyId.trim().toLowerCase();
    final trace = CorrelationContext.start(
      operation: CorrelatedOperation.createCompany,
      companyId: companyId,
      userId: input.createdByUid,
    );

    try {
      final trialUntil = DateTime.now().add(Duration(days: input.trialDays));
      final created = await _provision.createCompany(
        companyId: companyId,
        nameHebrew: input.nameHebrew.trim(),
        nameEnglish: input.nameEnglish.trim(),
        taxId: input.taxId.trim(),
        createdByUid: input.createdByUid,
        email: input.ownerEmail.trim(),
        phone: input.ownerPhone?.trim() ?? '',
        trialDays: input.trialDays,
        plan: input.plan,
        onboardingMode: input.onboardingMode.value,
      );
      if (!created) {
        throw CreateCompanyFlowException(
          'company_exists',
          'company_exists',
        );
      }

      await _firestore
          .doc('companies/$companyId/settings/setup_wizard')
          .set(
            CompanySetupWizardService.initialFirestorePayload(
              updatedBy: input.createdByUid,
              onboardingMode: input.onboardingMode.value,
            ),
            SetOptions(merge: true),
          );

      final tempPassword = _randomPassword();
      var linkedExisting = false;
      String? ownerUid;

      var createErr = await auth.createUser(
        email: input.ownerEmail.trim(),
        password: tempPassword,
        name: input.ownerName.trim(),
        role: input.initialRole,
        companyId: companyId,
      );

      if (createErr == 'email-already-in-use') {
        createErr = await auth.linkUserToCompany(
          email: input.ownerEmail.trim(),
          companyId: companyId,
          role: input.initialRole,
          name: input.ownerName.trim(),
          phone: input.ownerPhone,
        );
        linkedExisting = createErr == null;
        if (createErr == null) {
          ownerUid = await _uidByEmail(input.ownerEmail.trim());
        }
      } else if (createErr == null) {
        ownerUid = await _uidByEmail(input.ownerEmail.trim());
      }

      if (createErr != null) {
        throw CreateCompanyFlowException(createErr, createErr);
      }

      final emailErr = await auth.sendPasswordResetEmail(
        input.ownerEmail.trim(),
        languageCode: languageCode,
      );

      await _auditProvision(
        companyId: companyId,
        uid: input.createdByUid,
        correlationId: trace.correlationId,
        input: input,
        ownerUid: ownerUid,
        trialUntil: trialUntil,
      );

      return CreateCompanyFlowResult(
        companyId: companyId,
        correlationId: trace.correlationId,
        onboardingMode: input.onboardingMode,
        ownerEmail: input.ownerEmail.trim().toLowerCase(),
        ownerUserId: ownerUid,
        plan: input.plan,
        trialUntil: trialUntil,
        linkedExistingUser: linkedExisting,
        emailDeliveryFailed: emailErr != null,
        emailErrorCode: emailErr,
      );
    } catch (e) {
      debugPrint('❌ [CreateCompanyFlow] cid=${trace.correlationId} $e');
      rethrow;
    }
  }

  static String _randomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#';
    final r = Random.secure();
    return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String?> _uidByEmail(String email) async {
    final snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> _auditProvision({
    required String companyId,
    required String uid,
    required String correlationId,
    required CreateCompanyFlowInput input,
    required DateTime trialUntil,
    String? ownerUid,
  }) async {
    final audit = CrossModuleAuditService(companyId: companyId);
    final extra = {
      'correlationId': correlationId,
      'plan': input.plan,
      'onboardingMode': input.onboardingMode.value,
      'trialUntil': trialUntil.toIso8601String(),
      if (ownerUid != null) 'ownerUserId': ownerUid,
    };
    await audit.log(
      moduleKey: 'logistics',
      type: CrossModuleAuditService.typeCompanyCreated,
      entityCollection: 'companies',
      entityDocId: companyId,
      uid: uid,
      extra: extra,
    );
    await audit.log(
      moduleKey: 'logistics',
      type: CrossModuleAuditService.typeInitialOwnerCreated,
      entityCollection: 'users',
      entityDocId: ownerUid ?? input.ownerEmail,
      uid: uid,
      extra: extra,
    );
    await audit.log(
      moduleKey: 'logistics',
      type: CrossModuleAuditService.typeOnboardingModeSelected,
      entityCollection: 'companies',
      entityDocId: companyId,
      uid: uid,
      extra: extra,
    );
  }

  static String invitationText({
    required String companyName,
    required String ownerEmail,
    required CompanyOnboardingMode mode,
  }) {
    final modeLine = mode == CompanyOnboardingMode.selfSetup
        ? 'Настройка: самостоятельно через Launch Center.'
        : 'Настройка: команда LogiRoute (Done-for-you).';
    return 'Добро пожаловать в LogiRoute!\n'
        'Компания: $companyName\n'
        'Вход: $ownerEmail\n'
        '$modeLine\n'
        'Проверьте почту для установки пароля.';
  }
}
