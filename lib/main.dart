import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/match_provider.dart';
import 'providers/squad_provider.dart';
import 'services/cache_service.dart';
import 'services/performance_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // キャッシュサービスの初期化
  await CacheService.initialize();
  
  // パフォーマンス監視開始
  PerformanceService.startTimer('アプリ起動');
  
  // Firebase初期化を一時的にスキップして高速起動
  print('アプリ起動中...');
  
  runApp(const EfootballAnalyzerApp());
  
  // 起動時間を測定
  PerformanceService.stopTimer('アプリ起動');
}

class EfootballAnalyzerApp extends StatelessWidget {
  const EfootballAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => SquadProvider()),
      ],
      child: MaterialApp.router(
        title: 'eFootball Analyzer',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}