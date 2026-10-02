import 'package:flutter/material.dart';

import '../widgets/rounded_sheet_body.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentions légales'),
        centerTitle: true,
      ),
      body: RoundedSheetBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: const [
            _LegalSection(
              title: 'Éditeur',
              body:
                  'NotiWaste est une application d\'information sur les collectes '
                  'de déchets destinée aux habitants de la commune de Sainte-Rose '
                  '(La Réunion).',
            ),
            _LegalSection(
              title: 'Objet',
              body:
                  'L\'application permet de consulter le calendrier des collectes, '
                  'de recevoir un rappel la veille, de gérer les dates de collecte '
                  'et de localiser les points d\'apport du CIREST.',
            ),
            _LegalSection(
              title: 'Données personnelles',
              body:
                  'NotiWaste ne crée pas de compte utilisateur. L\'heure de rappel '
                  'est enregistrée uniquement sur l\'appareil. Les notifications '
                  'sont planifiées localement. Aucune donnée de calendrier n\'est '
                  'vendue à des tiers.',
            ),
            _LegalSection(
              title: 'Localisation',
              body:
                  'La position n\'est utilisée que si vous activez « Autour de moi », '
                  'afin de trier les lieux de dépôt les plus proches. Elle n\'est '
                  'pas transmise ni conservée en arrière-plan.',
            ),
            _LegalSection(
              title: 'Sources et hébergement',
              body:
                  'Les points de collecte proviennent de la base « Que faire de mes '
                  'objets & déchets » de l\'ADEME. Les dates de collecte sont '
                  'synchronisées via Firebase (Google). Les tuiles de carte sont '
                  'fournies par OpenStreetMap.',
            ),
            _LegalSection(
              title: 'Propriété intellectuelle',
              body:
                  'Les contenus de l\'application (textes, icônes, charte) sont '
                  'réservés. Les données ADEME et OpenStreetMap restent la '
                  'propriété de leurs auteurs, selon leurs licences respectives.',
            ),
            _LegalSection(
              title: 'Contact',
              body:
                  'Pour toute question relative à l\'application ou aux collectes, '
                  'rapprochez-vous des services de la commune de Sainte-Rose.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
