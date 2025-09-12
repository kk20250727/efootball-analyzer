import 'package:flutter/foundation.dart';
import '../models/match_result.dart';
import '../services/firebase_service.dart';

class MatchProvider with ChangeNotifier {
  List<MatchData> _matches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchData> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 統計データ
  int get totalMatches => _matches.length;
  int get wins => _matches.where((m) => m.result == MatchResult.win).length;
  int get losses => _matches.where((m) => m.result == MatchResult.loss).length;
  int get draws => _matches.where((m) => m.result == MatchResult.draw).length;
  double get winRate => totalMatches > 0 ? wins / totalMatches : 0.0;
  double get averageGoalsFor => totalMatches > 0 
      ? _matches.fold(0, (sum, m) => sum + m.myScore) / totalMatches 
      : 0.0;
  double get averageGoalsAgainst => totalMatches > 0 
      ? _matches.fold(0, (sum, m) => sum + m.opponentScore) / totalMatches 
      : 0.0;

  Future<void> loadMatches() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .orderBy('matchDate', descending: true)
          .get();

      _matches = querySnapshot.docs
          .map((doc) => MatchData.fromMap(doc.data()))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '戦績データの読み込みに失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMatch(MatchData match) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.firestore
          .collection('matches')
          .doc(match.id)
          .set(match.toMap());

      _matches.insert(0, match);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '戦績データの保存に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMatch(MatchData match) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.firestore
          .collection('matches')
          .doc(match.id)
          .update(match.toMap());

      final index = _matches.indexWhere((m) => m.id == match.id);
      if (index != -1) {
        _matches[index] = match;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '戦績データの更新に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMatch(String matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.firestore
          .collection('matches')
          .doc(matchId)
          .delete();

      _matches.removeWhere((m) => m.id == matchId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '戦績データの削除に失敗しました: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 時間帯別の勝率分析
  Map<int, Map<String, int>> getMatchesByHour() {
    Map<int, Map<String, int>> hourlyStats = {};
    
    for (var match in _matches) {
      int hour = match.matchDate.hour;
      if (!hourlyStats.containsKey(hour)) {
        hourlyStats[hour] = {'wins': 0, 'losses': 0, 'draws': 0, 'total': 0};
      }
      
      hourlyStats[hour]!['total'] = hourlyStats[hour]!['total']! + 1;
      switch (match.result) {
        case MatchResult.win:
          hourlyStats[hour]!['wins'] = hourlyStats[hour]!['wins']! + 1;
          break;
        case MatchResult.loss:
          hourlyStats[hour]!['losses'] = hourlyStats[hour]!['losses']! + 1;
          break;
        case MatchResult.draw:
          hourlyStats[hour]!['draws'] = hourlyStats[hour]!['draws']! + 1;
          break;
      }
    }
    
    return hourlyStats;
  }

  // スカッド別の勝率分析
  Map<String, Map<String, dynamic>> getMatchesBySquad() {
    Map<String, Map<String, dynamic>> squadStats = {};
    
    for (var match in _matches) {
      String squadId = match.squadId ?? 'Unknown';
      if (!squadStats.containsKey(squadId)) {
        squadStats[squadId] = {
          'wins': 0,
          'losses': 0,
          'draws': 0,
          'total': 0,
          'goalsFor': 0,
          'goalsAgainst': 0,
        };
      }
      
      squadStats[squadId]!['total'] = squadStats[squadId]!['total'] + 1;
      squadStats[squadId]!['goalsFor'] = squadStats[squadId]!['goalsFor'] + match.myScore;
      squadStats[squadId]!['goalsAgainst'] = squadStats[squadId]!['goalsAgainst'] + match.opponentScore;
      
      switch (match.result) {
        case MatchResult.win:
          squadStats[squadId]!['wins'] = squadStats[squadId]!['wins'] + 1;
          break;
        case MatchResult.loss:
          squadStats[squadId]!['losses'] = squadStats[squadId]!['losses'] + 1;
          break;
        case MatchResult.draw:
          squadStats[squadId]!['draws'] = squadStats[squadId]!['draws'] + 1;
          break;
      }
    }
    
    return squadStats;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
