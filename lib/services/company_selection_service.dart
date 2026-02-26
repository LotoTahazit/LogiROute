import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Модель компании для списка
class CompanyInfo {
  final String id;
  final String name;

  CompanyInfo({required this.id, required this.name});
}

/// Сервис для управления выбранной компанией (для super_admin)
class CompanySelectionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedCompanyId;
  List<CompanyInfo> _availableCompanies = [];
  bool _isLoading = false;

  String? get selectedCompanyId => _selectedCompanyId;
  List<CompanyInfo> get availableCompanies => _availableCompanies;
  bool get isLoading => _isLoading;

  /// Получить эффективный companyId для использования в сервисах
  /// Для super_admin - выбранная компания, для остальных - их companyId
  /// ВАЖНО: Это единственный источник правды для companyId в приложении!
  String? getEffectiveCompanyId(AuthService authService) {
    final user = authService.userModel;
    if (user == null) return null;

    if (user.isSuperAdmin) {
      // Для super_admin используем выбранную компанию
      return _selectedCompanyId;
    } else {
      // Для обычных пользователей - их компания
      return user.companyId;
    }
  }

  /// Устаревший метод - используйте getEffectiveCompanyId
  @Deprecated('Use getEffectiveCompanyId instead')
  String? getCompanyId(AuthService authService) {
    return getEffectiveCompanyId(authService);
  }

  /// Загрузить список доступных компаний
  Future<void> loadCompanies() async {
    _isLoading = true;
    notifyListeners();

    try {
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

      // Если компания не выбрана, выбираем первую
      if (_selectedCompanyId == null && _availableCompanies.isNotEmpty) {
        _selectedCompanyId = _availableCompanies.first.id;
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
      final doc = await _firestore.collection('companies').doc(companyId).get();

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
