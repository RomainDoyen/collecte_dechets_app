import 'package:flutter/material.dart';

enum DropOffCategory {
  piles('Piles', Icons.battery_std, Color(0xFFF9A825)),
  medicaments('Médicaments', Icons.medication, Color(0xFFE53935)),
  vetements('Vêtements', Icons.checkroom, Color(0xFF8E24AA)),
  electronique('Électronique', Icons.devices, Color(0xFF1E88E5)),
  autres('Autres', Icons.delete_outline, Color(0xFF546E7A));

  const DropOffCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static const pilesKeys = {
    'batteries_et_piles_portables',
    'batterie_de_voitures_pour_demarrage',
    'batteries_de_mtl',
  };

  static const medicamentsKeys = {
    'medicaments',
    'dasri',
  };

  static const vetementsKeys = {
    'vetement',
    'chaussures',
    'linge_de_maison',
    'maroquinerie',
    'decorations_textiles_elements_d_ameublement',
  };

  static const electroniqueKeys = {
    'petit_electromenager',
    'gros_electromenager_hors_refrigerant',
    'gros_electromenager_refrigerant',
    'ecran',
    'smartphone_tablette_et_console',
    'materiel_informatique',
    'materiel_hifi_et_video',
    'materiel_photo_et_cinema',
    'autre_equipement_electronique',
    'abj_electrique',
    'instrument_musique_electrique',
    'jels_mobilite_electrique',
    'luminaire',
    'ampoule',
  };

  static final knownKeys = {
    ...pilesKeys,
    ...medicamentsKeys,
    ...vetementsKeys,
    ...electroniqueKeys,
  };

  Set<String> get keys {
    switch (this) {
      case DropOffCategory.piles:
        return pilesKeys;
      case DropOffCategory.medicaments:
        return medicamentsKeys;
      case DropOffCategory.vetements:
        return vetementsKeys;
      case DropOffCategory.electronique:
        return electroniqueKeys;
      case DropOffCategory.autres:
        return const {};
    }
  }
}

class DropOffPoint {
  const DropOffPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.wasteKeys,
    this.phone,
    this.hours,
    this.accessNotes,
    this.actorType,
    this.source,
    this.website,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final Set<String> wasteKeys;
  final String? phone;
  final String? hours;
  final String? accessNotes;
  final String? actorType;
  final String? source;
  final String? website;

  String get displayName => name;

  String get fullAddress {
    final parts = [
      if (address.isNotEmpty) address,
      if (postalCode.isNotEmpty || city.isNotEmpty)
        '${postalCode.isNotEmpty ? '$postalCode ' : ''}$city'.trim(),
    ];
    return parts.join(', ');
  }

  List<String> get wasteLabels => wasteKeys
      .map(_labelForKey)
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  bool matches(DropOffCategory category) {
    if (category == DropOffCategory.autres) {
      return wasteKeys.any((key) => !DropOffCategory.knownKeys.contains(key));
    }
    return wasteKeys.any(category.keys.contains);
  }

  DropOffCategory primaryCategory() {
    for (final category in DropOffCategory.values) {
      if (category == DropOffCategory.autres) continue;
      if (matches(category)) return category;
    }
    return DropOffCategory.autres;
  }

  Color markerColor() => primaryCategory().color;

  Map<String, dynamic> toJson() => {
        'identifiant': id,
        'nom': name,
        'adresse': address,
        'ville': city,
        'code_postal': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'telephone': phone,
        'horaires_description': hours,
        'consignes_dacces': accessNotes,
        'type_dacteur': actorType,
        'trier': wasteKeys.join(' | '),
        'paternite': source,
        'site_web': website,
      };

  static DropOffPoint? tryParse(Map<String, dynamic> map) {
    final lieu = (map['lieu_prestation'] as String?) ?? 'SUR_PLACE';
    if (lieu == 'A_DOMICILE') return null;

    final lat = _readDouble(map['latitude']);
    final lon = _readDouble(map['longitude']);
    if (lat == null || lon == null) return null;

    final wasteKeys = _splitKeys(map['trier'] as String?);
    if (wasteKeys.isEmpty) return null;

    final commercial = (map['nom_commercial'] as String?)?.trim() ?? '';
    final legal = (map['nom'] as String?)?.trim() ?? '';
    final name = commercial.isNotEmpty ? commercial : legal;
    if (name.isEmpty) return null;

    final hours = _firstNonEmpty([
      map['horaires_description'] as String?,
      map['horaires_osm'] as String?,
    ]);

    return DropOffPoint(
      id: (map['identifiant'] as String?) ??
          (map['_id'] as String?) ??
          '$lat,$lon,$name',
      name: name,
      address: (map['adresse'] as String?)?.trim() ?? '',
      city: (map['ville'] as String?)?.trim() ?? '',
      postalCode: (map['code_postal'] as String?)?.trim() ?? '',
      latitude: lat,
      longitude: lon,
      wasteKeys: wasteKeys,
      phone: _firstNonEmpty([map['telephone'] as String?]),
      hours: hours,
      accessNotes: _firstNonEmpty([map['consignes_dacces'] as String?]),
      actorType: map['type_dacteur'] as String?,
      source: map['paternite'] as String?,
      website: _firstNonEmpty([map['site_web'] as String?]),
    );
  }

  static Set<String> _splitKeys(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    return raw
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet();
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String _labelForKey(String key) {
    const labels = {
      'batteries_et_piles_portables': 'Piles et petites batteries',
      'batterie_de_voitures_pour_demarrage': 'Batteries de voiture',
      'medicaments': 'Médicaments',
      'dasri': 'Déchets de soins',
      'vetement': 'Vêtements',
      'chaussures': 'Chaussures',
      'linge_de_maison': 'Linge de maison',
      'petit_electromenager': 'Petit électroménager',
      'gros_electromenager_hors_refrigerant': 'Gros électroménager',
      'gros_electromenager_refrigerant': 'Réfrigérateur / congélateur',
      'ecran': 'Écrans',
      'smartphone_tablette_et_console': 'Smartphones, tablettes, consoles',
      'materiel_informatique': 'Informatique',
      'ampoule': 'Ampoules',
      'luminaire': 'Luminaires',
      'dechets_verts': 'Déchets verts',
      'encombrants_menagers_divers': 'Encombrants',
      'huiles_lubrifiantes': 'Huiles de vidange',
      'huile_alimentaire': 'Huiles alimentaires',
      'meuble': 'Meubles',
      'jouet': 'Jouets',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }
}
