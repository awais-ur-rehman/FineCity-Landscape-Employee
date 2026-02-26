import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/cubit/auth_cubit.dart';
import 'presentation/auth/cubit/auth_state.dart';

/// Root application widget.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: const _AppWithRouter(),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  late final GoRouter _router;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    _router = createRouter(authCubit);
    _notificationService = sl<NotificationService>();

    // Wire notification tap → GoRouter navigation
    _notificationService.onNotificationTap = (taskId) {
      _router.push('/task/$taskId');
    };

    // Register FCM token when user authenticates
    authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _notificationService.registerFcmToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finecity Landscape',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
