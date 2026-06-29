import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/locale_service_stub.dart'
    if (dart.library.html) '../services/locale_service_web.dart';
import '../services/company_provision_service.dart';
import 'firestore_paths.dart';
import '../services/background_location_service.dart';
import 'access_log_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Письмо сброса пароля через Cloud Function (ссылка logiroute-app.web.app).
  Future<String?> sendPasswordResetEmail(
    String email, {
    String? languageCode,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendPasswordResetEmail',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      await callable.call<Map<String, dynamic>>({
        'email': email.trim().toLowerCase(),
        if (languageCode != null && languageCode.isNotEmpty)
          'languageCode': languageCode,
      });
      return null;
    } on FirebaseFunctionsException catch (e) {
      final detail = e.message?.trim();
      final code = (detail != null &&
              detail.isNotEmpty &&
              detail != e.code &&
              !detail.contains(' '))
          ? detail
          : e.code;
      debugPrint('❌ [AuthService] sendPasswordResetEmail: $code — ${e.message}');
      return code;
    } catch (e) {
      debugPrint('❌ [AuthService] sendPasswordResetEmail: $e');
      return 'unknown_error';
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
  bool _initialAuthResolved = false;
  String? _virtualCompanyId; // ✅ Виртуальный companyId для super_admin
  late final StreamSubscription<User?> _authSubscription;
  int _authGen = 0;
  bool _signInBusy = false;
  bool _profileMissing = false;
  Future<void>? _profileLoadFuture;
  String? _profileLoadUid;

  AuthService() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    if (kIsWeb) {
      unawaited(_initWebAuthPersistence());
    }
    // Web: не блокируем UI дольше 12 с (офисная сеть / медленный IndexedDB).
    Future<void>.delayed(const Duration(seconds: 12), () {
      if (_isLoading) {
        debugPrint('⚠️ [AuthService] auth init timeout — unlock UI');
        _completeAuthInit();
      }
    });
  }

  void _completeAuthInit() {
    _initialAuthResolved = true;
    if (!_isLoading) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initWebAuthPersistence() async {
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint('⚠️ [AuthService] setPersistence: $e');
    }
  }

  Future<User?> _resolveUserAfterRestore(User? user) async {
    if (user != null || _initialAuthResolved || !kIsWeb) return user;
    for (var i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      final restored = _auth.currentUser;
      if (restored != null) return restored;
    }
    _initialAuthResolved = true;
    return user;
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
  /// UI simulation (Owner Dashboard / view-as); rules use real claims.
  String? get effectiveRole => _viewAsRole ?? _userModel?.role;
  String? get viewAsRole => _viewAsRole;
  String? get viewAsDriverId => _viewAsDriverId;
  bool get isLoading => _isLoading;
  String? get virtualCompanyId => _virtualCompanyId;

  /// Auth есть, но компания ещё не создана (прерванная self-service регистрация).
  bool get needsCompanyRegistration {
    final user = _currentUser ?? _auth.currentUser;
    if (user == null) return false;
    if (_profileMissing || _userModel == null) return true;
    final cid = _userModel!.companyId;
    if (cid != null && cid.isNotEmpty) return false;
    final role = _userModel!.role;
    return role == 'owner' || role == 'pending';
  }

  /// Установить виртуальный companyId для super_admin
  void setVirtualCompanyId(String? companyId) {
    final canSet = _userModel?.isSuperAdmin == true ||
        (_userModel?.isAdmin == true && _viewAsRole != null);
    if (canSet && _virtualCompanyId != companyId) {
      _virtualCompanyId = companyId;
      print('✅ [AuthService] Virtual companyId set to: $companyId');
      _saveVirtualCompanyToPrefs();
      notifyListeners();
    }
  }

  Future<void> _saveVirtualCompanyToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_virtualCompanyId != null && _virtualCompanyId!.isNotEmpty) {
        await prefs.setString(_kVirtualCompanyId, _virtualCompanyId!);
        await prefs.setString('selected_company_id', _virtualCompanyId!);
        saveSelectedCompanyToWeb(_virtualCompanyId!);
      } else {
        await prefs.remove(_kVirtualCompanyId);
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService] Failed to save virtual company: $e');
    }
  }

  Future<void> _restoreVirtualCompanyFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _virtualCompanyId = prefs.getString(_kVirtualCompanyId) ??
          prefs.getString('selected_company_id');
      _virtualCompanyId ??= loadSelectedCompanyFromWeb();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Failed to restore virtual company: $e');
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_signInBusy) return;
    final gen = ++_authGen;
    user = await _resolveUserAfterRestore(user);
    if (user != null || _initialAuthResolved) {
      _initialAuthResolved = true;
    }
    debugPrint('🔐 [AuthService] _onAuthStateChanged: user=${user?.email}');

    if (user != null && _currentUser?.uid == user.uid && _userModel != null) {
      debugPrint('🔐 [AuthService] Same user already loaded, skipping');
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    _currentUser = user;
    try {
      if (user != null) {
        debugPrint('🔐 [AuthService] Loading user model for uid: ${user.uid}');
        await _loadUserModelOnce(user.uid);
        if (gen != _authGen) return;
        debugPrint(
            '✅ [AuthService] User model loaded: ${_userModel?.email}, role=${_userModel?.role}');
        if (_userModel != null) {
          unawaited(_ensureClaims(user));
        }
        if (gen != _authGen) return;
        if (_userModel?.isAdmin == true) {
          await _restoreViewAsFromPrefs();
          await _restoreVirtualCompanyFromPrefs();
        }
        saveLoginStatusToWeb(true);
      } else {
        debugPrint('🔐 [AuthService] User signed out');
        _userModel = null;
        _viewAsRole = null;
        saveLoginStatusToWeb(false);
      }
    } finally {
      if (gen != _authGen) return;
      if (user != null || _initialAuthResolved) {
        _completeAuthInit();
        debugPrint(
            '✅ [AuthService] _onAuthStateChanged COMPLETE, notifying listeners');
      }
    }
  }

  /// Вызывает Cloud Function ensureMyClaims (ставит role/companyId в токен по
  /// users/{uid}) и, если claims изменились, форсит обновление ID-токена, чтобы
  /// правила Storage/Firestore сразу видели request.auth.token.role/companyId.
  /// Не блокирует вход при ошибке.
  Future<void> _ensureClaims(User user) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'ensureMyClaims',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final res = await callable.call<Map<String, dynamic>>();
      if (res.data['changed'] == true) {
        await user.getIdToken(true);
        debugPrint('🔑 [AuthService] Claims updated → token refreshed');
      }
    } catch (e) {
      debugPrint('⚠️ [AuthService] ensureMyClaims failed (non-blocking): $e');
    }
  }

  Future<void> _loadUserModelOnce(String uid) {
    if (_profileLoadFuture != null && _profileLoadUid == uid) {
      return _profileLoadFuture!;
    }
    _profileLoadUid = uid;
    _profileLoadFuture = _loadUserModel(uid).whenComplete(() {
      if (_profileLoadUid == uid) {
        _profileLoadUid = null;
        _profileLoadFuture = null;
      }
    });
    return _profileLoadFuture!;
  }

  Future<void> _loadUserModel(String uid) async {
    _profileMissing = false;
    try {
      debugPrint('🔐 [AuthService] _loadUserModel START: uid=$uid');
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));
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
        _profileMissing = true;
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
    if (_signInBusy) return 'unknown_error';
    _signInBusy = true;
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔐 [AuthService] signIn START: email=$email');

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = _auth.currentUser;
      if (user == null) return 'unknown_error';

      _currentUser = user;
      _initialAuthResolved = true;
      notifyListeners();

      await _ensureClaims(user);
      await _loadUserModelOnce(user.uid);

      if (_userModel == null) {
        if (_profileMissing) {
          saveLoginStatusToWeb(true);
          return null;
        }
        return 'network-request-failed';
      }

      final cid = _userModel!.companyId;
      if ((cid == null || cid.isEmpty) &&
          (_userModel!.role == 'owner' || _userModel!.role == 'pending')) {
        saveLoginStatusToWeb(true);
        return null;
      }

      if (_userModel?.isAdmin == true) {
        await _restoreViewAsFromPrefs();
        await _restoreVirtualCompanyFromPrefs();
      }
      saveLoginStatusToWeb(true);
      debugPrint('✅ [AuthService] Firebase signIn SUCCESS');
      unawaited(_logAccessEvent(AccessEventType.login));
      return null;
    } catch (e) {
      _currentUser = null;
      _userModel = null;
      try {
        await _auth.signOut();
      } catch (_) {}
      final code = _authErrorCode(e);
      debugPrint('❌ [AuthService] signIn: $code — $e');
      return code;
    } finally {
      _signInBusy = false;
      _isLoading = false;
      notifyListeners();
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

  Future<String?> completeOwnerRegistration({
    required String name,
    required String companyId,
    required String nameHebrew,
    String nameEnglish = '',
    required String taxId,
    String phone = '',
    String? email,
  }) async {
    final user = _currentUser ?? _auth.currentUser;
    if (user == null) return 'unknown_error';

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'registerOwnerCompany',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      await callable.call<Map<String, dynamic>>({
        'companyId': companyId.trim().toLowerCase(),
        'nameHebrew': nameHebrew.trim(),
        'nameEnglish': nameEnglish.trim(),
        'taxId': taxId.trim(),
        'phone': phone.trim(),
        'name': name.trim(),
        'email': (email ?? user.email ?? '').trim().toLowerCase(),
      });

      _profileMissing = false;
      await _ensureClaims(user);
      await user.getIdToken(true);
      await _loadUserModelOnce(user.uid);

      if (_userModel == null) return 'profile-not-found';
      notifyListeners();
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [AuthService] completeOwnerRegistration: ${e.code} — ${e.message}');
      return e.message?.trim().isNotEmpty == true ? e.message! : e.code;
    } catch (e) {
      debugPrint('❌ [AuthService] completeOwnerRegistration: $e');
      return _authErrorCode(e);
    }
  }

  Future<String?> registerOwnerWithCompany({
    required String email,
    required String password,
    required String name,
    required String companyId,
    required String nameHebrew,
    String nameEnglish = '',
    required String taxId,
    String phone = '',
  }) async {
    if (_signInBusy) return 'unknown_error';
    _signInBusy = true;
    _isLoading = true;
    notifyListeners();

    User? created;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      created = cred.user;
      if (created == null) return 'unknown_error';

      final callable = FirebaseFunctions.instance.httpsCallable(
        'registerOwnerCompany',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      await callable.call<Map<String, dynamic>>({
        'companyId': companyId.trim().toLowerCase(),
        'nameHebrew': nameHebrew.trim(),
        'nameEnglish': nameEnglish.trim(),
        'taxId': taxId.trim(),
        'phone': phone.trim(),
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
      });

      _currentUser = created;
      _initialAuthResolved = true;
      await _ensureClaims(created);
      await created.getIdToken(true);
      await _loadUserModelOnce(created.uid);

      if (_userModel == null) return 'profile-not-found';

      saveLoginStatusToWeb(true);
      unawaited(_logAccessEvent(AccessEventType.login));
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [AuthService] registerOwnerCompany: ${e.code} — ${e.message}');
      try {
        await created?.delete();
      } catch (_) {}
      try {
        await _auth.signOut();
      } catch (_) {}
      _currentUser = null;
      _userModel = null;
      return e.message?.trim().isNotEmpty == true ? e.message! : e.code;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('❌ [AuthService] registerOwnerWithCompany: $e');
      try {
        await created?.delete();
      } catch (_) {}
      try {
        await _auth.signOut();
      } catch (_) {}
      _currentUser = null;
      _userModel = null;
      return _authErrorCode(e);
    } finally {
      _signInBusy = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _viewAsRole = null;
    _viewAsDriverId = null;
    _virtualCompanyId = null;
    _currentUser = null;
    _userModel = null;
    saveLoginStatusToWeb(false);
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
  static const _kVirtualCompanyId = 'auth_virtual_company_id';

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
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // ✅ Создаём аккаунт (но основной auth НЕ меняется)
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = userCredential.user!.uid;
      final createdBy = _userModel?.uid ?? 'system';

      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(newUid), {
        'email': email,
        'name': name,
        'role': role,
        'companyId': companyId,
        if (palletCapacity != null) 'palletCapacity': palletCapacity,
        if (truckWeight != null) 'truckWeight': truckWeight,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (companyId.isNotEmpty) {
        batch.set(
          FirestorePaths(firestore: _firestore).members(companyId).doc(newUid),
          {
            'role': role,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': createdBy,
          },
        );
      }
      await batch.commit();

      // ✅ Выйти из secondary (не обязательно, но аккуратно)
      await secondaryAuth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('Unexpected createUser error: $e');
      return 'unknown_error';
    } finally {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }

  /// Привязать существующего пользователя к компании (email уже в Auth).
  Future<String?> linkUserToCompany({
    required String email,
    required String companyId,
    required String role,
    required String name,
    String? phone,
  }) async {
    try {
      final normalized = email.trim().toLowerCase();
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return 'user-not-found';

      final doc = snap.docs.first;
      final data = doc.data();
      final existingCompany = data['companyId'] as String?;
      final existingRole = data['role'] as String?;
      if (existingCompany != null &&
          existingCompany.isNotEmpty &&
          existingCompany != companyId &&
          existingRole != null &&
          existingRole != 'pending') {
        return 'user-in-other-company';
      }

      final createdBy = _userModel?.uid ?? 'system';
      final batch = _firestore.batch();
      batch.set(doc.reference, {
        'email': normalized,
        'name': name.trim(),
        'role': role,
        'companyId': companyId,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(
        FirestorePaths(firestore: _firestore).members(companyId).doc(doc.id),
        {
          'role': role,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': createdBy,
        },
      );
      await batch.commit();
      return null;
    } catch (e) {
      debugPrint('❌ [AuthService] linkUserToCompany: $e');
      return 'unknown_error';
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
