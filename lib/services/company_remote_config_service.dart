import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/correlation/correlation_context.dart';
import '../models/company_remote_config.dart';
import 'company_remote_config_validator.dart';
import 'cross_module_audit_service.dart';
import 'firestore_paths.dart';
import 'platform_error_service.dart';

/// Читает companies/{companyId}/settings/remote_config, merge с AppConfig defaults.
class CompanyRemoteConfigService {
  CompanyRemoteConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static final Map<String, CompanyRemoteConfig> _cache = {};

  static String prefsKey(String companyId) => 'company_remote_config_$companyId';

  DocumentReference<Map<String, dynamic>> _doc(String companyId) =>
      FirestorePaths(firestore: _firestore)
          .companySettings(companyId)
          .doc('remote_config');

  CompanyRemoteConfig cached(String companyId) =>
      _cache[companyId] ?? CompanyRemoteConfig.defaults;

  Future<CompanyRemoteConfig> get(String companyId) async {
    if (companyId.isEmpty) return CompanyRemoteConfig.defaults;
    try {
      final snap = await _doc(companyId).get();
      final merged =
          CompanyRemoteConfigValidator.mergeRaw(snap.data());
      _cache[companyId] = merged.config;
      await _reportInvalidIfNeeded(companyId, merged);
      await cacheToPrefs(companyId, merged.config);
      return merged.config;
    } catch (e) {
      debugPrint('⚠️ [RemoteConfig] load failed: $e');
      return CompanyRemoteConfig.defaults;
    }
  }

  Stream<CompanyRemoteConfig> watch(String companyId) {
    if (companyId.isEmpty) {
      return Stream.value(CompanyRemoteConfig.defaults);
    }
    return _doc(companyId).snapshots().asyncMap((snap) async {
      final merged = CompanyRemoteConfigValidator.mergeRaw(snap.data());
      _cache[companyId] = merged.config;
      await _reportInvalidIfNeeded(companyId, merged);
      await cacheToPrefs(companyId, merged.config);
      return merged.config;
    });
  }

  Future<void> refresh(String companyId) async {
    await get(companyId);
  }

  static Future<void> cacheToPrefs(
    String companyId,
    CompanyRemoteConfig config,
  ) async {
    if (companyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey(companyId), jsonEncode(config.toMap()));
    await prefs.setBool(
      'company_bg_auto_close_enabled',
      config.backgroundAutoCloseEnabled,
    );
  }

  static Future<CompanyRemoteConfig> fromPrefs(String companyId) async {
    if (companyId.isEmpty) return CompanyRemoteConfig.defaults;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey(companyId));
      if (raw == null || raw.isEmpty) return CompanyRemoteConfig.defaults;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CompanyRemoteConfigValidator.mergeRaw(map).config;
    } catch (_) {
      return CompanyRemoteConfig.defaults;
    }
  }

  Future<String?> save({
    required String companyId,
    required CompanyRemoteConfig config,
    required String uid,
    required String role,
    CompanyRemoteConfig? previous,
    String? correlationId,
  }) async {
    final err = CompanyRemoteConfigValidator.validateForSave(config);
    if (err != null) return err;

    final cid = correlationId ?? CorrelationContext.resolveId();
    final prev = previous ?? await get(companyId);
    final changed = _changedFields(prev, config);
    final payload = config.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['updatedBy'] = uid;

    await _doc(companyId).set(payload, SetOptions(merge: true));
    _cache[companyId] = config;
    await cacheToPrefs(companyId, config);

    final audit = CrossModuleAuditService(companyId: companyId);
    await audit.log(
      moduleKey: 'logistics',
      type: CrossModuleAuditService.typeRemoteConfigChanged,
      entityCollection: 'settings',
      entityDocId: 'remote_config',
      uid: uid,
      extra: {
        'correlationId': cid,
        'role': role,
        'companyId': companyId,
        'changedFields': changed,
        'oldValues': _pickFields(prev, changed),
        'newValues': _pickFields(config, changed),
        'old': prev.toMap(),
        'new': config.toMap(),
      },
    );
    return null;
  }

  /// Частичное обновление (patch merge с текущим конфигом).
  Future<String?> update({
    required String companyId,
    required Map<String, dynamic> patch,
    required String uid,
    required String role,
    String? correlationId,
  }) async {
    final current = await get(companyId);
    final merged = {...current.toMap(), ...patch};
    final next = CompanyRemoteConfig.fromMap(merged);
    return save(
      companyId: companyId,
      config: next,
      uid: uid,
      role: role,
      previous: current,
      correlationId: correlationId,
    );
  }

  Future<void> resetAll({
    required String companyId,
    required String uid,
    required String role,
  }) async {
    final current = await get(companyId);
    await save(
      companyId: companyId,
      config: CompanyRemoteConfig.defaults,
      uid: uid,
      role: role,
      previous: current,
    );
  }

  static List<String> _changedFields(
    CompanyRemoteConfig prev,
    CompanyRemoteConfig next,
  ) {
    final keys = next.toMap().keys;
    final out = <String>[];
    for (final k in keys) {
      if (prev.toMap()[k] != next.toMap()[k]) out.add(k);
    }
    return out;
  }

  static Map<String, dynamic> _pickFields(
    CompanyRemoteConfig cfg,
    List<String> fields,
  ) {
    final map = cfg.toMap();
    return {for (final f in fields) f: map[f]};
  }

  Future<void> resetField({
    required String companyId,
    required String fieldKey,
    required String uid,
    required String role,
  }) async {
    final current = await get(companyId);
    final defaults = CompanyRemoteConfig.defaults;
    final map = current.toMap();
    final defaultMap = defaults.toMap();
    if (defaultMap.containsKey(fieldKey)) {
      map[fieldKey] = defaultMap[fieldKey];
    }
    final next = CompanyRemoteConfig.fromMap(map);
    await save(
      companyId: companyId,
      config: next,
      uid: uid,
      role: role,
      previous: current,
    );
  }

  Future<void> _reportInvalidIfNeeded(
    String companyId,
    CompanyRemoteConfigValidation merged,
  ) async {
    if (merged.invalidFields.isEmpty) return;
    unawaited(
      PlatformErrorService.report(
        error: 'remote_config_invalid_fields',
        operation: 'remote_config_load',
        companyId: companyId,
        metadata: {
          'invalidFields': merged.invalidFields,
          'warnings': merged.warnings,
        },
        source: 'company_remote_config',
      ),
    );
  }
}
