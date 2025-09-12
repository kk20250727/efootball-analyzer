import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
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
