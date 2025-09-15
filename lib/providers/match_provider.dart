import 'package:flutter/foundation.dart';
import '../models/match_result.dart';

class MatchProvider with ChangeNotifier {
  List<MatchData> _matches = [];
  bool _isLoading = false;

  List<MatchData> get matches => _matches;
  bool get isLoading => _isLoading;

  // 統計データ
  int get totalMatches => _matches.length;
  int get wins => _matches.where((m) => m.result == MatchResult.win).length;
  int get losses => _matches.where((m) => m.result == MatchResult.loss).length;
  int get draws => _matches.where((m) => m.result == MatchResult.draw).length;
  double get winRate => totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;
  double get averageGoalsScored => totalMatches > 0 
      ? _matches.map((m) => m.myScore).reduce((a, b) => a + b) / totalMatches 
      : 0.0;
  double get averageGoalsConceded => totalMatches > 0 
      ? _matches.map((m) => m.opponentScore).reduce((a, b) => a + b) / totalMatches 
      : 0.0;

  // 追加のゲッターメソッド（分析画面で使用）
  double get averageGoalsFor => averageGoalsScored;
  double get averageGoalsAgainst => averageGoalsConceded;

  MatchProvider() {
    _loadDemoData();
  }

  void _loadDemoData() {
    // デモデータを追加
    _matches = [
      MatchData(
        id: 'demo1',
        userId: 'demo-user',
        myTeamName: 'Barcelona',
        opponentTeamName: 'Real Madrid',
        myUsername: 'demo_player',
        opponentUsername: 'rival_player',
        myScore: 2,
        opponentScore: 1,
        result: MatchResult.win,
        matchDate: DateTime.now().subtract(const Duration(days: 1)),
        squadId: null,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MatchData(
        id: 'demo2',
        userId: 'demo-user',
        myTeamName: 'Manchester City',
        opponentTeamName: 'Liverpool',
        myUsername: 'demo_player',
        opponentUsername: 'another_player',
        myScore: 1,
        opponentScore: 3,
        result: MatchResult.loss,
        matchDate: DateTime.now().subtract(const Duration(days: 2)),
        squadId: null,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    notifyListeners();
  }

  Future<void> addMatch(MatchData match) async {
    _isLoading = true;
    notifyListeners();

    // デモ実装：即座に追加
    await Future.delayed(const Duration(milliseconds: 300));
    _matches.insert(0, match);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMatch(MatchData updatedMatch) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _matches.indexWhere((m) => m.id == updatedMatch.id);
    if (index != -1) {
      _matches[index] = updatedMatch;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteMatch(String matchId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _matches.removeWhere((m) => m.id == matchId);
    
    _isLoading = false;
    notifyListeners();
  }

  // データロード用のメソッド（画面で呼び出される）
  Future<void> loadMatches() async {
    // デモ版では何もしない（既にデータがロード済み）
    return;
  }

  // 時間帯別の分析データ
  Map<int, Map<String, dynamic>> getMatchesByHour() {
    Map<int, Map<String, dynamic>> hourlyStats = {};
    
    for (var match in _matches) {
      int hour = match.matchDate.hour;
      if (!hourlyStats.containsKey(hour)) {
        hourlyStats[hour] = {
          'matches': 0,
          'wins': 0,
          'losses': 0,
          'draws': 0,
        };
      }
      
      hourlyStats[hour]!['matches'] = hourlyStats[hour]!['matches'] + 1;
      
      switch (match.result) {
        case MatchResult.win:
          hourlyStats[hour]!['wins'] = hourlyStats[hour]!['wins'] + 1;
          break;
        case MatchResult.loss:
          hourlyStats[hour]!['losses'] = hourlyStats[hour]!['losses'] + 1;
          break;
        case MatchResult.draw:
          hourlyStats[hour]!['draws'] = hourlyStats[hour]!['draws'] + 1;
          break;
      }
    }
    
    return hourlyStats;
  }

  // スカッド別の分析データ
  Map<String, Map<String, dynamic>> getMatchesBySquad() {
    Map<String, Map<String, dynamic>> squadStats = {};
    
    for (var match in _matches) {
      String squadKey = match.squadId ?? 'default';
      if (!squadStats.containsKey(squadKey)) {
        squadStats[squadKey] = {
          'matches': 0,
          'wins': 0,
          'losses': 0,
          'draws': 0,
        };
      }
      
      squadStats[squadKey]!['matches'] = squadStats[squadKey]!['matches'] + 1;
      
      switch (match.result) {
        case MatchResult.win:
          squadStats[squadKey]!['wins'] = squadStats[squadKey]!['wins'] + 1;
          break;
        case MatchResult.loss:
          squadStats[squadKey]!['losses'] = squadStats[squadKey]!['losses'] + 1;
          break;
        case MatchResult.draw:
          squadStats[squadKey]!['draws'] = squadStats[squadKey]!['draws'] + 1;
          break;
      }
    }
    
    return squadStats;
  }
}