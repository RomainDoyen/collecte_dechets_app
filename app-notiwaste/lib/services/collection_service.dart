import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_type.dart';

class CollectionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'collections';
  static List<CollectionEvent>? _cachedCollections;

  static void clearCache() {
    _cachedCollections = null;
  }

  static Future<List<CollectionEvent>> getAllCollections() async {
    if (_cachedCollections != null) {
      return _cachedCollections!;
    }

    try {
      final snapshot = await _firestore.collection(_collectionName).get();

      _cachedCollections = snapshot.docs
          .map((doc) => CollectionEvent.fromMap(doc.data()))
          .toList();

      return _cachedCollections!;
    } catch (e) {
      print('Erreur chargement Firestore: $e');
      return [];
    }
  }

  static Future<List<CollectionEvent>> getCollectionsForMonth(
    DateTime month,
  ) async {
    final allCollections = await getAllCollections();
    return allCollections
        .where(
          (event) =>
              event.date.year == month.year && event.date.month == month.month,
        )
        .toList();
  }

  static Future<CollectionEvent?> getNextCollection() async {
    final allCollections = await getAllCollections();
    final now = DateTime.now();

    final upcomingCollections =
        allCollections.where((event) => event.date.isAfter(now)).toList();

    if (upcomingCollections.isEmpty) return null;

    upcomingCollections.sort((a, b) => a.date.compareTo(b.date));
    return upcomingCollections.first;
  }

  static Future<List<CollectionEvent>> getCollectionsForToday() async {
    final allCollections = await getAllCollections();
    final today = DateTime.now();

    return allCollections
        .where(
          (event) =>
              event.date.year == today.year &&
              event.date.month == today.month &&
              event.date.day == today.day,
        )
        .toList();
  }
}
