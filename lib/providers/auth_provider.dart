import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String email;
  final String efootballUsername;

  User({
    required this.id,
    required this.email,
    required this.efootballUsername,
  });
}

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // デモ用：自動ログイン
    _user = User(
      id: 'demo-user',
      email: 'demo@example.com',
      efootballUsername: 'demo_player',
    );
    print('AuthProvider: デモユーザーでログイン済み');
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String efootballUsername,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // デモ実装：即座に成功
    await Future.delayed(const Duration(milliseconds: 500));
    
    _user = User(
      id: 'new-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      efootballUsername: efootballUsername,
    );
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    print('AuthProvider: ログイン開始 - $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // デモ実装：即座に成功
    await Future.delayed(const Duration(milliseconds: 500));
    
    _user = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      efootballUsername: 'hisa_racer', // デモデータ
    );
    
    print('AuthProvider: ログイン成功 - ${_user?.id}');
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateEfootballUsername(String newUsername) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    // デモ実装
    await Future.delayed(const Duration(milliseconds: 300));
    
    _user = User(
      id: _user!.id,
      email: _user!.email,
      efootballUsername: newUsername,
    );
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}