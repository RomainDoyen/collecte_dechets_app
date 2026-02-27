import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'collections';

  static Future<void> clearCollection() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Erreur lors du vidage: $e');
    }
  }
}
