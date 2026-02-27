import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notifications.dart';

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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser Android Alarm Manager Plus (DOIT être fait avant runApp)
  await AndroidAlarmManager.initialize();

  // Enregistrer le handler pour les messages en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const CollecteDechetsApp());
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
