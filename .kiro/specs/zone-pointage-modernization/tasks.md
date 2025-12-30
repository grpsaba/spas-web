# Implementation Plan: Modernisation du système de pointage des zones

## Tâches

- [x] 1. Moderniser la liste des pointages zone





  - Adapter PointageProvider pour PointingZone (créer PointageZoneProvider)
  - Créer PointageZoneRepository basé sur PointageRepository
  - Moderniser lib/zone/pointage_zone_list.dart avec StatisticsCard, FilterBar, ModernPointageTable
  - Ajouter les statistiques: total pointages, chefs de zone uniques, zones uniques, moyenne/jour
  - Implémenter la recherche et filtrage par chef de zone, zone, période
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Créer le rapport de pointage par chef de zone





  - Créer lib/zone/zone_pointage_map.dart (similaire à site_pointage_map.dart)
  - Adapter ReportGenerator pour générer des rapports de chefs de zone
  - Intégrer ModernDateRangePicker pour sélection de période
  - Ajouter sélection multi-chefs de zone avec FilterBar
  - Implémenter génération Excel/PDF avec ReportGenerator
  - Afficher PerformanceChart avec données des chefs de zone
  - Ajouter GenerationProgressCard pendant la génération
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 3. Moderniser le rapport mensuel des visites par zone





  - Moderniser lib/zone/zone_site_monthly_pointage.dart
  - Intégrer ChartViewToggle pour basculer tableau/graphique
  - Utiliser VisitFrequencyChart pour visualisation
  - Implémenter AnimatedViewSwitcher pour transitions fluides
  - Ajouter export Excel/PDF des données
  - Afficher statistiques avec StatisticsCard
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 4. Ajouter le pointage manuel pour chefs de zone





  - Créer ManualZonePointingDialog dans lib/zone_member/
  - Ajouter bouton "Pointage manuel" dans zone_member_list.dart
  - Intégrer ModernDateRangePicker pour sélection date/heure
  - Ajouter sélection de zone avec dropdown
  - Charger dynamiquement les sites de la zone sélectionnée
  - Implémenter sélection MULTIPLE de sites avec CheckboxListTile
  - Afficher le compteur de sites sélectionnés
  - Créer un pointage pour CHAQUE site sélectionné (boucle)
  - Implémenter validation: date, zone, au moins 1 site requis
  - Utiliser SuccessSnackbar avec nombre de pointages créés
  - Utiliser ErrorDisplay pour erreurs
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 5. Implémenter la génération automatique de pointages mensuels





  - Modifier actifInactifAgent() dans zone_member_list.dart
  - Détecter l'activation d'un chef de zone (wasInactive → actif)
  - Créer _generateMonthlyPointingsForZoneMember() 
  - Générer pointages du 1er du mois à aujourd'hui (8h par défaut)
  - Utiliser la zone assignée au chef de zone
  - Éviter les doublons avec IDs uniques Firebase
  - Afficher notification de succès/erreur
  - _Requirements: 5.1, 5.2, 5.3, 5.4_
