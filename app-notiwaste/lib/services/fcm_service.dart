import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Initialiser FCM
  static Future<void> initialize() async {
    if (_isInitialized) {
      // print('🔔 DEBUG: FCM déjà initialisé');
      return;
    }

    // print('🔔 DEBUG: Initialisation FCM...');

    // Initialiser le service de notifications locales
    await _initializeLocalNotifications();

    // Demander les permissions
    await _requestPermissions();

    // Configurer les handlers de messages
    _setupMessageHandlers();

    // Obtenir le token FCM
    await _getFCMToken();

    _isInitialized = true;
    // print('🔔 DEBUG: FCM initialisé avec succès');
  }

  // Initialiser le service de notifications locales
  static Future<void> _initializeLocalNotifications() async {
    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification_recycling');

    // Configuration iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    // Configuration globale
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialiser le plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // print('🔔 DEBUG: Notification FCM tapée: ${response.payload}');
      },
    );

    // print('🔔 DEBUG: Service de notifications locales initialisé pour FCM');
  }

  // Demander les permissions
  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // print('🔔 DEBUG: Permissions FCM - Alert: ${settings.alert}');
    // print('🔔 DEBUG: Permissions FCM - Badge: ${settings.badge}');
    // print('🔔 DEBUG: Permissions FCM - Sound: ${settings.sound}');
  }

  // Configurer les handlers de messages
  static void _setupMessageHandlers() {
    // Message reçu quand l'app est en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print(
      //   '🔔 DEBUG: Message reçu en foreground: ${message.notification?.title}',
      // );
      _showLocalNotification(message);
    });

    // Message reçu quand l'app est en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print(
      //   '🔔 DEBUG: Message ouvert depuis background: ${message.notification?.title}',
      // );
    });

    // Message reçu quand l'app est fermée
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // print('🔔 DEBUG: Message initial: ${message.notification?.title}');
      }
    });
  }

  // Afficher une notification locale
  static Future<void> _showLocalNotification(RemoteMessage message) async {
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

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'Nouveau message',
      notificationDetails,
    );
  }

  // Obtenir le token FCM
  static Future<String?> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      // print('🔔 DEBUG: Token FCM: $token');
      return token;
    } catch (e) {
      // print('🔔 DEBUG: Erreur token FCM: $e');
      return null;
    }
  }

  // Obtenir le token FCM (méthode publique)
  static Future<String?> getToken() async {
    return await _getFCMToken();
  }

  // S'abonner à un topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      // print('🔔 DEBUG: Abonné au topic: $topic');
    } catch (e) {
      // print('🔔 DEBUG: Erreur abonnement topic: $e');
    }
  }

  // Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      // print('🔔 DEBUG: Désabonné du topic: $topic');
    } catch (e) {
      // print('🔔 DEBUG: Erreur désabonnement topic: $e');
    }
  }
}
