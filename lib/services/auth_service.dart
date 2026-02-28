import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/locale_service_stub.dart'
    if (dart.library.html) '../services/locale_service_web.dart';
import '../services/company_settings_service.dart';

class AuthService extends ChangeNotifier {
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('Unexpected sendPasswordResetEmail error: $e');
      return 'unknown_error';
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  UserModel? _userModel;
  String? _viewAsRole;
  String? _viewAsDriverId;
  bool _isLoading = true;
  String? _virtualCompanyId; // ✅ Виртуальный companyId для super_admin

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
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
    _currentUser = user;
    if (user != null) {
      debugPrint('🔐 [AuthService] Loading user model for uid: ${user.uid}');
      await _loadUserModel(user.uid);
      debugPrint(
          '✅ [AuthService] User model loaded: ${_userModel?.email}, role=${_userModel?.role}');
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

      debugPrint(
          '🔐 [AuthService] Calling Firebase signInWithEmailAndPassword...');
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      debugPrint('✅ [AuthService] Firebase signIn SUCCESS');
      debugPrint('🔐 [AuthService] Waiting for authStateChanges to trigger...');

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected signIn error: $e');
      return 'unknown_error';
    }
  }

  Future<void> signOut() async {
    _viewAsRole = null;
    await _auth.signOut();
  }

  void setViewAsRole(String? role, {String? driverId}) {
    if (_userModel?.isAdmin == true) {
      _viewAsRole = role;
      _viewAsDriverId = driverId;
      notifyListeners();
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
        final companyDoc =
            await _firestore.collection('companies').doc(companyId).get();

        // ✅ Если компании нет - создаём её с инициализацией
        if (!companyDoc.exists) {
          await _firestore.collection('companies').doc(companyId).set({
            'name': companyId, // Используем ID как имя по умолчанию
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': _userModel?.uid ?? 'system',
          });
          print('✅ [AuthService] Created new company: $companyId');

          // Инициализация settings
          try {
            final settingsService =
                CompanySettingsService(companyId: companyId);
            await settingsService.createDefaultSettings();
          } catch (e) {
            debugPrint('⚠️ [AuthService] Failed to init settings: $e');
          }

          // Инициализация counters (lastNumber: 0 → первый номер будет 1)
          try {
            final countersRef = _firestore
                .collection('companies')
                .doc(companyId)
                .collection('counters');
            final batch = _firestore.batch();
            for (final docType in [
              'invoice',
              'receipt',
              'delivery',
              'creditNote'
            ]) {
              batch.set(countersRef.doc(docType), {'lastNumber': 0});
            }
            await batch.commit();
            print('✅ [AuthService] Initialized counters for $companyId');
          } catch (e) {
            debugPrint('⚠️ [AuthService] Failed to init counters: $e');
          }
        }
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
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
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
