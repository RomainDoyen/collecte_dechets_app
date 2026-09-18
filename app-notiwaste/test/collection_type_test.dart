import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collecte_dechets_app/models/collection_type.dart';

void main() {
  test('chaque type de collecte a une couleur de tag distincte', () {
    expect(
      CollectionType.orduresMenageres.tagColor,
      const Color(0xFF757575),
    );
    expect(
      CollectionType.collecteSelective.tagColor,
      const Color(0xFFF9A825),
    );
    expect(
      CollectionType.dechetsVerts.tagColor,
      const Color(0xFF43A047),
    );
    expect(
      CollectionType.encombrants.tagColor,
      const Color(0xFFE53935),
    );
    expect(
      CollectionType.dechetsMetalliques.tagColor,
      const Color(0xFF1E88E5),
    );
  });

  test('fromName retrouve le type à partir du nom affiché', () {
    expect(
      CollectionType.fromName('Poubelle jaune'),
      CollectionType.collecteSelective,
    );
    expect(
      CollectionType.fromName('Poubelle grise'),
      CollectionType.orduresMenageres,
    );
  });
}
