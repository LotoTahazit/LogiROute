import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с интеграциями компании.
///
/// Предоставляет методы для отправки email, WhatsApp, валидации API-ключей.
/// Настройки читаются из companies/{companyId}/settings/integrations.
class IntegrationService {
  final String companyId;

  IntegrationService({required this.companyId});

  DocumentReference get _integrationsRef => FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('settings')
      .doc('integrations');

  /// Проверяет, включена ли интеграция.
  Future<bool> isEnabled(String key) async {
    try {
      final snap = await _integrationsRef.get();
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final section = data[key] as Map<String, dynamic>?;
      return section != null && section['enabled'] == true;
    } catch (e) {
      debugPrint('❌ [IntegrationService] isEnabled($key) error: $e');
      return false;
    }
  }

  /// Отправляет email через Cloud Function.
  ///
  /// Использует SMTP-настройки компании из интеграций.
  /// Если не настроено — fallback на глобальный SMTP.
  Future<Map<String, dynamic>> sendEmail({
    required List<String> to,
    required String subject,
    String? html,
    String? text,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendCompanyEmail');
      final result = await callable.call({
        'companyId': companyId,
        'to': to,
        'subject': subject,
        'html': html,
        'text': text,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('❌ [IntegrationService] sendEmail error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Отправляет WhatsApp сообщение через Cloud Function.
  Future<Map<String, dynamic>> sendWhatsApp({
    required String phone,
    String? message,
    String? templateName,
    List<String>? templateParams,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendWhatsApp');
      final result = await callable.call({
        'companyId': companyId,
        'phone': phone,
        'message': message,
        'templateName': templateName,
        'templateParams': templateParams,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('❌ [IntegrationService] sendWhatsApp error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Получает текущий API-ключ компании.
  Future<String?> getApiKey() async {
    try {
      final snap = await _integrationsRef.get();
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final apiKeys = data['apiKeys'] as Map<String, dynamic>?;
      if (apiKeys == null || apiKeys['enabled'] != true) return null;
      return apiKeys['key'] as String?;
    } catch (e) {
      debugPrint('❌ [IntegrationService] getApiKey error: $e');
      return null;
    }
  }

  /// Получает настройки конкретной интеграции.
  Future<Map<String, dynamic>?> getIntegrationConfig(String key) async {
    try {
      final snap = await _integrationsRef.get();
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      return data[key] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ [IntegrationService] getConfig($key) error: $e');
      return null;
    }
  }
}
