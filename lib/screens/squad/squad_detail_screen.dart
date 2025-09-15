import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/match_provider.dart';
import '../../providers/squad_provider.dart';
import '../../models/squad.dart';
import '../../models/match_result.dart';
import '../../utils/app_theme.dart';

class SquadDetailScreen extends StatefulWidget {
  final Squad squad;

  const SquadDetailScreen({
    super.key,
    required this.squad,
  });

  @override
  State<SquadDetailScreen> createState() => _SquadDetailScreenState();
}

class _SquadDetailScreenState extends State<SquadDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.squad.name),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/squads/edit', extra: {'squad': widget.squad});
            },
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppTheme.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: AppTheme.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: Consumer<MatchProvider>(
          builder: (context, matchProvider, child) {
            final squadMatches = matchProvider.matches
                .where((match) => match.squadId == widget.squad.id)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // スカッド基本情報
                  _buildSquadInfoCard(),
                  const SizedBox(height: 24),

                  // 戦績統計
                  _buildStatsCard(squadMatches),
                  const SizedBox(height: 24),

                  // パフォーマンスチャート
                  if (squadMatches.isNotEmpty) ...[
                    _buildPerformanceChart(squadMatches),
                    const SizedBox(height: 24),
                  ],

                  // 最近の試合
                  _buildRecentMatches(squadMatches),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSquadInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      widget.squad.formation.split('-').first,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.squad.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'フォーメーション: ${widget.squad.formation}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.squad.memo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.mediumGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.squad.memo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightGray,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '作成日: ${widget.squad.createdAt.month}/${widget.squad.createdAt.day}/${widget.squad.createdAt.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<MatchData> matches) {
    final totalMatches = matches.length;
    final wins = matches.where((m) => m.result == MatchResult.win).length;
    final losses = matches.where((m) => m.result == MatchResult.loss).length;
    final draws = matches.where((m) => m.result == MatchResult.draw).length;
    final winRate = totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;
    
    final totalGoalsScored = matches.isNotEmpty 
        ? matches.map((m) => m.myScore).reduce((a, b) => a + b) 
        : 0;
    final totalGoalsConceded = matches.isNotEmpty 
        ? matches.map((m) => m.opponentScore).reduce((a, b) => a + b) 
        : 0;
    final avgGoalsScored = totalMatches > 0 ? totalGoalsScored / totalMatches : 0.0;
    final avgGoalsConceded = totalMatches > 0 ? totalGoalsConceded / totalMatches : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '戦績統計',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 基本統計
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('総試合数', '$totalMatches', AppTheme.cyan),
                ),
                Expanded(
                  child: _buildStatItem('勝率', '${winRate.toStringAsFixed(1)}%', AppTheme.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('勝利', '$wins', AppTheme.green),
                ),
                Expanded(
                  child: _buildStatItem('敗北', '$losses', AppTheme.red),
                ),
                Expanded(
                  child: _buildStatItem('引分', '$draws', AppTheme.orange),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('平均得点', avgGoalsScored.toStringAsFixed(1), AppTheme.cyan),
                ),
                Expanded(
                  child: _buildStatItem('平均失点', avgGoalsConceded.toStringAsFixed(1), AppTheme.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.lightGray,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(List<MatchData> matches) {
    if (matches.length < 2) return const SizedBox.shrink();

    // 最近の10試合の勝率推移
    final recentMatches = matches.take(10).toList();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < recentMatches.length; i++) {
      final match = recentMatches[i];
      final winValue = match.result == MatchResult.win ? 1.0 : 0.0;
      spots.add(FlSpot(i.toDouble(), winValue));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近のパフォーマンス',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('負', style: TextStyle(color: AppTheme.lightGray, fontSize: 12));
                          if (value == 1) return const Text('勝', style: TextStyle(color: AppTheme.lightGray, fontSize: 12));
                          return const Text('');
                        },
                        reservedSize: 20,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt() + 1}',
                            style: const TextStyle(color: AppTheme.lightGray, fontSize: 12),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.cyan,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.cyan.withOpacity(0.3),
                      ),
                    ),
                  ],
                  minY: -0.1,
                  maxY: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMatches(List<MatchData> matches) {
    final recentMatches = matches.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近の試合 (${recentMatches.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (recentMatches.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_soccer_outlined,
                      size: 48,
                      color: AppTheme.lightGray,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'このスカッドでの試合記録がありません',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightGray,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentMatches.map((match) => _buildMatchItem(match)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchItem(MatchData match) {
    Color resultColor;
    String resultText;
    
    switch (match.result) {
      case MatchResult.win:
        resultColor = AppTheme.green;
        resultText = 'W';
        break;
      case MatchResult.loss:
        resultColor = AppTheme.red;
        resultText = 'L';
        break;
      case MatchResult.draw:
        resultColor = AppTheme.orange;
        resultText = 'D';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.mediumGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: resultColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                resultText,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.myTeamName} vs ${match.opponentTeamName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${match.matchDate.month}/${match.matchDate.day} ${match.matchDate.hour}:${match.matchDate.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${match.myScore} - ${match.opponentScore}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スカッドを削除'),
        content: Text('「${widget.squad.name}」を削除しますか？\n関連する試合記録は残ります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final squadProvider = context.read<SquadProvider>();
              await squadProvider.deleteSquad(widget.squad.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('スカッドを削除しました'),
                    backgroundColor: AppTheme.green,
                  ),
                );
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
