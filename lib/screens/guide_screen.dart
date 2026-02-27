import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.calendar_month,
            title: 'Calendrier',
            steps: [
              'Le calendrier affiche toutes les collectes prevues avec des pastilles colorées.',
              'Chaque couleur correspond à un type de collecte (voir la légende).',
              'Appuyez sur un jour pour voir le détail des collectes prévues.',
              'Faites glisser vers la gauche ou la droite pour changer de mois.',
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.edit_calendar,
            title: 'Gestion des collectes',
            steps: [
              'Allez dans l\'onglet "Gestion" en bas de l\'écran.',
              'Sélectionnez l\'année avec les flèches, puis appuyez sur un mois.',
              'Choisissez un type de collecte dans le bandeau en haut.',
              'Appuyez sur les jours pour ajouter ou retirer une collecte.',
              'Appui long sur un jour pour voir et supprimer individuellement ses collectes.',
              'Appuyez sur "Enregistrer" pour sauvegarder vos modifications.',
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.notifications_active,
            title: 'Notifications',
            steps: [
              'Vous recevez automatiquement une notification la veille de chaque collecte.',
              'Les notifications fonctionnent même lorsque l\'application est fermée.',
              'Assurez-vous que les notifications sont autorisées dans les paramètres de votre téléphone.',
              'Pensez à désactivez l\'optimisation de batterie pour cette application.',
            ],
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> steps,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8BC34A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final types = [
      ('Poubelle grise', Colors.grey, 'Ordures ménagères'),
      ('Poubelle jaune', Colors.yellow.shade700, 'Collecte sélective (tri)'),
      ('Déchets Verts', Colors.green.shade600, 'Végétaux, tontes, branches'),
      ('Encombrants', Colors.red.shade600, 'Meubles, appareils volumineux'),
      ('Déchets Métalliques', Colors.blue.shade600, 'Ferraille, métaux'),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 12),
                Text(
                  'Types de collecte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...types.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: type.$2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            type.$3,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
