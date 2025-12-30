# Requirements: Modernisation du système de pointage des zones

## Introduction

Moderniser le système de pointage des chefs de zone en appliquant le même design moderne et les mêmes fonctionnalités que le système de pointage des sites (superviseurs) déjà implémenté.

## Glossary

- **Zone Member (Chef de Zone)**: Responsable d'une zone géographique contenant plusieurs sites
- **Zone Pointing**: Pointage effectué par un chef de zone
- **Modern UI**: Interface utilisateur moderne avec design system cohérent
- **Report Generation**: Génération de rapports Excel/PDF pour les pointages

## Requirements

### Requirement 1: Liste moderne des pointages zone

**User Story:** En tant qu'administrateur, je veux voir les pointages des chefs de zone dans une interface moderne, afin de consulter facilement les données.

#### Acceptance Criteria

1. WHEN l'utilisateur accède à `/pointagezones`, THE System SHALL afficher une liste moderne avec statistiques
2. THE System SHALL utiliser le même design system que `/pointages` (PointageProvider, FilterBar, ModernPointageTable)
3. THE System SHALL afficher les statistiques: total pointages, chefs de zone uniques, zones uniques, moyenne par jour
4. THE System SHALL permettre la recherche et le filtrage par chef de zone, zone, et période

### Requirement 2: Rapports de pointage par chef de zone

**User Story:** En tant qu'administrateur, je veux générer des rapports de pointage par chef de zone, afin d'analyser leur performance.

#### Acceptance Criteria

1. WHEN l'utilisateur clique sur "Rapport de pointage" (`/pointagezones/npcz`), THE System SHALL afficher le rapport moderne
2. THE System SHALL utiliser ReportGenerator pour générer les rapports Excel/PDF
3. THE System SHALL afficher les données avec graphiques (PerformanceChart)
4. THE System SHALL permettre la sélection de période et de chefs de zone spécifiques

### Requirement 3: Rapport mensuel des visites par zone

**User Story:** En tant qu'administrateur, je veux voir le nombre de visites des sites par chef de zone, afin d'évaluer la couverture.

#### Acceptance Criteria

1. WHEN l'utilisateur accède à `/pointagezones/nvcz`, THE System SHALL afficher le rapport mensuel moderne
2. THE System SHALL utiliser VisitFrequencyChart pour visualiser les données
3. THE System SHALL permettre le basculement entre vue tableau et graphique (ChartViewToggle)
4. THE System SHALL générer des rapports exportables en Excel/PDF

### Requirement 4: Pointage manuel pour chefs de zone

**User Story:** En tant qu'administrateur, je veux enregistrer des pointages manuels pour les chefs de zone, afin de corriger ou compléter les données.

#### Acceptance Criteria

1. WHEN l'utilisateur clique sur "Pointage manuel" dans zone_member_list, THE System SHALL ouvrir un dialogue moderne
2. THE System SHALL permettre la sélection de date, heure, et zone du chef de zone
3. THE System SHALL afficher la liste des sites de la zone sélectionnée
4. THE System SHALL permettre la sélection multiple de sites (un ou plusieurs sites visités)
5. THE System SHALL créer un pointage pour chaque site sélectionné
6. THE System SHALL valider les données avant enregistrement (date, zone, au moins un site)
7. THE System SHALL afficher un message de succès/erreur avec SuccessSnackbar/ErrorDisplay

### Requirement 5: Génération automatique de pointages mensuels

**User Story:** En tant qu'administrateur, je veux que les pointages mensuels soient générés automatiquement quand j'active un chef de zone, afin de maintenir l'historique.

#### Acceptance Criteria

1. WHEN un chef de zone est activé, THE System SHALL générer automatiquement les pointages du mois en cours
2. THE System SHALL créer un pointage par jour depuis le début du mois jusqu'à aujourd'hui
3. THE System SHALL utiliser la position de la première zone assignée
4. THE System SHALL éviter les doublons en utilisant des IDs uniques
