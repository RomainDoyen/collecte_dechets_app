import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collecte_dechets_app/services/reminder_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('par défaut l\'heure de rappel est 18:00', () async {
    final settings = await ReminderSettings.load();

    expect(settings.hour, 18);
    expect(settings.minute, 0);
    expect(settings.formatted, '18:00');
  });

  test('charge l\'heure enregistrée', () async {
    SharedPreferences.setMockInitialValues({
      ReminderSettings.hourKey: 17,
      ReminderSettings.minuteKey: 30,
    });

    final settings = await ReminderSettings.load();

    expect(settings.hour, 17);
    expect(settings.minute, 30);
    expect(settings.formatted, '17:30');
  });

  test('sauvegarde puis recharge l\'heure choisie', () async {
    await const ReminderSettings(hour: 17, minute: 0).save();

    final settings = await ReminderSettings.load();

    expect(settings.hour, 17);
    expect(settings.minute, 0);
    expect(settings.formatted, '17:00');
  });

  test('programme le rappel la veille à l\'heure choisie', () {
    const settings = ReminderSettings(hour: 17, minute: 0);
    final collectionDate = DateTime(2026, 9, 19);

    final scheduled = settings.scheduledAt(collectionDate);

    expect(scheduled, DateTime(2026, 9, 18, 17, 0));
  });
}
