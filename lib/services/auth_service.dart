import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/locale_service_stub.dart'
    if (dart.library.html) '../services/locale_service_web.dart';
import '../services/company_provision_service.dart';
import '../services/background_location_service.dart';
import 'access_log_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправляет письмо сброса пароля (Firebase Authentication, не Firestore).
  Future<String?> sendPasswordResetEmail(
    String email, {
    String? languageCode,
  }) async {
    try {
      if (languageCode != null && languageCode.isNotEmpty) {
        try {
          await _auth.setLanguageCode(languageCode);
        } catch (e) {
          debugPrint('⚠️ [AuthService] setLanguageCode: $e');
        }
      }
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      final code = _authErrorCode(e);
      debugPrint('❌ [AuthService] sendPasswordResetEmail: $code — $e');
      return code;
    }
  }

  Future<String?> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return null;
    } catch (e) {
      final err = _authErrorCode(e);
      debugPrint('❌ [AuthService] confirmPasswordReset: $err — $e');
      return err;
    }
  }

  /// Android Firebase Auth иногда отдаёт числовые коды (PlatformException).
  static const _androidNumericAuthCodes = {
    '17004': 'invalid-credential',
    '17005': 'user-disabled',
    '17006': 'operation-not-allowed',
    '17007': 'email-already-in-use',
    '17008': 'invalid-email',
    '17009': 'wrong-password',
    '17010': 'too-many-requests',
    '17011': 'user-not-found',
    '17012': 'account-exists-with-different-credential',
    '17014': 'requires-recent-login',
    '17020': 'network-request-failed',
    '17021': 'invalid-user-token',
    '17023': 'user-token-expired',
    '17025': 'credential-already-in-use',
    '17026': 'user-not-found',
    '17028': 'app-not-authorized',
    '17029': 'invalid-credential',
    '17030': 'invalid-credential',
    '17033': 'invalid-api-key',
    '17499': 'internal-error',
  };

  static String _authErrorCode(Object e) {
    String? raw;
    String? message;
    if (e is FirebaseAuthException) {
      raw = e.code;
      message = e.message;
    } else if (e is FirebaseException) {
      raw = e.code;
      message = e.message;
    } else if (e is PlatformException) {
      raw = e.code;
      message = e.message;
    }
    final haystack = '${raw ?? ''} ${message ?? ''} ${e.toString()}';
    if (haystack.contains('app-not-authorized') ||
        haystack.contains('APP_NOT_AUTHORIZED')) {
      return 'app-not-authorized';
    }
    if (haystack.contains('api-key-not-valid') ||
        haystack.contains('API_KEY_NOT_VALID') ||
        haystack.contains('INVALID_API_KEY')) {
      return 'invalid-api-key';
    }
    if (haystack.contains('network-request-failed') ||
        haystack.contains('NETWORK_ERROR')) {
      return 'network-request-failed';
    }
    if (raw != null) {
      var code = raw.trim();
      if (code.startsWith('error-code:')) {
        code = code.substring('error-code:'.length).trim();
      }
      final auth = RegExp(r'\(auth/([^)]+)\)|auth/([\w-]+)').firstMatch(haystack);
      if (auth != null) return auth.group(1) ?? auth.group(2)!;
      if (RegExp(r'^-?\d+$').hasMatch(code)) {
        return _androidNumericAuthCodes[code] ?? 'error-code:$code';
      }
      code = code.replaceAll('ERROR_', '').toLowerCase().replaceAll('_', '-');
      if (code.isEmpty) return 'unknown_error';
      return code;
    }
    final auth = RegExp(r'auth/([\w-]+)').firstMatch(haystack);
    return auth?.group(1) ?? 'unknown_error';
  }

  User? _currentUser;
  UserModel? _userModel;
  String? _viewAsRole;
  String? _viewAsDriverId;
  bool _isLoading = true;
  String? _virtualCompanyId; // ✅ Виртуальный companyId для super_admin
  late final StreamSubscription<User?> _authSubscription;

  AuthService() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  User? get currentUser => _currentUser;

  // ✅ Виртуальный userModel с подменённым companyId для super_admin
  UserModel? get userModel {
    if (_userModel == null) return null;

    // Если super_admin выбрал компанию - возвращаем виртуальную модель
    if (_userModel!.isSuperAdmin && _virtualCompanyId != null) {
      return UserModel(
        uid: _userModel!.uid,
        email: _userModel!.email,
        name: _userModel!.name,
        role: _userModel!.role,
        companyId: _virtualCompanyId!, // ✅ Подменяем companyId
        palletCapacity: _userModel!.palletCapacity,
        vehicleNumber: _userModel!.vehicleNumber,
        truckWeight: _userModel!.truckWeight,
      );
    }

    return _userModel;
  }

  String? get userRole => _userModel?.role;
  String? get viewAsRole => _viewAsRole;
  String? get viewAsDriverId => _viewAsDriverId;
  bool get isLoading => _isLoading;

  /// Установить виртуальный companyId для super_admin
  void setVirtualCompanyId(String? companyId) {
    if (_userModel?.isSuperAdmin == true && _virtualCompanyId != companyId) {
      _virtualCompanyId = companyId;
      print('✅ [AuthService] Virtual companyId set to: $companyId');
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    debugPrint('🔐 [AuthService] _onAuthStateChanged: user=${user?.email}');

    // Дедупликация: если тот же пользователь уже загружен — не перезагружаем
    if (user != null && _currentUser?.uid == user.uid && _userModel != null) {
      debugPrint('🔐 [AuthService] Same user already loaded, skipping');
      return;
    }

    _currentUser = user;
    if (user != null) {
      debugPrint('🔐 [AuthService] Loading user model for uid: ${user.uid}');
      await _loadUserModel(user.uid);
      debugPrint(
          '✅ [AuthService] User model loaded: ${_userModel?.email}, role=${_userModel?.role}');
      // 🛡️ Восстанавливаем viewAsRole из SharedPreferences (только для админов)
      if (_userModel?.isAdmin == true) {
        await _restoreViewAsFromPrefs();
      }
      // Сохраняем статус логина для веба (для кнопки скачивания)
      saveLoginStatusToWeb(true);
    } else {
      debugPrint('🔐 [AuthService] User signed out');
      _userModel = null;
      _viewAsRole = null;
      // Сохраняем статус разлогина для веба
      saveLoginStatusToWeb(false);
    }
    _isLoading = false;
    debugPrint(
        '✅ [AuthService] _onAuthStateChanged COMPLETE, notifying listeners');
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      debugPrint('🔐 [AuthService] _loadUserModel START: uid=$uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      debugPrint('🔐 [AuthService] Firestore doc.exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        if (data == null) {
          debugPrint('❌ [AuthService] User document exists but data is null');
          _userModel = null;
          return;
        }

        // Безопасное чтение полей
        final role = (data['role'] as String?) ?? 'unknown';
        final companyId = data['companyId'] as String?;

        debugPrint(
            '🔐 [AuthService] User data: role=$role, companyId=$companyId');

        // Проверка обязательных полей для ролей
        if ((role == 'dispatcher' ||
                role == 'driver' ||
                role == 'warehouse_keeper') &&
            (companyId == null || companyId.isEmpty)) {
          debugPrint('❌ [AuthService] Missing companyId for role: $role');
          _userModel = null;
          return;
        }

        _userModel = UserModel.fromMap(data, uid);
        debugPrint(
            '✅ [AuthService] UserModel created: ${_userModel?.email}, role=${_userModel?.role}, companyId=${_userModel?.companyId}');
      } else {
        // Профиль не найден в Firestore
        debugPrint(
            '❌ [AuthService] User profile not found in Firestore for uid: $uid');
        _userModel = null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthService] Error loading user: $e');
      debugPrint('Stack trace: $stackTrace');
      _userModel = null;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      debugPrint('🔐 [AuthService] signIn START: email=$email');

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _loadUserModel(uid);
        if (_userModel == null) {
          await _auth.signOut();
          return 'profile-not-found';
        }
      }

      debugPrint('✅ [AuthService] Firebase signIn SUCCESS');
      unawaited(_logAccessEvent(AccessEventType.login));

      return null;
    } catch (e) {
      final code = _authErrorCode(e);
      debugPrint('❌ [AuthService] signIn: $code — $e');
      return code;
    }
  }

  Future<void> _logAccessEvent(AccessEventType type) async {
    final uid = _currentUser?.uid ?? _auth.currentUser?.uid;
    if (uid == null) return;
    if (_userModel == null) await _loadUserModel(uid);
    final companyId = _userModel?.companyId;
    if (companyId == null || companyId.isEmpty) return;
    await AccessLogService(companyId: companyId).logAccess(
      actorUid: uid,
      eventType: type,
      actorName: _userModel?.name,
    );
  }

  Future<void> signOut() async {
    _viewAsRole = null;
    _viewAsDriverId = null;
    _virtualCompanyId = null;
    notifyListeners();

    unawaited(_clearViewAsPrefs());
    unawaited(_logAccessEvent(AccessEventType.logout));

    // Сначала выход — GPS cleanup только если трекинг реально был включён
    await _auth.signOut();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('bg_tracking_active') == true) {
        await BackgroundLocationService.stop()
            .timeout(const Duration(seconds: 2));
      }
    } catch (_) {}
  }

  // 🛡️ Persistent keys for viewAsRole
  static const _kViewAsRole = 'auth_view_as_role';
  static const _kViewAsDriverId = 'auth_view_as_driver_id';

  void setViewAsRole(String? role, {String? driverId}) {
    if (_userModel?.isAdmin == true) {
      _viewAsRole = role;
      _viewAsDriverId = driverId;
      _saveViewAsToPrefs();
      notifyListeners();
    }
  }

  Future<void> _saveViewAsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_viewAsRole != null) {
        await prefs.setString(_kViewAsRole, _viewAsRole!);
      } else {
        await prefs.remove(_kViewAsRole);
      }
      if (_viewAsDriverId != null) {
        await prefs.setString(_kViewAsDriverId, _viewAsDriverId!);
      } else {
        await prefs.remove(_kViewAsDriverId);
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService] Failed to save viewAs prefs: $e');
    }
  }

  Future<void> _restoreViewAsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _viewAsRole = prefs.getString(_kViewAsRole);
      _viewAsDriverId = prefs.getString(_kViewAsDriverId);
      if (_viewAsRole != null) {
        debugPrint(
            '✅ [AuthService] Restored viewAs: role=$_viewAsRole, driverId=$_viewAsDriverId');
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService] Failed to restore viewAs prefs: $e');
    }
  }

  Future<void> _clearViewAsPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kViewAsRole);
      await prefs.remove(_kViewAsDriverId);
    } catch (e) {
      debugPrint('⚠️ [AuthService] Failed to clear viewAs prefs: $e');
    }
  }

  Future<String?> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    required String companyId,
    int? palletCapacity,
    double? truckWeight,
    String? vehicleNumber,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // ✅ Проверяем существует ли компания
      if (companyId.isNotEmpty) {
        await CompanyProvisionService(firestore: _firestore).ensureCompanyExists(
          companyId: companyId,
          createdByUid: _userModel?.uid ?? 'system',
        );
      }

      // ✅ Secondary app — чтобы НЕ разлогинивать текущего админа/суперадмина
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_ ${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // ✅ Создаём аккаунт (но основной auth НЕ меняется)
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = userCredential.user!.uid;

      // ✅ Пишем профиль в Firestore уже от ТЕКУЩЕГО залогиненного админа
      await _firestore.collection('users').doc(newUid).set({
        'email': email,
        'name': name,
        'role': role,
        'companyId': companyId,
        if (palletCapacity != null) 'palletCapacity': palletCapacity,
        if (truckWeight != null) 'truckWeight': truckWeight,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Выйти из secondary (не обязательно, но аккуратно)
      await secondaryAuth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('Unexpected createUser error: $e');
      return 'unknown_error';
    } finally {
      // ✅ Удаляем secondary app, чтобы не копились инстансы (особенно на Web)
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      // Filter by company on server side when not super_admin
      Query query = _firestore.collection('users');
      if (_userModel != null && !_userModel!.isSuperAdmin) {
        final companyId = _virtualCompanyId ?? _userModel!.companyId;
        if (companyId != null && companyId.isNotEmpty) {
          query = query.where('companyId', isEqualTo: companyId);
        }
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  /// Обновление данных пользователя (email, роль, пароль)
  Future<String?> updateUser({
    required String uid,
    String? newEmail,
    String? newPassword,
    String? newRole,
    String? newName,
    int? palletCapacity,
    double? truckWeight,
    String? vehicleNumber,
  }) async {
    try {
      // Обновляем данные в Firestore
      final Map<String, dynamic> updates = {};

      if (newEmail != null) updates['email'] = newEmail;
      if (newRole != null) updates['role'] = newRole;
      if (newName != null) updates['name'] = newName;
      if (palletCapacity != null) updates['palletCapacity'] = palletCapacity;
      if (truckWeight != null) updates['truckWeight'] = truckWeight;
      if (vehicleNumber != null) updates['vehicleNumber'] = vehicleNumber;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }

      // Если нужно обновить email или пароль в Firebase Auth
      // Это можно сделать только через Admin SDK на сервере
      // Для веб-приложения используем Cloud Functions или Admin SDK
      // Пока оставим заглушку - в продакшене нужен backend

      return null;
    } on FirebaseException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('Unexpected updateUser error: $e');
      return 'unknown_error';
    }
  }

  /// Удаление пользователя
  Future<String?> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      // Удаление из Firebase Auth требует Admin SDK
      return null;
    } on FirebaseException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('Unexpected deleteUser error: $e');
      return 'unknown_error';
    }
  }
}
