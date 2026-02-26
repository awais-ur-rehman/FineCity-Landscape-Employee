import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (fails gracefully if not configured)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  // Initialize dependencies
  await initDependencies(firebaseInitialized: firebaseInitialized);

  // Initialize notification service & request permission
  if (firebaseInitialized) {
    final notificationService = sl<NotificationService>();
    await notificationService.init();
    await notificationService.requestPermission();
  }

  runApp(const App());
}
