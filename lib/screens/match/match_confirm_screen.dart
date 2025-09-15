import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/match_provider.dart';
import '../../providers/squad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/match_result.dart';
// import '../../models/match_data.dart'; // このインポートは不要
import '../../services/match_parser_service.dart';
import '../../utils/app_theme.dart';

class MatchConfirmScreen extends StatefulWidget {
  final List<ParsedMatchData>? matchData;
  final String? ocrText;

  const MatchConfirmScreen({
    super.key,
    this.matchData,
    this.ocrText,
  });

  @override
  State<MatchConfirmScreen> createState() => _MatchConfirmScreenState();
}

class _MatchConfirmScreenState extends State<MatchConfirmScreen> {
  List<ParsedMatchData> _matches = [];
  String? _selectedSquadId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _matches = widget.matchData ?? [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SquadProvider>().loadSquads();
    });
  }

  Future<void> _saveMatches() async {
    if (_matches.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    final matchProvider = context.read<MatchProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      for (final parsedMatch in _matches) {
        final result = MatchParserService.determineResult(
          parsedMatch,
          user.efootballUsername,
        );

        final match = MatchData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.id,
          myTeamName: parsedMatch.myTeamName,
          opponentTeamName: parsedMatch.opponentTeamName,
          myUsername: parsedMatch.myUsername,
          opponentUsername: parsedMatch.opponentUsername,
          myScore: parsedMatch.myScore,
          opponentScore: parsedMatch.opponentScore,
          result: result,
          matchDate: parsedMatch.matchDate,
          squadId: _selectedSquadId,
          createdAt: DateTime.now(),
        );

        await matchProvider.addMatch(match);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('戦績を保存しました'),
            backgroundColor: AppTheme.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _updateMatch(int index, ParsedMatchData updatedMatch) {
    setState(() {
      _matches[index] = updatedMatch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('戦績を確認'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveMatches,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: Column(
          children: [
            // スカッド選択
            Consumer<SquadProvider>(
              builder: (context, squadProvider, child) {
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用したスカッド',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSquadId,
                          decoration: const InputDecoration(
                            hintText: 'スカッドを選択（任意）',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('スカッドを選択しない'),
                            ),
                            ...squadProvider.squads.map((squad) {
                              return DropdownMenuItem<String>(
                                value: squad.id,
                                child: Text('${squad.name} (${squad.formation})'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSquadId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 戦績リスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final match = _matches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ヘッダー
                          Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                color: AppTheme.cyan,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '試合 ${index + 1}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${match.matchDate.month}/${match.matchDate.day} ${match.matchDate.hour}:${match.matchDate.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // スコア
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      match.myTeamName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.myUsername,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.lightGray,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.mediumGray,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${match.myScore} - ${match.opponentScore}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      match.opponentTeamName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.opponentUsername,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.lightGray,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 編集ボタン
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showEditDialog(index, match),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('編集'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _matches.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('削除'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.red,
                                    side: const BorderSide(color: AppTheme.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(int index, ParsedMatchData match) {
    final myTeamController = TextEditingController(text: match.myTeamName);
    final opponentTeamController = TextEditingController(text: match.opponentTeamName);
    final myScoreController = TextEditingController(text: match.myScore.toString());
    final opponentScoreController = TextEditingController(text: match.opponentScore.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('試合データを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: myTeamController,
                decoration: const InputDecoration(
                  labelText: '自分のチーム名',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: opponentTeamController,
                decoration: const InputDecoration(
                  labelText: '相手のチーム名',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: myScoreController,
                      decoration: const InputDecoration(
                        labelText: '自分のスコア',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: opponentScoreController,
                      decoration: const InputDecoration(
                        labelText: '相手のスコア',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedMatch = ParsedMatchData(
                myTeamName: myTeamController.text,
                opponentTeamName: opponentTeamController.text,
                myUsername: match.myUsername,
                opponentUsername: match.opponentUsername,
                myScore: int.tryParse(myScoreController.text) ?? match.myScore,
                opponentScore: int.tryParse(opponentScoreController.text) ?? match.opponentScore,
                matchDate: match.matchDate,
              );
              _updateMatch(index, updatedMatch);
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
