import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

// Handler pour les messages FCM en background
// Cette fonction DOIT être une fonction top-level (pas dans une classe)
// et DOIT être marquée avec @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase si nécessaire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // print(
  //   '🔔 DEBUG: Message FCM reçu en background: ${message.notification?.title}',
  // );
  // print('🔔 DEBUG: Données: ${message.data}');

  // Afficher la notification locale
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialiser le service de notifications locales si nécessaire
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification_recycling');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await localNotifications.initialize(initializationSettings);

  // Afficher la notification
  const androidDetails = AndroidNotificationDetails(
    'fcm_channel',
    'Notifications FCM',
    channelDescription: 'Notifications push via Firebase Cloud Messaging',
    importance: Importance.max,
    priority: Priority.max,
    icon: 'ic_notification_recycling',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    message.hashCode,
    message.notification?.title ?? 'Notification',
    message.notification?.body ?? 'Nouveau message',
    notificationDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ne jamais bloquer le premier frame trop longtemps : le splash natif
  // reste collé tant que runApp() n'a pas eu lieu.
  await Future.wait([
    _initFirebase(),
    _initAlarmManager(),
  ]);

  runApp(const CollecteDechetsApp());
}

Future<void> _initFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) return;
    final options = DefaultFirebaseOptions.currentPlatform;
    if (DefaultFirebaseOptions.isConfigured(options)) {
      await Firebase.initializeApp(
        options: options,
      ).timeout(const Duration(seconds: 8));
    } else {
      // Sans --dart-define-from-file=.env.json les String.fromEnvironment
      // sont vides. Sur Android, google-services.json suffit.
      await Firebase.initializeApp().timeout(const Duration(seconds: 8));
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init ignorée: $e');
  }
}

Future<void> _initAlarmManager() async {
  try {
    await AndroidAlarmManager.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('AlarmManager init ignorée: $e');
  }
}

class CollecteDechetsApp extends StatelessWidget {
  const CollecteDechetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotiWaste',
      locale: const Locale('fr', 'FR'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 105, 153, 50),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
