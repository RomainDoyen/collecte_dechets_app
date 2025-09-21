# Application Consultation Collecte de Déchets - Sainte Rose

Cette application Flutter permet de consulter le calendrier de collecte des déchets pour la zone SAINTE-ROSE SR01.

## Fonctionnalités

- 📅 **Calendrier interactif** avec affichage des collectes
- 🔔 **Prochaine collecte** mise en évidence
- 🎨 **Légende colorée** selon les types de déchets
- 📱 **Interface responsive** et moderne
- 🔔 **Notifications** pour les prochaines collectes
- 📊 **Données locales** (pas de connexion internet requise)

## Types de collectes

- 🗑️ **Ordures Ménagères** (Gris) - Mardi
- ♻️ **Collecte Sélective** (Jaune) - 1 lundi sur 2
- 🍃 **Déchets Verts** (Vert) - 1 collecte par mois
- 🛋️ **Encombrants** (Rouge) - 1 collecte tous les 2 mois
- 🚲 **Déchets Métalliques** (Bleu) - Sur rendez-vous uniquement

## Données

Les données de collecte sont stockées localement dans un fichier JSON (`assets/collections_data.json`) et couvrent la période juillet-décembre 2025 pour la zone SR01 (Sainte-Rose).

### Avantages des données locales :
- ⚡ **Performance** : Chargement instantané
- 🔒 **Fiabilité** : Fonctionne hors ligne
- 💰 **Économie** : Pas de coûts de serveur
- 🛠️ **Simplicité** : Pas de configuration complexe

## Installation

1. Cloner le projet
2. Installer les dépendances : `flutter pub get`
3. Lancer l'application : `flutter run`

## Structure du projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/
│   └── collection_type.dart  # Modèles de données
├── services/
│   ├── collection_service.dart # Service de gestion des données JSON
│   └── notification_service.dart # Service de notifications
└── screens/
    ├── calendar_screen.dart  # Écran principal avec calendrier
    └── splash_screen.dart    # Écran de démarrage

assets/
├── collections_data.json     # Données de collecte (JSON)
└── icon/
    └── recycling-bin.png     # Icône de l'application
```

## Développement

Pour modifier les données de collecte :
1. Éditer le fichier `assets/collections_data.json`
2. Redémarrer l'application

### Format des données JSON :
```json
{
  "date": "2025-07-02T00:00:00.000Z",
  "type": "Ordures Ménagères",
  "notes": null,
  "isHoliday": false,
  "isCatchUp": false
}
```

## Licence

Application développée pour un usage personnel.