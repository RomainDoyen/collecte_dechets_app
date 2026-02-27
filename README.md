# Application Consultation Collecte de Déchets - Sainte Rose

Cette application Flutter permet de consulter le calendrier de collecte des déchets pour la zone SAINTE-ROSE SR01 avec des notifications push fiables via Firebase Cloud Messaging.

## Fonctionnalités

- 📅 **Calendrier interactif** avec affichage des collectes
- 🔔 **Prochaine collecte** mise en évidence
- 🎨 **Légende colorée** selon les types de déchets
- 📱 **Interface responsive** et moderne
- 🔔 **Notifications push** via Firebase Cloud Messaging (FCM)
- ☁️ **Synchronisation Firestore** pour les données
- 🔄 **Notifications automatiques** programmées via cron

## Types de collectes

- 🗑️ **Ordures Ménagères** (Gris) - Mardi
- ♻️ **Collecte Sélective** (Jaune) - 1 lundi sur 2
- 🍃 **Déchets Verts** (Vert) - 1 collecte par mois
- 🛋️ **Encombrants** (Rouge) - 1 collecte tous les 2 mois
- 🚲 **Déchets Métalliques** (Bleu) - Sur rendez-vous uniquement

## Configuration Firebase

### 1. Créer un projet Firebase
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Créer un nouveau projet
3. Activer Firestore Database
4. Activer Cloud Messaging

### 2. Configuration Android
1. Ajouter une app Android dans Firebase
2. Télécharger `google-services.json`
3. Placer le fichier dans `android/app/`
4. Mettre à jour `firebase_options.dart` avec vos clés

### 3. Configuration iOS
1. Ajouter une app iOS dans Firebase
2. Télécharger `GoogleService-Info.plist`
3. Placer le fichier dans `ios/Runner/`
4. Mettre à jour `firebase_options.dart` avec vos clés

## Données

Les données de collecte sont synchronisées avec Firestore et initialisées depuis le fichier JSON local (`assets/collections_data.json`).

### Avantages de Firestore :
- 🔄 **Synchronisation** : Données à jour en temps réel
- 🔔 **Notifications push** : Fiables même si l'app est fermée
- ☁️ **Cloud** : Accessible depuis n'importe où
- 📊 **Analytics** : Suivi des utilisateurs

## Installation

1. Cloner le projet
2. Configurer Firebase (voir section Configuration Firebase)
3. Installer les dépendances : `flutter pub get`
4. Lancer l'application : `flutter run`

## Notifications FCM

### Test des notifications
L'application inclut un bouton de test FCM (☁️) dans l'AppBar qui :
- Programme une notification de test pour 18h55
- Affiche le token FCM dans les logs
- S'abonne au topic de test

### Configuration automatique
Les notifications sont programmées automatiquement au démarrage de l'application pour les collectes du lendemain à 18h15.

## Structure du projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── firebase_options.dart     # Configuration Firebase
├── models/
│   └── collection_type.dart  # Modèles de données
├── services/
│   ├── collection_service.dart # Service de gestion des données Firestore
│   ├── notification_service.dart # Service de notifications locales
│   ├── fcm_service.dart     # Service Firebase Cloud Messaging
│   └── firestore_initializer.dart # Initialisation Firestore
└── screens/
    ├── calendar_screen.dart  # Écran principal avec calendrier
    └── splash_screen.dart    # Écran de démarrage

assets/
├── collections_data.json     # Données de collecte (JSON - initialisation)
└── icon/
    └── recycling-bin.png     # Icône de l'application

# Configuration Firebase
├── firebase.json            # Configuration Firebase
└── firebase_options.dart    # Options Firebase (à configurer)
```

## Développement

### Modifier les données de collecte :
1. Éditer le fichier `assets/collections_data.json`
2. Redémarrer l'application (les données seront synchronisées avec Firestore)

### Tester les notifications :
1. Configurer Firebase avec vos clés
2. Lancer l'app et cliquer sur le bouton ☁️ (FCM)
3. Vérifier les logs pour le token FCM
4. La notification de test apparaîtra à 18h55

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

## Prochaines étapes

1. **Configurer Firebase** avec vos vraies clés dans `firebase_options.dart`
2. **Tester les notifications FCM** avec le bouton ☁️ dans l'app
3. **Vérifier la collecte de test** pour demain (24/09/2025)
4. **La notification apparaîtra** à 18h55 aujourd'hui

## Licence

Application développée pour un usage personnel.