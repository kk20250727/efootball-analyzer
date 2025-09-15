import 'package:flutter/foundation.dart';
import '../models/squad.dart';

class SquadProvider with ChangeNotifier {
  List<Squad> _squads = [];
  bool _isLoading = false;

  List<Squad> get squads => _squads;
  bool get isLoading => _isLoading;

  SquadProvider() {
    _loadDemoData();
  }

  void _loadDemoData() {
    // デモデータを追加
    _squads = [
      Squad(
        id: 'demo-squad-1',
        userId: 'demo-user',
        name: 'メインスカッド',
        formation: '4-3-3',
        memo: '攻撃的フォーメーション',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Squad(
        id: 'demo-squad-2',
        userId: 'demo-user',
        name: '守備重視',
        formation: '5-4-1',
        memo: '堅守速攻',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    notifyListeners();
  }

  Future<void> addSquad(Squad squad) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _squads.insert(0, squad);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSquad(Squad updatedSquad) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _squads.indexWhere((s) => s.id == updatedSquad.id);
    if (index != -1) {
      _squads[index] = updatedSquad;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSquad(String squadId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _squads.removeWhere((s) => s.id == squadId);
    
    _isLoading = false;
    notifyListeners();
  }

  // データロード用のメソッド（画面で呼び出される）
  Future<void> loadSquads() async {
    // デモ版では何もしない（既にデータがロード済み）
    return;
  }

  // IDでスカッドを取得
  Squad? getSquadById(String squadId) {
    try {
      return _squads.firstWhere((squad) => squad.id == squadId);
    } catch (e) {
      return null;
    }
  }
}