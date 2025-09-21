enum CollectionType {
  orduresMenageres('Ordures Ménagères', 'Gris', '🗑️'),
  collecteSelective('Collecte Sélective', 'Jaune', '♻️'),
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
    return CollectionEvent(
      date: DateTime.parse(map['date']),
      type: CollectionType.values.firstWhere((e) => e.name == map['type']),
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
