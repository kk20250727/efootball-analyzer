import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  app_user.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  app_user.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    FirebaseService.authStateChanges.listen((firebase_auth.User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseService.firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = app_user.User.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'ユーザーデータの読み込みに失敗しました: $e';
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String efootballUsername,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        efootballUsername: efootballUsername,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEfootballUsername(String newUsername) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.updateEfootballUsername(newUsername);
      _user = _user!.copyWith(
        efootballUsername: newUsername,
        updatedAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
