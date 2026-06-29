import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_service_stub.dart'
    if (dart.library.html) 'locale_service_web.dart';
import 'auth_service.dart';
import 'firestore_paths.dart';

/// Модель компании для списка
class CompanyInfo {
  final String id;
  final String name;

  CompanyInfo({required this.id, required this.name});
}

/// Сервис для управления выбранной компанией (для super_admin)
class CompanySelectionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _kSelectedCompany = 'selected_company_id';

  String? _selectedCompanyId;
  List<CompanyInfo> _availableCompanies = [];
  bool _isLoading = false;

  String? get selectedCompanyId => _selectedCompanyId;
  List<CompanyInfo> get availableCompanies => _availableCompanies;
  bool get isLoading => _isLoading;

  /// Приоритет tenant для super_admin / admin (H2 — Support Console sync).
  @visibleForTesting
  static String? resolveAdminTenant({
    String? selectedCompanyId,
    String? virtualCompanyId,
    String? userCompanyId,
  }) =>
      selectedCompanyId ?? virtualCompanyId ?? userCompanyId;

  /// Получить эффективный companyId для использования в сервисах
  /// Для super_admin - выбранная компания, для остальных - их companyId
  /// ВАЖНО: Это единственный источник правды для companyId в приложении!
  String? getEffectiveCompanyId(AuthService authService) {
    final user = authService.userModel;
    if (user == null) return null;

    if (user.isSuperAdmin || user.isAdmin) {
      return resolveAdminTenant(
        selectedCompanyId: _selectedCompanyId,
        virtualCompanyId: authService.virtualCompanyId,
        userCompanyId: user.companyId,
      );
    }
    return user.companyId;
  }

  Future<void> ensureRestored() async {
    await _restorePersistedSelection();
  }

  Future<void> _restorePersistedSelection() async {
    if (_selectedCompanyId != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCompanyId = prefs.getString(_kSelectedCompany);
      _selectedCompanyId ??= loadSelectedCompanyFromWeb();
    } catch (e) {
      debugPrint('⚠️ [CompanySelection] restore failed: $e');
    }
  }

  Future<void> _persistSelection(String companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedCompany, companyId);
      saveSelectedCompanyToWeb(companyId);
    } catch (e) {
      debugPrint('⚠️ [CompanySelection] persist failed: $e');
    }
  }

  /// Загрузить список доступных компаний
  Future<void> loadCompanies() async {
    _isLoading = true;

    try {
      await _restorePersistedSelection();

      // Получаем все документы компаний
      final snapshot = await _firestore.collection('companies').get();

      _availableCompanies = [];

      for (final doc in snapshot.docs) {
        // Пытаемся получить название из документа
        final data = doc.data();
        String name = doc.id; // По умолчанию используем ID

        // Проверяем разные возможные поля с названием
        if (data.containsKey('name')) {
          name = data['name'] as String;
        } else if (data.containsKey('nameHebrew')) {
          name = data['nameHebrew'] as String;
        } else if (data.containsKey('companyName')) {
          name = data['companyName'] as String;
        }

        _availableCompanies.add(CompanyInfo(id: doc.id, name: name));
      }

      // Сортируем по названию
      _availableCompanies.sort((a, b) => a.name.compareTo(b.name));

      if (_selectedCompanyId != null &&
          !_availableCompanies.any((c) => c.id == _selectedCompanyId)) {
        _selectedCompanyId = null;
      }

      print(
          '📊 [CompanySelection] Loaded ${_availableCompanies.length} companies');
    } catch (e) {
      print('❌ [CompanySelection] Error loading companies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Выбрать компанию
  void selectCompany(String companyId) {
    if (_selectedCompanyId != companyId) {
      _selectedCompanyId = companyId;
      print('✅ [CompanySelection] Selected company: $companyId');
      _persistSelection(companyId);
      notifyListeners();
    }
  }

  /// Установить компанию по умолчанию (для обычных пользователей)
  void setDefaultCompany(String companyId) {
    _selectedCompanyId = companyId;
    // Для обычных пользователей загружаем только их компанию
    _loadSingleCompany(companyId);
  }

  Future<void> _loadSingleCompany(String companyId) async {
    try {
      final doc =
          await FirestorePaths(firestore: _firestore).companyDoc(companyId).get();

      if (doc.exists) {
        final data = doc.data();
        String name = companyId;

        if (data != null) {
          if (data.containsKey('name')) {
            name = data['name'] as String;
          } else if (data.containsKey('nameHebrew')) {
            name = data['nameHebrew'] as String;
          } else if (data.containsKey('companyName')) {
            name = data['companyName'] as String;
          }
        }

        _availableCompanies = [CompanyInfo(id: companyId, name: name)];
        notifyListeners();
      }
    } catch (e) {
      print('❌ [CompanySelection] Error loading company: $e');
    }
  }
}
