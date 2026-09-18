import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collecte_dechets_app/firebase_options.dart';

void main() {
  test('refuse une config Firebase vide (build sans .env.json)', () {
    const empty = FirebaseOptions(
      apiKey: '',
      appId: '',
      messagingSenderId: '',
      projectId: '',
    );

    expect(DefaultFirebaseOptions.isConfigured(empty), isFalse);
  });

  test('accepte une config Firebase complète', () {
    const options = FirebaseOptions(
      apiKey: 'key',
      appId: 'id',
      messagingSenderId: '1',
      projectId: 'projet',
    );

    expect(DefaultFirebaseOptions.isConfigured(options), isTrue);
  });
}
