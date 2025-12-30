# Requirements Document

## Introduction

Ce document définit les exigences pour améliorer l'interface utilisateur et les fonctionnalités des pages de pointage dans l'application SPAS-Web. Les améliorations couvrent la liste des pointages de sites, la liste des pointages de zone, la gestion des erreurs de pointage, et le formulaire des chefs de zone.

## Glossary

- **Pointage_Site_List**: Page affichant la liste des pointages effectués par les superviseurs sur les sites
- **Pointage_Zone_List**: Page affichant la liste des pointages effectués par les chefs de zone
- **Error_Log_System**: Système de gestion des erreurs de pointage avec visualisation et résolution
- **Zone_Member_Form**: Formulaire d'ajout/modification des chefs de zone
- **Manual_Pointing_Page**: Page dédiée au pointage manuel des chefs de zone
- **Statistics_Card**: Composant affichant les statistiques de pointage
- **Design_System**: Système de design unifié (PointageColors, PointageSpacing, etc.)
- **Glass_Smooth_Reaction**: Style d'interaction fluide avec effets visuels subtils (hover, transitions)

## Requirements

### Requirement 1: Correction des filtres de période dans Pointage_Site_List

**User Story:** En tant que contrôleur, je veux que les filtres de période fonctionnent correctement, afin de pouvoir visualiser les pointages d'une date spécifique.

#### Acceptance Criteria

1. WHEN un utilisateur sélectionne "Aujourd'hui" dans le filtre de période THEN THE Pointage_Site_List SHALL appliquer le filtre immédiatement et afficher uniquement les pointages du jour
2. WHEN un utilisateur sélectionne une plage de dates et clique sur "Appliquer" THEN THE Dialog SHALL se fermer automatiquement et THE Pointage_Site_List SHALL afficher les pointages filtrés
3. WHEN un filtre de période est appliqué THEN THE Pointage_Site_List SHALL afficher un indicateur visuel montrant la période active

### Requirement 2: Réorganisation des colonnes du tableau de pointages

**User Story:** En tant que contrôleur, je veux voir les informations les plus importantes en premier, afin de faciliter la lecture des pointages.

#### Acceptance Criteria

1. THE Modern_Pointage_Table SHALL afficher les colonnes dans l'ordre suivant: Superviseur, Site, Zone, Date, Heure
2. THE Date column SHALL afficher la date avec un Chip coloré (fond bleu clair) pour une meilleure visibilité
3. THE Heure column SHALL afficher l'heure avec un Chip coloré (fond orange clair) pour une meilleure visibilité
4. WHEN les colonnes sont réorganisées THEN THE sorting functionality SHALL continuer à fonctionner correctement

### Requirement 3: Mise à jour des coordonnées de site depuis les erreurs de distance

**User Story:** En tant qu'administrateur, je veux pouvoir corriger les coordonnées GPS d'un site directement depuis une erreur de distance, afin de résoudre les problèmes de géolocalisation.

#### Acceptance Criteria

1. WHEN une erreur de type "distanceError" est affichée THEN THE Error_Log_Detail_Page SHALL afficher un bouton "Mettre à jour les coordonnées du site"
2. WHEN l'utilisateur clique sur "Mettre à jour les coordonnées du site" THEN THE System SHALL afficher une confirmation avec les nouvelles coordonnées (position du superviseur)
3. WHEN l'utilisateur confirme la mise à jour THEN THE System SHALL mettre à jour les coordonnées lat/lng du site dans Firestore
4. WHEN la mise à jour est réussie THEN THE System SHALL afficher un message de succès et proposer de marquer l'erreur comme résolue
5. IF la mise à jour échoue THEN THE System SHALL afficher un message d'erreur explicatif

### Requirement 4: Finalisation de la migration de Pointage_Zone_List

**User Story:** En tant que contrôleur, je veux que la page des pointages de zone utilise l'architecture moderne, afin d'avoir une expérience cohérente avec les autres pages.

#### Acceptance Criteria

1. THE Pointage_Zone_List_Modern SHALL afficher les statistiques correctement (pas "Aucune statistique disponible")
2. THE Statistics_Card SHALL avoir une taille réduite et compacte
3. THE Pointage_Zone_List_Modern SHALL être entièrement scrollable (page complète)
4. THE colonnes du tableau SHALL être dans l'ordre: Chef de zone, Site, Zone, Date, Heure, Contact
5. THE Date et Heure columns SHALL utiliser des Chips colorés comme dans la version legacy

### Requirement 5: Uniformisation du design des boutons

**User Story:** En tant qu'utilisateur, je veux que tous les boutons aient un style cohérent, afin d'avoir une interface professionnelle et intuitive.

#### Acceptance Criteria

1. THE "Pointage manuel" button dans Zone_Member_List SHALL utiliser le style PointageButtonStyles.outlined ou un style cohérent avec le design system
2. WHEN un bouton est survolé THEN THE System SHALL afficher un effet hover subtil (glass smooth reaction)
3. ALL action buttons SHALL utiliser les couleurs et espacements du design system

### Requirement 6: Migration du pointage manuel vers une page dédiée

**User Story:** En tant qu'administrateur, je veux effectuer les pointages manuels dans une page dédiée, afin d'avoir plus d'espace et une meilleure expérience utilisateur.

#### Acceptance Criteria

1. WHEN l'utilisateur clique sur "Pointage manuel" THEN THE System SHALL naviguer vers une nouvelle page dédiée (pas un dialog)
2. THE Manual_Pointing_Page SHALL afficher la liste des chefs de zone actifs avec recherche
3. WHEN un chef de zone est sélectionné THEN THE System SHALL afficher le formulaire de pointage dans la même page
4. THE Manual_Pointing_Page SHALL permettre la sélection de date, heure et sites multiples
5. THE Manual_Pointing_Page SHALL utiliser le design system et avoir un style glass smooth reaction

### Requirement 7: Modernisation du formulaire Zone_Member_Form

**User Story:** En tant qu'administrateur, je veux un formulaire d'ajout de chef de zone élégant et professionnel, afin d'avoir une expérience utilisateur agréable.

#### Acceptance Criteria

1. THE Zone_Member_Form SHALL utiliser le design system (PointageColors, PointageSpacing, PointageTextStyles)
2. THE Zone_Member_Form SHALL avoir une mise en page en sections avec des cartes
3. THE form fields SHALL utiliser PointageInputDecorations.standard
4. THE buttons SHALL utiliser PointageButtonStyles
5. THE Zone_Member_Form SHALL avoir des animations subtiles (glass smooth reaction) sur les interactions
6. WHEN le formulaire est en cours de soumission THEN THE System SHALL afficher un indicateur de chargement élégant
7. THE Zone_Member_Form SHALL afficher les erreurs de validation de manière claire et non intrusive

### Requirement 8: Amélioration de la section statistiques

**User Story:** En tant que contrôleur, je veux une section statistiques compacte et informative, afin de voir rapidement les métriques importantes sans occuper trop d'espace.

#### Acceptance Criteria

1. THE Statistics_Card SHALL avoir une version compacte avec une hauteur réduite
2. THE Statistics_Card compact version SHALL afficher les 4 métriques sur une seule ligne
3. WHEN l'écran est petit THEN THE Statistics_Card SHALL s'adapter en affichant 2 métriques par ligne
4. THE Statistics_Card SHALL supporter un paramètre `compact: true` pour activer le mode compact

