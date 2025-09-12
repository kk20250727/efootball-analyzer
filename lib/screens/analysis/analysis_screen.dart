import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/match_provider.dart';
import '../../providers/squad_provider.dart';
import '../../utils/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMatches();
      context.read<SquadProvider>().loadSquads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('データ分析'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: Consumer2<MatchProvider, SquadProvider>(
          builder: (context, matchProvider, squadProvider, child) {
            if (matchProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (matchProvider.matches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 80,
                      color: AppTheme.lightGray,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '分析データがありません',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '戦績を追加して分析を始めましょう',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightGray,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 総合戦績
                  _buildOverallStats(matchProvider),
                  const SizedBox(height: 24),

                  // 時間帯別勝率
                  _buildHourlyAnalysis(matchProvider),
                  const SizedBox(height: 24),

                  // スカッド別勝率
                  _buildSquadAnalysis(matchProvider, squadProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverallStats(MatchProvider matchProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '総合戦績',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '総試合数',
                    '${matchProvider.totalMatches}',
                    Icons.sports_soccer,
                    AppTheme.cyan,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '勝率',
                    '${(matchProvider.winRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppTheme.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '勝利',
                    '${matchProvider.wins}',
                    Icons.check_circle,
                    AppTheme.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '敗北',
                    '${matchProvider.losses}',
                    Icons.cancel,
                    AppTheme.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '引き分け',
                    '${matchProvider.draws}',
                    Icons.remove_circle,
                    AppTheme.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '平均得点',
                    matchProvider.averageGoalsFor.toStringAsFixed(1),
                    Icons.sports,
                    AppTheme.cyan,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均失点',
                    matchProvider.averageGoalsAgainst.toStringAsFixed(1),
                    Icons.sports,
                    AppTheme.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.lightGray,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyAnalysis(MatchProvider matchProvider) {
    final hourlyStats = matchProvider.getMatchesByHour();
    
    if (hourlyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '時間帯別勝率',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}時',
                            style: const TextStyle(
                              color: AppTheme.lightGray,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: AppTheme.lightGray,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: hourlyStats.entries.map((entry) {
                    final stats = entry.value;
                    final winRate = stats['total']! > 0 
                        ? (stats['wins']! / stats['total']! * 100)
                        : 0.0;
                    
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: winRate,
                          color: AppTheme.cyan,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadAnalysis(MatchProvider matchProvider, SquadProvider squadProvider) {
    final squadStats = matchProvider.getMatchesBySquad();
    
    if (squadStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スカッド別勝率',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...squadStats.entries.map((entry) {
              final squadId = entry.key;
              final stats = entry.value;
              final squad = squadProvider.getSquadById(squadId);
              final winRate = stats['total'] > 0 
                  ? (stats['wins'] / stats['total'] * 100)
                  : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mediumGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.cyan,
                          radius: 16,
                          child: Text(
                            squad?.formation.split('-').first ?? '?',
                            style: const TextStyle(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            squad?.name ?? 'Unknown Squad',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${winRate.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${squad?.formation ?? 'Unknown'} | ${stats['total']}試合',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat('勝利', stats['wins'], AppTheme.green),
                        const SizedBox(width: 16),
                        _buildMiniStat('敗北', stats['losses'], AppTheme.red),
                        const SizedBox(width: 16),
                        _buildMiniStat('引き分け', stats['draws'], AppTheme.orange),
                        const Spacer(),
                        _buildMiniStat('得点', stats['goalsFor'], AppTheme.cyan),
                        const SizedBox(width: 8),
                        _buildMiniStat('失点', stats['goalsAgainst'], AppTheme.red),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.lightGray,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
