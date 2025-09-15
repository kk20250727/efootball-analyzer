import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      // Web環境では簡単な設定で初期化
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'demo-api-key',
            appId: 'demo-app-id',
            messagingSenderId: 'demo-sender-id',
            projectId: 'efootball-gachi',
            authDomain: 'efootball-gachi.firebaseapp.com',
            storageBucket: 'efootball-gachi.appspot.com',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      print('Firebase初期化成功');
    } catch (e) {
      print('Firebase初期化エラー: $e');
      // Firebase初期化に失敗してもアプリは続行
    }
  }

  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => currentUser?.uid;

  static Stream<User?> get authStateChanges => auth.authStateChanges();

  static Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String efootballUsername,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザー情報をFirestoreに保存
      await firestore.collection('users').doc(credential.user?.uid).set({
        'id': credential.user?.uid,
        'email': email,
        'efootballUsername': efootballUsername,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      throw Exception('アカウント作成に失敗しました: $e');
    }
  }

  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('FirebaseService: signInWithEmailAndPassword呼び出し - $email');
      final result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('FirebaseService: ログイン成功 - ${result.user?.uid}');
      return result;
    } catch (e) {
      print('FirebaseService: ログインエラー - $e');
      throw Exception('ログインに失敗しました: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('ログアウトに失敗しました: $e');
    }
  }

  static Future<void> updateEfootballUsername(String newUsername) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('ユーザーがログインしていません');

      await firestore.collection('users').doc(userId).update({
        'efootballUsername': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('ユーザー名の更新に失敗しました: $e');
    }
  }
}
