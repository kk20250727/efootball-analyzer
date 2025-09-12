import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: const Text('eFootball Analyzer'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // プロフィール画面へ
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('プロフィール'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('ログアウト'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<AuthProvider, MatchProvider>(
        builder: (context, authProvider, matchProvider, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppTheme.darkGradient,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ウェルカムメッセージ
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'こんにちは、${authProvider.user?.efootballUsername ?? 'ユーザー'}さん！',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '今日も戦績を記録して分析しましょう',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 統計サマリー
                  Text(
                    '戦績サマリー',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '総試合数',
                          '${matchProvider.totalMatches}',
                          Icons.sports_soccer,
                          AppTheme.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '勝率',
                          '${(matchProvider.winRate * 100).toStringAsFixed(1)}%',
                          Icons.trending_up,
                          AppTheme.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '勝利',
                          '${matchProvider.wins}',
                          Icons.check_circle,
                          AppTheme.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '敗北',
                          '${matchProvider.losses}',
                          Icons.cancel,
                          AppTheme.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '引き分け',
                          '${matchProvider.draws}',
                          Icons.remove_circle,
                          AppTheme.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // クイックアクション
                  Text(
                    'クイックアクション',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        '戦績を追加',
                        Icons.add_photo_alternate,
                        AppTheme.cyan,
                        () => context.go('/match-upload'),
                      ),
                      _buildActionCard(
                        '対戦相手分析',
                        Icons.people,
                        AppTheme.orange,
                        () => context.go('/opponent-upload'),
                      ),
                      _buildActionCard(
                        'スカッド管理',
                        Icons.group,
                        AppTheme.green,
                        () => context.go('/squad-list'),
                      ),
                      _buildActionCard(
                        'データ分析',
                        Icons.analytics,
                        AppTheme.yellow,
                        () => context.go('/analysis'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 最近の試合
                  Text(
                    '最近の試合',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (matchProvider.isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (matchProvider.matches.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 48,
                                color: AppTheme.lightGray,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'まだ試合記録がありません',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.lightGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '戦績を追加して分析を始めましょう',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.lightGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: matchProvider.matches.take(5).length,
                      itemBuilder: (context, index) {
                        final match = matchProvider.matches[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getResultColor(match.result),
                              child: Icon(
                                _getResultIcon(match.result),
                                color: AppTheme.white,
                              ),
                            ),
                            title: Text(
                              '${match.myTeamName} vs ${match.opponentTeamName}',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${match.myScore} - ${match.opponentScore}',
                              style: const TextStyle(
                                color: AppTheme.lightGray,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              '${match.matchDate.month}/${match.matchDate.day}',
                              style: const TextStyle(
                                color: AppTheme.lightGray,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResultColor(dynamic result) {
    switch (result.toString()) {
      case 'MatchResult.win':
        return AppTheme.green;
      case 'MatchResult.loss':
        return AppTheme.red;
      case 'MatchResult.draw':
        return AppTheme.orange;
      default:
        return AppTheme.lightGray;
    }
  }

  IconData _getResultIcon(dynamic result) {
    switch (result.toString()) {
      case 'MatchResult.win':
        return Icons.check;
      case 'MatchResult.loss':
        return Icons.close;
      case 'MatchResult.draw':
        return Icons.remove;
      default:
        return Icons.help;
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (mounted) {
      context.go('/login');
    }
  }
}
