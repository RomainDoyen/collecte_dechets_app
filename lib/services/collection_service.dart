import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/collection_type.dart';

class CollectionService {
  static List<CollectionEvent>? _cachedCollections;

  // Charger les données depuis le fichier JSON
  static Future<List<CollectionEvent>> _loadCollectionsFromJson() async {
    if (_cachedCollections != null) {
      return _cachedCollections!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/collections_data.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedCollections =
          jsonList
              .map(
                (json) => CollectionEvent.fromMap(json as Map<String, dynamic>),
              )
              .toList();

      return _cachedCollections!;
    } catch (e) {
      // En cas d'erreur, retourner une liste vide
      return [];
    }
  }

  // Initialiser les données (plus nécessaire avec JSON local)
  static Future<void> initializeData() async {
    // Les données sont maintenant chargées depuis le fichier JSON
    // Cette méthode est conservée pour la compatibilité mais ne fait rien
    await _loadCollectionsFromJson();
  }

  // Récupérer toutes les collectes
  static Future<List<CollectionEvent>> getAllCollections() async {
    return await _loadCollectionsFromJson();
  }

  // Récupérer les collectes pour un mois donné
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

  // Récupérer la prochaine collecte
  static Future<CollectionEvent?> getNextCollection() async {
    final allCollections = await getAllCollections();
    final now = DateTime.now();

    final upcomingCollections =
        allCollections.where((event) => event.date.isAfter(now)).toList();

    if (upcomingCollections.isEmpty) return null;

    upcomingCollections.sort((a, b) => a.date.compareTo(b.date));
    return upcomingCollections.first;
  }

  // Récupérer les collectes du jour
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
