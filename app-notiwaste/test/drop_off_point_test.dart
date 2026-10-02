import 'package:flutter_test/flutter_test.dart';
import 'package:collecte_dechets_app/models/drop_off_point.dart';

void main() {
  Map<String, dynamic> sample({
    String? nom,
    String? lieu,
    String? trier,
    Object? lat,
    Object? lon,
  }) {
    return {
      'identifiant': 'id-1',
      'nom': nom ?? 'DÉCHÈTERIE DE SAINTE ROSE',
      'nom_commercial': '',
      'adresse': 'RN2',
      'ville': 'Sainte Rose',
      'code_postal': '97439',
      'latitude': lat ?? -21.14,
      'longitude': lon ?? 55.81,
      'telephone': '0262475657',
      'horaires_description': 'lundi: 08:00 - 12:00',
      'consignes_dacces': 'Trier avant dépôt',
      'type_dacteur': 'decheterie',
      'lieu_prestation': lieu ?? 'SUR_PLACE',
      'trier': trier ??
          'batteries_et_piles_portables | medicaments | vetement | petit_electromenager | huiles_lubrifiantes',
      'paternite': 'Que faire de mes objets et déchets | ADEME',
    };
  }

  test('ignore les acteurs uniquement à domicile', () {
    expect(DropOffPoint.tryParse(sample(lieu: 'A_DOMICILE')), isNull);
  });

  test('ignore les lieux sans coordonnées ou sans déchets à trier', () {
    final withoutCoords = sample()
      ..['latitude'] = null
      ..['longitude'] = null;
    expect(DropOffPoint.tryParse(withoutCoords), isNull);
    expect(DropOffPoint.tryParse(sample(trier: '')), isNull);
  });

  test('classe piles, médicaments, vêtements, électronique et autres', () {
    final point = DropOffPoint.tryParse(sample())!;
    expect(point.matches(DropOffCategory.piles), isTrue);
    expect(point.matches(DropOffCategory.medicaments), isTrue);
    expect(point.matches(DropOffCategory.vetements), isTrue);
    expect(point.matches(DropOffCategory.electronique), isTrue);
    expect(point.matches(DropOffCategory.autres), isTrue);
  });

  test('une pharmacie n’apparaît que dans Médicaments', () {
    final point = DropOffPoint.tryParse(
      sample(nom: 'PHARMACIE NAVOROZALY', trier: 'dasri | medicaments'),
    )!;
    expect(point.matches(DropOffCategory.medicaments), isTrue);
    expect(point.matches(DropOffCategory.piles), isFalse);
    expect(point.matches(DropOffCategory.vetements), isFalse);
    expect(point.matches(DropOffCategory.electronique), isFalse);
    expect(point.matches(DropOffCategory.autres), isFalse);
  });

  test('préfère le nom commercial pour l’affichage', () {
    final point = DropOffPoint.tryParse({
      ...sample(),
      'nom': 'Raison sociale',
      'nom_commercial': 'Le Relais',
    })!;
    expect(point.displayName, 'Le Relais');
  });
}
