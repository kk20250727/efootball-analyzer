import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/match/match_upload_screen.dart';
import '../screens/match/match_ocr_screen.dart';
import '../screens/match/match_confirm_screen.dart';
import '../screens/opponent/opponent_upload_screen.dart';
import '../screens/squad/squad_list_screen.dart';
import '../screens/squad/squad_edit_screen.dart';
import '../screens/squad/squad_detail_screen.dart';
import '../screens/analysis/analysis_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // スプラッシュ画面の場合はリダイレクトしない
      if (state.uri.path == '/splash') {
        return null;
      }
      
      // 認証が必要な画面かチェック
      final protectedRoutes = [
        '/home',
        '/match-upload',
        '/match/ocr',
        '/match/confirm',
        '/opponent-upload',
        '/squads',
        '/analysis',
      ];
      
      final isProtectedRoute = protectedRoutes.any((route) => 
          state.uri.path.startsWith(route));
      
      if (isProtectedRoute && !authProvider.isAuthenticated) {
        return '/login';
      }
      
      // 認証済みでログイン画面にいる場合はホームにリダイレクト
      if (authProvider.isAuthenticated && 
          (state.uri.path == '/login' || state.uri.path == '/signup')) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/match-upload',
        builder: (context, state) => const MatchUploadScreen(),
      ),
      GoRoute(
        path: '/match/ocr',
        builder: (context, state) => const MatchOCRScreen(),
      ),
      GoRoute(
        path: '/match/confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MatchConfirmScreen(
            matchData: extra?['matchData'],
            ocrText: extra?['ocrText'],
          );
        },
      ),
      GoRoute(
        path: '/opponent-upload',
        builder: (context, state) => const OpponentUploadScreen(),
      ),
      GoRoute(
        path: '/squads',
        builder: (context, state) => const SquadListScreen(),
        routes: [
          GoRoute(
            path: '/add',
            builder: (context, state) => const SquadEditScreen(),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return SquadEditScreen(
                squad: extra?['squad'],
              );
            },
          ),
          GoRoute(
            path: '/detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return SquadDetailScreen(
                squad: extra?['squad'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) => const AnalysisScreen(),
      ),
    ],
  );
}
