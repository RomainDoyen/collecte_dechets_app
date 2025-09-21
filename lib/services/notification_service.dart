import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/collection_type.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialiser le service de notifications
  static Future<void> initialize() async {
    // Initialiser timezone
    tz.initializeTimeZones();

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
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander les permissions Android
    await _requestPermissions();
  }

  // Demander les permissions Android
  static Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Callback quand on tape sur une notification
  static void _onNotificationTapped(NotificationResponse response) {
    // Ici on pourrait ouvrir l'app ou une page spécifique
    // Notification tapée
  }

  // Programmer une notification pour une collecte
  static Future<void> scheduleCollectionNotification(
    CollectionEvent event,
  ) async {
    final now = DateTime.now();
    final eventDate = event.date;

    // Ne pas programmer si la date est dans le passé
    if (eventDate.isBefore(now)) return;

    // Programmer la notification 1 jour avant
    final notificationDate = eventDate.subtract(const Duration(days: 1));

    // Si c'est déjà dans le passé, programmer pour demain matin 8h
    final scheduledDate =
        notificationDate.isBefore(now)
            ? DateTime(eventDate.year, eventDate.month, eventDate.day, 8, 0)
            : DateTime(
              notificationDate.year,
              notificationDate.month,
              notificationDate.day,
              8,
              0,
            );

    await _notificationsPlugin.zonedSchedule(
      event.hashCode, // ID unique basé sur l'événement
      '🗑️ Collecte de déchets demain !',
      '${event.type.name} prévu le ${eventDate.day}/${eventDate.month}/${eventDate.year}${event.notes != null ? ' - ${event.notes}' : ''}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'collecte_dechets',
          'Collectes de déchets',
          channelDescription: 'Notifications pour les collectes de déchets',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification_recycling',
          color: _getColorForCollectionType(event.type),
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: [DarwinNotificationAttachment('NotificationIcon.png')],
        ),
      ),
      payload: 'collection_${event.hashCode}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Notification programmée
  }

  // Programmer toutes les notifications pour les prochaines collectes
  static Future<void> scheduleAllNotifications(
    List<CollectionEvent> events,
  ) async {
    final now = DateTime.now();

    // Filtrer les événements futurs
    final upcomingEvents =
        events
            .where((event) => event.date.isAfter(now))
            .take(10) // Limiter à 10 notifications pour éviter la surcharge
            .toList();

    // Annuler toutes les notifications existantes
    await cancelAllNotifications();

    // Programmer les nouvelles notifications
    for (final event in upcomingEvents) {
      await scheduleCollectionNotification(event);
    }

    // Notifications programmées
  }

  // Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    // Notifications annulées
  }

  // Annuler une notification spécifique
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Obtenir la couleur pour le type de collecte
  static Color _getColorForCollectionType(CollectionType type) {
    switch (type) {
      case CollectionType.orduresMenageres:
        return const Color(0xFF757575); // Gris
      case CollectionType.collecteSelective:
        return const Color(0xFFF57F17); // Jaune
      case CollectionType.dechetsVerts:
        return const Color(0xFF2E7D32); // Vert
      case CollectionType.encombrants:
        return const Color(0xFFD32F2F); // Rouge
      case CollectionType.dechetsMetalliques:
        return const Color(0xFF1976D2); // Bleu
    }
  }

  // Tester une notification immédiate
  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      999,
      '🗑️ Test - Collecte de déchets',
      'Ceci est une notification de test pour les collectes',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'collecte_dechets',
          'Collectes de déchets',
          channelDescription: 'Notifications pour les collectes de déchets',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification_recycling',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: [DarwinNotificationAttachment('NotificationIcon.png')],
        ),
      ),
    );
  }
}
