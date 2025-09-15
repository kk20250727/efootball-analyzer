import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/match_provider.dart';
import '../../providers/squad_provider.dart';
import '../../models/match_result.dart';
import '../../utils/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '全期間';
  final List<String> _periods = ['全期間', '今月', '今週', '今日'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMatches();
      context.read<SquadProvider>().loadSquads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('データ分析'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedPeriod,
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: '概要'),
            Tab(icon: Icon(Icons.pie_chart), text: '戦績'),
            Tab(icon: Icon(Icons.access_time), text: '時間'),
            Tab(icon: Icon(Icons.groups), text: 'スカッド'),
          ],
        ),
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

            final filteredMatches = _getFilteredMatches(matchProvider.matches);

            if (filteredMatches.isEmpty) {
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

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(filteredMatches, squadProvider),
                _buildPerformanceTab(filteredMatches),
                _buildTimeAnalysisTab(filteredMatches),
                _buildSquadAnalysisTab(filteredMatches, squadProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  List<MatchData> _getFilteredMatches(List<MatchData> allMatches) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case '今日':
        return allMatches.where((match) {
          return match.matchDate.day == now.day &&
                 match.matchDate.month == now.month &&
                 match.matchDate.year == now.year;
        }).toList();
      case '今週':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return allMatches.where((match) {
          return match.matchDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
        }).toList();
      case '今月':
        return allMatches.where((match) {
          return match.matchDate.month == now.month &&
                 match.matchDate.year == now.year;
        }).toList();
      case '全期間':
      default:
        return allMatches;
    }
  }

  Widget _buildOverviewTab(List<MatchData> matches, SquadProvider squadProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 期間情報
          _buildPeriodInfoCard(matches),
          const SizedBox(height: 16),
          
          // 主要統計
          _buildMainStatsGrid(matches),
          const SizedBox(height: 16),
          
          // 勝率トレンド
          _buildWinRateTrendChart(matches),
          const SizedBox(height: 16),
          
          // 最近の活動
          _buildRecentActivityCard(matches),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(List<MatchData> matches) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 勝敗分布パイチャート
          _buildResultPieChart(matches),
          const SizedBox(height: 16),
          
          // スコア分析
          _buildScoreAnalysisCard(matches),
          const SizedBox(height: 16),
          
          // 得失点バランス
          _buildGoalBalanceChart(matches),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysisTab(List<MatchData> matches) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 時間帯別勝率
          _buildHourlyWinRateChart(matches),
          const SizedBox(height: 16),
          
          // 曜日別分析
          _buildWeekdayAnalysisCard(matches),
          const SizedBox(height: 16),
          
          // 月別トレンド
          _buildMonthlyTrendChart(matches),
        ],
      ),
    );
  }

  Widget _buildSquadAnalysisTab(List<MatchData> matches, SquadProvider squadProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // スカッド使用率
          _buildSquadUsageChart(matches, squadProvider),
          const SizedBox(height: 16),
          
          // スカッド別詳細統計
          _buildSquadDetailedStats(matches, squadProvider),
        ],
      ),
    );
  }

  Widget _buildPeriodInfoCard(List<MatchData> matches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: AppTheme.cyan, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '分析期間: $_selectedPeriod',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${matches.length}試合のデータを分析',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsGrid(List<MatchData> matches) {
    final wins = matches.where((m) => m.result == MatchResult.win).length;
    final losses = matches.where((m) => m.result == MatchResult.loss).length;
    final draws = matches.where((m) => m.result == MatchResult.draw).length;
    final winRate = matches.isNotEmpty ? (wins / matches.length) * 100 : 0.0;
    
    final totalGoalsScored = matches.isNotEmpty 
        ? matches.map((m) => m.myScore).reduce((a, b) => a + b) 
        : 0;
    final totalGoalsConceded = matches.isNotEmpty 
        ? matches.map((m) => m.opponentScore).reduce((a, b) => a + b) 
        : 0;
    final avgGoalsScored = matches.isNotEmpty ? totalGoalsScored / matches.length : 0.0;
    final avgGoalsConceded = matches.isNotEmpty ? totalGoalsConceded / matches.length : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('勝率', '${winRate.toStringAsFixed(1)}%', AppTheme.green, Icons.trending_up),
        _buildStatCard('総試合数', '${matches.length}', AppTheme.cyan, Icons.sports_soccer),
        _buildStatCard('平均得点', avgGoalsScored.toStringAsFixed(1), AppTheme.blue, Icons.sports_score),
        _buildStatCard('平均失点', avgGoalsConceded.toStringAsFixed(1), AppTheme.orange, Icons.sports),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinRateTrendChart(List<MatchData> matches) {
    if (matches.length < 2) return const SizedBox.shrink();

    // 最近の10試合の勝率推移
    final recentMatches = matches.take(10).toList();
    final spots = <FlSpot>[];
    
    int winCount = 0;
    for (int i = 0; i < recentMatches.length; i++) {
      if (recentMatches[i].result == MatchResult.win) winCount++;
      final winRate = winCount / (i + 1);
      spots.add(FlSpot(i.toDouble(), winRate));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '勝率トレンド（最近10試合）',
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.lightGray.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value * 100).toInt()}%',
                            style: const TextStyle(color: AppTheme.lightGray, fontSize: 12),
                          );
                        },
                        reservedSize: 40,
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
                      color: AppTheme.green,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.green,
                            strokeWidth: 2,
                            strokeColor: AppTheme.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.green.withOpacity(0.3),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPieChart(List<MatchData> matches) {
    final wins = matches.where((m) => m.result == MatchResult.win).length;
    final losses = matches.where((m) => m.result == MatchResult.loss).length;
    final draws = matches.where((m) => m.result == MatchResult.draw).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '勝敗分布',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: wins.toDouble(),
                            title: '勝利\n$wins',
                            color: AppTheme.green,
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: losses.toDouble(),
                            title: '敗北\n$losses',
                            color: AppTheme.red,
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: draws.toDouble(),
                            title: '引分\n$draws',
                            color: AppTheme.orange,
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('勝利', AppTheme.green, wins),
                      _buildLegendItem('敗北', AppTheme.red, losses),
                      _buildLegendItem('引分', AppTheme.orange, draws),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyWinRateChart(List<MatchData> matches) {
    final hourlyStats = <int, Map<String, int>>{};
    
    for (final match in matches) {
      final hour = match.matchDate.hour;
      hourlyStats[hour] ??= {'total': 0, 'wins': 0};
      hourlyStats[hour]!['total'] = hourlyStats[hour]!['total']! + 1;
      if (match.result == MatchResult.win) {
        hourlyStats[hour]!['wins'] = hourlyStats[hour]!['wins']! + 1;
      }
    }

    final barGroups = hourlyStats.entries.map((entry) {
      final hour = entry.key;
      final total = entry.value['total']!;
      final wins = entry.value['wins']!;
      final winRate = total > 0 ? (wins / total) * 100 : 0.0;
      
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: winRate,
            color: winRate >= 50 ? AppTheme.green : AppTheme.red,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '時間帯別勝率',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(color: AppTheme.lightGray, fontSize: 12),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}時',
                            style: const TextStyle(color: AppTheme.lightGray, fontSize: 10),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.lightGray.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(List<MatchData> matches) {
    final recentMatches = matches.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近の活動',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentMatches.map((match) => _buildActivityItem(match)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(MatchData match) {
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
            child: Text(
              '${match.myTeamName} ${match.myScore}-${match.opponentScore} ${match.opponentTeamName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.white,
              ),
            ),
          ),
          Text(
            DateFormat('MM/dd').format(match.matchDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.lightGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreAnalysisCard(List<MatchData> matches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スコア分析',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // スコア分布などの詳細分析をここに追加
            Text(
              '詳細なスコア分析機能は開発中です',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalBalanceChart(List<MatchData> matches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '得失点バランス',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 得失点チャートをここに追加
            Text(
              '得失点バランスチャートは開発中です',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayAnalysisCard(List<MatchData> matches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '曜日別分析',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 曜日別分析をここに追加
            Text(
              '曜日別分析機能は開発中です',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<MatchData> matches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '月別トレンド',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 月別トレンドチャートをここに追加
            Text(
              '月別トレンドチャートは開発中です',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadUsageChart(List<MatchData> matches, SquadProvider squadProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スカッド使用率',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // スカッド使用率チャートをここに追加
            Text(
              'スカッド使用率チャートは開発中です',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadDetailedStats(List<MatchData> matches, SquadProvider squadProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スカッド別詳細統計',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // スカッド別詳細統計をここに追加
            Text(
              'スカッド別詳細統計は開発中です',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}