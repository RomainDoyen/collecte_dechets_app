import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  static const int defaultHour = 18;
  static const int defaultMinute = 0;
  static const String hourKey = 'reminder_hour';
  static const String minuteKey = 'reminder_minute';

  final int hour;
  final int minute;

  const ReminderSettings({
    this.hour = defaultHour,
    this.minute = defaultMinute,
  });

  String get formatted {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      hour: prefs.getInt(hourKey) ?? defaultHour,
      minute: prefs.getInt(minuteKey) ?? defaultMinute,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(hourKey, hour);
    await prefs.setInt(minuteKey, minute);
  }

  DateTime scheduledAt(DateTime collectionDate) {
    final local = collectionDate.toLocal();
    final collectionDay = DateTime(local.year, local.month, local.day);
    final eve = collectionDay.subtract(const Duration(days: 1));
    return DateTime(eve.year, eve.month, eve.day, hour, minute);
  }
}
