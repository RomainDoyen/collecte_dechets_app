import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'collection_service.dart';

/// Service de notifications ULTRA SIMPLE
/// Rien d'autre que le strict minimum
class Notifications {
  // ⏰ HEURE DE NOTIFICATION (modifiable facilement)
  static const int notificationHour = 18; // Heure (0-23)
  static const int notificationMinute = 00; // Minute (0-59)

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _init = false;
  static Timer? _checkTimer;
  static final Map<int, Timer> _activeTimers = {};
  static bool _scheduling = false;

  /// Initialiser - UNIQUEMENT ce qui est nécessaire
  static Future<bool> init() async {
    if (_init) return true;

    try {
      // Initialiser timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Indian/Reunion'));

      // Configuration Android minimale
      const android = AndroidInitializationSettings(
        'ic_notification_recycling',
      );

      // Configuration iOS minimale
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(android: android, iOS: ios);

      // Initialiser
      final ok = await _notifications.initialize(settings);
      if (ok == false) return false;

      // Créer canal Android
      const channel = AndroidNotificationChannel(
        'notifications',
        'Notifications',
        description: 'Notifications de l\'application',
        importance: Importance.max,
      );

      final androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();

        // Vérifier les permissions
        final notificationsEnabled =
            await androidPlugin.areNotificationsEnabled();
        final exactAlarmsEnabled =
            await androidPlugin.canScheduleExactNotifications();
        // print(
        //   '🔔 Permissions - Notifications: ${notificationsEnabled ?? false}',
        // );
        // print('🔔 Permissions - Alarmes exactes: $exactAlarmsEnabled');

        // Demander à désactiver les optimisations de batterie (important pour WorkManager)
        // Note: Sur Xiaomi/Redmi, cela ouvre les paramètres pour que l'utilisateur désactive
        // manuellement les optimisations (obligatoire pour la sécurité Android)
        try {
          // print(
          //   '⚠️ Ouverture des paramètres pour désactiver les optimisations de batterie...',
          // );
          DisableBatteryOptimization.showDisableAllOptimizationsSettings(
            'Notifications importantes',
            'Pour recevoir les notifications de collecte même quand l\'app est fermée, veuillez désactiver les optimisations de batterie.',
            'Optimisations de batterie détectées',
            'Votre appareil limite les notifications en arrière-plan. Désactivez les optimisations pour cette application.',
          );
        } catch (e) {
          // print('⚠️ Erreur ouverture paramètres optimisations batterie: $e');
        }
      }

      // Android Alarm Manager Plus est déjà initialisé dans main.dart
      // print('✅ Android Alarm Manager Plus disponible');

      // Initialiser WorkManager pour vérifier les notifications en arrière-plan (secours)
      try {
        await Workmanager().initialize(callbackDispatcher);
        // print('✅ WorkManager initialisé');

        // Programmer une tâche périodique toutes les 5 minutes (pour tests)
        // En production, vous pouvez augmenter à 15 minutes
        await Workmanager().registerPeriodicTask(
          'check-notifications',
          'checkNotifications',
          frequency: const Duration(minutes: 5),
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
        );
        // print('✅ Tâche WorkManager programmée (toutes les 5 minutes)');
      } catch (e) {
        // print('⚠️ Erreur WorkManager (continuons sans): $e');
      }

      _init = true;
      return true;
    } catch (e) {
      // print('❌ Erreur init notifications: $e');
      return false;
    }
  }

  /// Envoyer une notification IMMÉDIATE - TEST UNIQUEMENT
  static Future<void> test() async {
    try {
      const android = AndroidNotificationDetails(
        'notifications',
        'Notifications',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_notification_recycling',
      );

      const ios = DarwinNotificationDetails();

      const details = NotificationDetails(android: android, iOS: ios);

      await _notifications.show(
        1,
        'TEST',
        'Si vous voyez ceci, ça fonctionne !',
        details,
      );

      // print('✅ Notification test envoyée');
    } catch (e) {
      // print('❌ Erreur test: $e');
    }
  }

  /// Programmer une notification dans X secondes (pour test)
  /// Utilise un Timer pour forcer l'affichage (contournement Xiaomi)
  static Future<void> testInSeconds(int seconds) async {
    try {
      final now = DateTime.now();
      final scheduled = now.add(Duration(seconds: seconds));

      // print('🔔 [Test] Maintenant: $now');
      // print('🔔 [Test] Programmé pour: $scheduled');
      // print('🔔 [Test] Dans $seconds secondes');

      // Annuler l'ancien timer si existe
      _checkTimer?.cancel();

      // Programmer avec zonedSchedule (méthode normale)
      const android = AndroidNotificationDetails(
        'notifications',
        'Notifications',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_notification_recycling',
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: android, iOS: ios);

      final tzDate = tz.TZDateTime.from(scheduled, tz.local);
      // print('🔔 [Test] TZDateTime: $tzDate');

      await _notifications.zonedSchedule(
        2,
        'TEST PROGRAMMÉ',
        'Notification programmée dans $seconds secondes',
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // TIMER DE SECOURS : Vérifier toutes les secondes et forcer l'affichage
      int countdown = seconds;
      _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        countdown--;
        final now = DateTime.now();

        if (countdown <= 0 ||
            now.isAfter(scheduled) ||
            now.isAtSameMomentAs(scheduled)) {
          timer.cancel();
          // Forcer l'affichage immédiat
          _notifications.show(
            2,
            'TEST PROGRAMMÉ',
            'Notification programmée dans $seconds secondes',
            details,
          );
          // print('🔔 [Test] ✅ Notification forcée via Timer');
        }
      });

      // print(
      //   '✅ Notification programmée dans $seconds secondes (avec Timer de secours)',
      // );
    } catch (e, stackTrace) {
      print('❌ Erreur programmation: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  /// Programmer toutes les notifications de collecte
  static Future<void> scheduleAll() async {
    // Éviter les appels multiples simultanés
    if (_scheduling) {
      print('⚠️ scheduleAll() déjà en cours, ignoré');
      return;
    }
    _scheduling = true;
    try {
      // Annuler toutes les notifications et timers existants
      await _notifications.cancelAll();
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();

      // Annuler toutes les alarmes Android Alarm Manager Plus existantes
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys =
            prefs.getKeys().where((k) => k.startsWith('alarm_')).toList();
        for (final key in keys) {
          try {
            final alarmIdStr = key.replaceFirst('alarm_', '');
            final alarmId = int.tryParse(alarmIdStr);
            if (alarmId != null) {
              await AndroidAlarmManager.cancel(alarmId);
            }
          } catch (e) {
            // Ignorer les erreurs d'annulation
          }
        }
        // Nettoyer les clés SharedPreferences des alarmes
        for (final key in keys) {
          await prefs.remove(key);
        }
      } catch (e) {
        print('⚠️ Erreur annulation alarmes Android: $e');
      }

      // Annuler toutes les tâches WorkManager existantes
      try {
        await Workmanager().cancelAll();
      } catch (e) {
        print('⚠️ Erreur annulation tâches WorkManager: $e');
      }

      // Nettoyer toutes les notifications sauvegardées dans SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys =
            prefs
                .getKeys()
                .where(
                  (k) =>
                      k.startsWith('scheduled_notif_') ||
                      k.startsWith('notif_displayed_'),
                )
                .toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      } catch (e) {
        print('⚠️ Erreur nettoyage SharedPreferences: $e');
      }

      // Récupérer les collectes
      final collections = await CollectionService.getAllCollections();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filtrer les collectes futures (30 prochains jours)
      final futures =
          collections.where((event) {
            final eventDate = DateTime(
              event.date.toLocal().year,
              event.date.toLocal().month,
              event.date.toLocal().day,
            );
            final limit = today.add(const Duration(days: 30));
            return eventDate.isAfter(today) &&
                (eventDate.isBefore(limit) ||
                    eventDate.isAtSameMomentAs(limit));
          }).toList();

      // print('📅 ${futures.length} collectes futures trouvées');

      // Programmer chaque notification avec Timer de secours
      int count = 0;
      for (final collection in futures) {
        final collectionDate = DateTime(
          collection.date.toLocal().year,
          collection.date.toLocal().month,
          collection.date.toLocal().day,
        );

        // Notification = veille à l'heure configurée
        final notificationDate = collectionDate.subtract(
          const Duration(days: 1),
        );
        final scheduled = DateTime(
          notificationDate.year,
          notificationDate.month,
          notificationDate.day,
          notificationHour,
          notificationMinute,
        );

        // Si la date est passée, ignorer
        if (scheduled.isBefore(now)) continue;

        // Si c'est aujourd'hui et l'heure est passée, programmer pour demain
        final finalDate =
            (notificationDate.year == now.year &&
                    notificationDate.month == now.month &&
                    notificationDate.day == now.day &&
                    (now.hour > notificationHour ||
                        (now.hour == notificationHour &&
                            now.minute >= notificationMinute)))
                ? DateTime(
                  now.year,
                  now.month,
                  now.day + 1,
                  notificationHour,
                  notificationMinute,
                )
                : scheduled;

        const android = AndroidNotificationDetails(
          'notifications',
          'Notifications',
          importance: Importance.max,
          priority: Priority.max,
          icon: 'ic_notification_recycling',
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

        const ios = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const details = NotificationDetails(android: android, iOS: ios);

        // Programmer avec zonedSchedule
        final tzDate = tz.TZDateTime(
          tz.local,
          finalDate.year,
          finalDate.month,
          finalDate.day,
          finalDate.hour,
          finalDate.minute,
        );

        await _notifications.zonedSchedule(
          collection.hashCode,
          '🗑️ ${collection.type.name} demain !',
          'N\'oubliez pas de sortir vos poubelles demain matin',
          tzDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        // TIMER DE SECOURS pour cette notification (si app ouverte)
        final delay = finalDate.difference(now);
        if (delay.inSeconds > 0) {
          final timer = Timer(delay, () {
            // Forcer l'affichage au moment prévu
            _notifications.show(
              collection.hashCode,
              '🗑️ ${collection.type.name} demain !',
              'N\'oubliez pas de sortir vos poubelles demain matin',
              details,
            );
            _activeTimers.remove(collection.hashCode);
            // print('🔔 Notification ${collection.type.name} forcée via Timer');
          });
          _activeTimers[collection.hashCode] = timer;
        }

        // Sauvegarder dans SharedPreferences pour WorkManager
        await _saveScheduledNotification(
          collection.hashCode,
          collection.type.name,
          finalDate.millisecondsSinceEpoch,
        );

        // Programmer une alarme Android Alarm Manager Plus (plus fiable)
        try {
          final delay = finalDate.difference(now);
          if (delay.inSeconds > 0 && delay.inDays < 30) {
            // Programmer une alarme exacte avec Android Alarm Manager Plus
            final alarmId = collection.hashCode;
            final scheduledTime =
                DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds;

            await AndroidAlarmManager.oneShot(
              delay,
              alarmId,
              showNotificationAlarm,
              exact: true,
              wakeup: true,
              alarmClock: true,
              allowWhileIdle: true,
              rescheduleOnReboot: true,
            );

            // Sauvegarder les données de l'alarme
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'alarm_$alarmId',
              jsonEncode({
                'id': alarmId,
                'type': collection.type.name,
                'scheduledTime': scheduledTime,
              }),
            );

            // print(
            //   '✅ Alarme Android programmée pour ${collection.type.name} dans ${delay.inHours}h${delay.inMinutes.remainder(60)}min',
            // );
          }
        } catch (e) {
          print('⚠️ Erreur programmation alarme Android: $e');
        }

        // Programmer une tâche WorkManager unique pour cette notification (secours)
        try {
          final delay = finalDate.difference(now);
          if (delay.inSeconds > 0 && delay.inDays < 30) {
            // Programmer une tâche unique pour cette notification exacte
            await Workmanager().registerOneOffTask(
              'notif-${collection.hashCode}',
              'checkNotifications',
              initialDelay: delay,
              constraints: Constraints(
                networkType: NetworkType.notRequired,
                requiresBatteryNotLow: false,
                requiresCharging: false,
                requiresDeviceIdle: false,
                requiresStorageNotLow: false,
              ),
              inputData: {
                'notificationId': collection.hashCode,
                'type': collection.type.name,
              },
            );
            // print(
            //   '✅ Tâche WorkManager unique programmée pour ${collection.type.name} dans ${delay.inHours}h${delay.inMinutes.remainder(60)}min',
            // );
          }
        } catch (e) {
          print('⚠️ Erreur programmation tâche WorkManager: $e');
        }

        count++;
      }

      // print('✅ $count notifications programmées (avec Timers + WorkManager)');
      // print(
      //   '📝 ${count} notifications sauvegardées dans SharedPreferences pour WorkManager',
      // );
    } catch (e) {
      print('❌ Erreur programmation collectes: $e');
    } finally {
      _scheduling = false;
    }
  }

  /// Test manuel : Forcer la vérification des notifications (pour debug)
  static Future<void> testWorkManagerCheck() async {
    // print('🔔 [Test] Vérification manuelle des notifications...');
    await checkAndShowPendingNotifications();
  }

  /// Afficher directement une notification (appelé par WorkManager)
  @pragma('vm:entry-point')
  static Future<void> showNotificationDirectly(int id, String typeName) async {
    try {
      // Éviter les doublons : vérifier si cette notification a déjà été affichée récemment
      // (dans les 5 dernières minutes)
      final now = DateTime.now();
      final key = 'notif_displayed_$id';
      final prefs = await SharedPreferences.getInstance();
      final lastDisplayedStr = prefs.getString(key);

      if (lastDisplayedStr != null) {
        final lastDisplayed = DateTime.parse(lastDisplayedStr);
        final diff = now.difference(lastDisplayed);
        if (diff.inMinutes < 5) {
          // print('🔔 [WorkManager] Notification $typeName déjà affichée il y a ${diff.inMinutes}min, ignorée');
          return;
        }
      }

      // Marquer comme affichée
      await prefs.setString(key, now.toIso8601String());

      // print('🔔 [WorkManager] Affichage direct notification $typeName');

      // Initialiser timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Indian/Reunion'));

      // Initialiser les notifications
      const androidInit = AndroidInitializationSettings(
        'ic_notification_recycling',
      );
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.initialize(settings);

      // Créer le canal
      const channel = AndroidNotificationChannel(
        'notifications',
        'Notifications',
        description: 'Notifications de l\'application',
        importance: Importance.max,
      );

      final androidPlugin =
          notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      const androidDetails = AndroidNotificationDetails(
        'notifications',
        'Notifications',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_notification_recycling',
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: ios);

      await notifications.show(
        id,
        '🗑️ $typeName demain !',
        'N\'oubliez pas de sortir vos poubelles demain matin',
        details,
      );

      // Supprimer de SharedPreferences
      final prefsRemove = await SharedPreferences.getInstance();
      await prefsRemove.remove('scheduled_notif_$id');

      // print('🔔 [WorkManager] ✅ Notification $typeName affichée directement');
    } catch (e, stackTrace) {
      print('❌ [WorkManager] Erreur affichage direct: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  /// Sauvegarder une notification programmée pour WorkManager
  static Future<void> _saveScheduledNotification(
    int id,
    String typeName,
    int timestampMs,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'scheduled_notif_$id';
      await prefs.setString(
        key,
        jsonEncode({'id': id, 'type': typeName, 'timestamp': timestampMs}),
      );
    } catch (e) {
      print('❌ Erreur sauvegarde notification: $e');
    }
  }

  /// Vérifier et afficher les notifications manquantes (appelé par WorkManager)
  @pragma('vm:entry-point')
  static Future<void> checkAndShowPendingNotifications() async {
    try {
      // print('🔔 [WorkManager] ⏰ Début vérification des notifications...');
      // print('🔔 [WorkManager] Heure actuelle: ${DateTime.now()}');

      // Initialiser timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Indian/Reunion'));

      // Initialiser les notifications
      const android = AndroidInitializationSettings(
        'ic_notification_recycling',
      );
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.initialize(settings);

      // Créer le canal
      const channel = AndroidNotificationChannel(
        'notifications',
        'Notifications',
        description: 'Notifications de l\'application',
        importance: Importance.max,
      );

      final androidPlugin =
          notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      // Lire toutes les notifications programmées
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs
              .getKeys()
              .where((k) => k.startsWith('scheduled_notif_'))
              .toList();
      final now = DateTime.now();
      int displayed = 0;

      // print(
      //   '🔔 [WorkManager] ${keys.length} notification(s) trouvée(s) dans SharedPreferences',
      // );

      for (final key in keys) {
        try {
          final dataStr = prefs.getString(key);
          if (dataStr == null) {
            // print('🔔 [WorkManager] ⚠️ Clé $key sans données');
            continue;
          }

          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final timestamp = data['timestamp'] as int;
          final scheduledDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final id = data['id'] as int;
          final typeName = data['type'] as String;

          // print(
          //   '🔔 [WorkManager] Notification $typeName - Programmée: $scheduledDate - Maintenant: $now',
          // );

          // Si l'heure est passée (avec marge de 1 minute), afficher la notification
          if (now.isAfter(scheduledDate.subtract(const Duration(minutes: 1)))) {
            // Éviter les doublons : vérifier si cette notification a déjà été affichée récemment
            final keyCheck = 'notif_displayed_$id';
            final lastDisplayedStr = prefs.getString(keyCheck);

            if (lastDisplayedStr != null) {
              final lastDisplayed = DateTime.parse(lastDisplayedStr);
              final diffDisplayed = now.difference(lastDisplayed);
              if (diffDisplayed.inMinutes < 5) {
                // print('🔔 [WorkManager] Notification $typeName déjà affichée il y a ${diffDisplayed.inMinutes}min, ignorée');
                // Supprimer quand même de SharedPreferences
                await prefs.remove(key);
                continue;
              }
            }

            // Marquer comme affichée
            await prefs.setString(keyCheck, now.toIso8601String());

            // print('🔔 [WorkManager] ✅ Affichage de la notification $typeName');
            const android = AndroidNotificationDetails(
              'notifications',
              'Notifications',
              importance: Importance.max,
              priority: Priority.max,
              icon: 'ic_notification_recycling',
              showWhen: true,
              enableVibration: true,
              playSound: true,
            );
            const ios = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            );
            const details = NotificationDetails(android: android, iOS: ios);

            await notifications.show(
              id,
              '🗑️ $typeName demain !',
              'N\'oubliez pas de sortir vos poubelles demain matin',
              details,
            );

            // Supprimer de SharedPreferences
            await prefs.remove(key);
            displayed++;
            // print(
            //   '🔔 [WorkManager] ✅ Notification $typeName affichée et supprimée',
            // );
          } else {
            final diff = scheduledDate.difference(now);
            // print(
            //   '🔔 [WorkManager] ⏳ Notification $typeName pas encore due (dans ${diff.inMinutes} minutes)',
            // );
          }
        } catch (e) {
          print('❌ [WorkManager] Erreur traitement notification $key: $e');
        }
      }

      // print(
      //   '🔔 [WorkManager] ✅ Résumé: $displayed notification(s) affichée(s) sur ${keys.length} trouvée(s)',
      // );
    } catch (e, stackTrace) {
      print('❌ [WorkManager] Erreur: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }
}

/// Callback pour Android Alarm Manager Plus (DOIT être top-level)
@pragma('vm:entry-point')
Future<void> showNotificationAlarm(int alarmId) async {
  // print('🔔 [Alarm] Alarme déclenchée: $alarmId');
  try {
    // Lire les données de l'alarme depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final alarmDataStr = prefs.getString('alarm_$alarmId');

    if (alarmDataStr == null) {
      // print('⚠️ [Alarm] Aucune donnée trouvée pour l\'alarme $alarmId');
      return;
    }

    final alarmData = jsonDecode(alarmDataStr) as Map<String, dynamic>;
    final typeName = alarmData['type'] as String;

    // Éviter les doublons : vérifier si cette notification a déjà été affichée récemment
    final now = DateTime.now();
    final key = 'notif_displayed_$alarmId';
    final lastDisplayedStr = prefs.getString(key);

    if (lastDisplayedStr != null) {
      final lastDisplayed = DateTime.parse(lastDisplayedStr);
      final diff = now.difference(lastDisplayed);
      if (diff.inMinutes < 5) {
        // print('🔔 [Alarm] Notification $typeName déjà affichée il y a ${diff.inMinutes}min, ignorée');
        // Supprimer quand même l'alarme
        await prefs.remove('alarm_$alarmId');
        return;
      }
    }

    // print('🔔 [Alarm] Affichage notification: $typeName (ID: $alarmId)');
    await Notifications.showNotificationDirectly(alarmId, typeName);

    // Supprimer l'alarme après affichage
    await prefs.remove('alarm_$alarmId');
    // print('🔔 [Alarm] ✅ Notification $typeName affichée et alarme supprimée');
  } catch (e, stackTrace) {
    print('❌ [Alarm] Erreur: $e');
    print('❌ Stack trace: $stackTrace');
  }
}

/// Callback pour WorkManager (DOIT être top-level)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // print('🔔 [WorkManager] Tâche exécutée: $task');
    // print('🔔 [WorkManager] Données: $inputData');

    if (task == 'checkNotifications') {
      // Si on a des données spécifiques (tâche unique), afficher directement
      if (inputData != null &&
          inputData.containsKey('notificationId') &&
          inputData.containsKey('type')) {
        final notificationId = inputData['notificationId'] as int;
        final typeName = inputData['type'] as String;
        // print(
        //   '🔔 [WorkManager] Affichage notification unique: $typeName (ID: $notificationId)',
        // );
        await Notifications.showNotificationDirectly(notificationId, typeName);
      } else {
        // Sinon, vérifier toutes les notifications (tâche périodique)
        await Notifications.checkAndShowPendingNotifications();
      }
    }
    return Future.value(true);
  });
}
