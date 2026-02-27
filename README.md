<p align="center">
  <img src="documentation/assets/logo-notiwaste-master.png" alt="NotiWaste" width="180" style="background:white; border-radius:20px; padding:12px;" />
</p>

# NotiWaste

Application mobile Flutter de gestion des collectes de déchets pour la commune de Sainte-Rose (La Réunion).

## Fonctionnalités

- **Calendrier interactif** — Affichage mensuel avec pastilles colorées par type de collecte
- **Notifications automatiques** — Rappel la veille de chaque collecte (triple sécurité : zonedSchedule + AlarmManager + WorkManager)
- **Gestion des collectes** — Ajout/suppression de dates directement depuis l'app avec sauvegarde Firestore
- **Guide intégré** — Mode d'emploi accessible depuis l'application
- **Synchronisation cloud** — Données stockées dans Firebase Firestore

## Types de collectes


| Couleur | Type                | Description                   |
| ------- | ------------------- | ----------------------------- |
| Gris    | Poubelle grise      | Ordures ménagères             |
| Jaune   | Poubelle jaune      | Collecte sélective (tri)      |
| Vert    | Déchets Verts       | Végétaux, tontes, branches    |
| Rouge   | Encombrants         | Meubles, appareils volumineux |
| Bleu    | Déchets Métalliques | Ferraille, métaux             |


## Installation

```bash
# Cloner le projet
git clone https://github.com/votre-repo/collecte_dechets_app.git
cd app-notiwaste

# Installer les dépendances
flutter pub get

# Générer les icônes et le splash screen
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Lancer l'application
flutter run
```

## Configuration Firebase

1. Créer un projet sur [Firebase Console](https://console.firebase.google.com/)
2. Activer **Firestore Database** et **Cloud Messaging**
3. Ajouter une app Android, télécharger `google-services.json` et le placer dans `android/app/`
4. Mettre à jour `lib/firebase_options.dart` avec vos clés

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── firebase_options.dart        # Configuration Firebase
├── models/
│   └── collection_type.dart     # Modèle de données
├── services/
│   ├── collection_service.dart  # Chargement des données Firestore
│   ├── notifications.dart       # Système de notifications complet
│   ├── fcm_service.dart         # Firebase Cloud Messaging
│   └── firestore_initializer.dart
└── screens/
    ├── splash_screen.dart       # Écran de démarrage
    ├── home_screen.dart         # Navigation principale
    ├── calendar_screen.dart     # Calendrier des collectes
    ├── admin_screen.dart        # Gestion (grille des 12 mois)
    ├── month_editor_screen.dart # Éditeur de mois
    ├── guide_screen.dart        # Guide d'utilisation
    └── about_screen.dart        # À propos
```

## Documentation

La documentation technique complète est disponible dans le dossier `documentation/`. Ouvrez `documentation/index.html` dans un navigateur pour y accéder.

## Compilation

```bash
# APK (installation directe)
flutter build apk --release

# App Bundle (Google Play Store)
flutter build appbundle --release
```

## Licence

Application développée pour un usage personnel.