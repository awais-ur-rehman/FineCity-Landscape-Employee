import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/auth/cubit/auth_state.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/home/cubit/home_cubit.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/schedule/schedule_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shared/bottom_nav.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/task_detail/task_detail_screen.dart';
import '../di/injection.dart';

/// App route paths.
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const schedule = '/schedule';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const taskDetail = '/task/:id';
}

// Navigator keys for shell branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Creates the GoRouter with auth-based redirects and bottom nav shell.
GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthNotifier(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final currentPath = state.uri.path;

      // While checking auth, stay on splash.
      if (authState is AuthInitial || authState is AuthLoading) {
        if (currentPath != AppRoutes.splash) return AppRoutes.splash;
        return null;
      }

      // Authenticated → go to home.
      if (authState is AuthAuthenticated) {
        if (currentPath == AppRoutes.splash || currentPath == AppRoutes.login) {
          return AppRoutes.home;
        }
        return null;
      }

      // Unauthenticated or error → go to login.
      if (currentPath != AppRoutes.login) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Bottom nav shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BlocProvider(
            create: (_) => sl<HomeCubit>(),
            child: BottomNavScaffold(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Task detail — full screen (above bottom nav)
      GoRoute(
        path: '/task/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
    ],
  );
}

/// Notifier that triggers GoRouter refresh on auth state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
