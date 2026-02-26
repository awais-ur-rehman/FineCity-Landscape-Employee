import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/auth_local_ds.dart';
import '../../data/datasources/local/task_local_ds.dart';
import '../../data/datasources/remote/auth_remote_ds.dart';
import '../../data/datasources/remote/task_remote_ds.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/complete_task.dart';
import '../../domain/usecases/get_today_tasks.dart';
import '../../domain/usecases/send_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/home/cubit/home_cubit.dart';
import '../../presentation/schedule/cubit/schedule_cubit.dart';
import '../../presentation/settings/cubit/settings_cubit.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../services/notification_service.dart';

final sl = GetIt.instance;

/// Initialize all dependencies. Call before runApp.
Future<void> initDependencies({bool firebaseInitialized = false}) async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Notification service — only register with real Firebase if initialized
  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );
  if (firebaseInitialized) {
    sl.registerLazySingleton<NotificationService>(
      () => NotificationService(
        messaging: FirebaseMessaging.instance,
        localNotifications: sl(),
        prefs: sl(),
        apiClient: sl(),
      ),
    );
  } else {
    sl.registerLazySingleton<NotificationService>(
      () => NotificationService.noop(prefs: sl()),
    );
  }

  // Data sources — Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  // Data sources — Tasks
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDs: sl(),
      localDs: sl(),
      apiClient: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDs: sl(),
      localDs: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendOtp(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => GetTodayTasks(sl()));
  sl.registerLazySingleton(() => CompleteTask(sl()));

  // Cubits
  sl.registerFactory(() => AuthCubit(sl()));
  sl.registerFactory(() => HomeCubit(sl()));
  sl.registerFactory(() => ScheduleCubit(sl()));
  sl.registerFactory(() => SettingsCubit(
        notificationService: sl(),
        taskRepository: sl(),
      ));
}
