import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  UserModel? _userModel;
  String? _viewAsRole;
  bool _isLoading = true;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  String? get userRole => _userModel?.role;
  String? get viewAsRole => _viewAsRole;
  bool get isLoading => _isLoading;

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      await _loadUserModel(user.uid);
    } else {
      _userModel = null;
      _viewAsRole = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      // Возвращаем код для локализации в UI
      return e.code;
    } catch (e) {
      debugPrint('Unexpected signIn error: $e');
      return 'unknown_error';
    }
  }

  Future<void> signOut() async {
    _viewAsRole = null;
    await _auth.signOut();
  }

  void setViewAsRole(String? role) {
    if (_userModel?.isAdmin == true) {
      _viewAsRole = role;
      notifyListeners();
    }
  }

  Future<String?> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    int? palletCapacity,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        if (palletCapacity != null) 'palletCapacity': palletCapacity,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      debugPrint('Unexpected createUser error: $e');
      return 'unknown_error';
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
}
