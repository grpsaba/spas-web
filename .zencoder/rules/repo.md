# SPAS Web - Projet Flutter

## Description
Application web Flutter pour la gestion SPAS (Sistema de Protección y Asistencia Social) - système de sécurité et surveillance avec fonctionnalités d'alerte SOS.

## Structure du projet

### Services principaux
- **Authentication** : Gestion de l'authentification Firebase
- **Player** : Gestion audio/SOS et text-to-speech
- **Site, Agent, Supervisor** : Gestion des entités métier
- **Pointing*** : Services de pointage (site, agent, tools, zone)

### Modules fonctionnels
- **Administration** : Interface d'admin avec widgets SOS et statuts
- **Accueil** : Dashboard avec cartes et statistiques
- **Agent/Site/Supervisor** : Gestion CRUD des entités
- **Pointage** : Système de pointage multi-entités
- **Notes** : Gestion des rapports et notes
- **Tools** : Gestion des outils et équipements

### Fonctionnalités clés
1. **Système SOS** : Alerte sonore automatique en cas de problème
2. **Cartographie** : Intégration Google Maps pour géolocalisation
3. **Pointage temps réel** : Suivi en temps réel des agents/sites
4. **Notifications** : Push notifications Firebase
5. **Rapports PDF** : Génération automatique de rapports

## Technologies utilisées
- **Frontend** : Flutter Web
- **Backend** : Firebase (Firestore, Auth, Storage, Messaging)
- **Audio** : audioplayers, text_to_speech
- **Maps** : google_maps_flutter
- **PDF** : Printing, Excel export
- **UI** : Bootstrap5, Material Design

## Architecture
- **Services** : Couche de services pour API calls
- **Models** : Modèles de données (Site, Agent, Supervisor, etc.)
- **Providers** : State management avec Provider
- **Widgets** : Composants réutilisables

## Problèmes identifiés et corrigés
### Système SOS
- **Problème** : Chevauchement des sons SOS due aux rebuilds multiples
- **Solution** : Implémentation singleton + debouncing + contrôle d'état
- **Améliorations** : Timer de debounce, limite temps entre SOS, contrôle états async