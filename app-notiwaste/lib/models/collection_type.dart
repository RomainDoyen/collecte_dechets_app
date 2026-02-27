enum CollectionType {
  orduresMenageres('Poubelle grise', 'Gris', '🗑️'),
  collecteSelective('Poubelle jaune', 'Jaune', '♻️'),
  dechetsVerts('Déchets Verts', 'Vert', '🍃'),
  encombrants('Encombrants', 'Rouge', '🛋️'),
  dechetsMetalliques('Déchets Métalliques', 'Bleu', '🚲');

  const CollectionType(this.name, this.color, this.icon);

  final String name;
  final String color;
  final String icon;
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
    // Mapping des noms du JSON vers les types
    final String typeName = map['type'] as String;
    CollectionType collectionType;

    switch (typeName) {
      case 'Ordures Ménagères':
        collectionType = CollectionType.orduresMenageres;
        break;
      case 'Collecte Sélective':
        collectionType = CollectionType.collecteSelective;
        break;
      case 'Déchets Verts':
      case 'Déchets Végétaux':
        collectionType = CollectionType.dechetsVerts;
        break;
      case 'Encombrants':
        collectionType = CollectionType.encombrants;
        break;
      case 'Déchets Métalliques':
        collectionType = CollectionType.dechetsMetalliques;
        break;
      // Fallback : essayer de trouver par le nom de l'enum
      default:
        collectionType = CollectionType.values.firstWhere(
          (e) => e.name == typeName,
          orElse: () => CollectionType.orduresMenageres, // Par défaut
        );
    }

    return CollectionEvent(
      date: DateTime.parse(map['date']),
      type: collectionType,
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
