import 'package:flutter/material.dart';

enum CollectionType {
  orduresMenageres('Poubelle grise', 'Gris', Icons.delete),
  collecteSelective('Poubelle jaune', 'Jaune', Icons.recycling),
  dechetsVerts('Déchets Verts', 'Vert', Icons.grass),
  encombrants('Encombrants', 'Rouge', Icons.weekend),
  dechetsMetalliques('Déchets Métalliques', 'Bleu', Icons.pedal_bike);

  const CollectionType(this.name, this.color, this.icon);

  final String name;
  final String color;
  final IconData icon;

  Color get tagColor {
    switch (this) {
      case CollectionType.orduresMenageres:
        return const Color(0xFF757575);
      case CollectionType.collecteSelective:
        return const Color(0xFFF9A825);
      case CollectionType.dechetsVerts:
        return const Color(0xFF43A047);
      case CollectionType.encombrants:
        return const Color(0xFFE53935);
      case CollectionType.dechetsMetalliques:
        return const Color(0xFF1E88E5);
    }
  }

  static CollectionType fromName(String typeName) {
    switch (typeName) {
      case 'Ordures Ménagères':
      case 'Poubelle grise':
        return CollectionType.orduresMenageres;
      case 'Collecte Sélective':
      case 'Poubelle jaune':
        return CollectionType.collecteSelective;
      case 'Déchets Verts':
      case 'Déchets Végétaux':
        return CollectionType.dechetsVerts;
      case 'Encombrants':
        return CollectionType.encombrants;
      case 'Déchets Métalliques':
        return CollectionType.dechetsMetalliques;
      default:
        return CollectionType.values.firstWhere(
          (e) => e.name == typeName,
          orElse: () => CollectionType.orduresMenageres,
        );
    }
  }
}

class CollectionEvent {
  final DateTime date;
  final CollectionType type;
  final String? notes; // Pour les rattrapages ou notes spéciales
  final bool isHoliday;
  final bool isCatchUp; // Pour les rattrapages

  CollectionEvent({
    required this.date,
    required this.type,
    this.notes,
    this.isHoliday = false,
    this.isCatchUp = false,
  });

  factory CollectionEvent.fromMap(Map<String, dynamic> map) {
    return CollectionEvent(
      date: DateTime.parse(map['date']),
      type: CollectionType.fromName(map['type'] as String),
      notes: map['notes'],
      isHoliday: map['isHoliday'] ?? false,
      isCatchUp: map['isCatchUp'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'type': type.name,
      'notes': notes,
      'isHoliday': isHoliday,
      'isCatchUp': isCatchUp,
    };
  }
}
