import 'package:flutter/foundation.dart';
import '../models/squad.dart';
import '../services/firebase_service.dart';

class SquadProvider with ChangeNotifier {
  List<Squad> _squads = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Squad> get squads => _squads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSquads() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection('squads')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _squads = querySnapshot.docs
          .map((doc) => Squad.fromMap(doc.data()))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'スカッドデータの読み込みに失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSquad(Squad squad) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.firestore
          .collection('squads')
          .doc(squad.id)
          .set(squad.toMap());

      _squads.insert(0, squad);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'スカッドの保存に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSquad(Squad squad) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.firestore
          .collection('squads')
          .doc(squad.id)
          .update(squad.toMap());

      final index = _squads.indexWhere((s) => s.id == squad.id);
      if (index != -1) {
        _squads[index] = squad;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'スカッドの更新に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSquad(String squadId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.firestore
          .collection('squads')
          .doc(squadId)
          .delete();

      _squads.removeWhere((s) => s.id == squadId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'スカッドの削除に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Squad? getSquadById(String squadId) {
    try {
      return _squads.firstWhere((s) => s.id == squadId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
