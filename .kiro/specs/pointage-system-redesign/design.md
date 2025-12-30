# Design Document - Pointage System Redesign

## Overview

Cette refonte transforme le module de pointage en un système moderne, performant et scalable. L'architecture privilégie le traitement côté serveur, une UI/UX moderne avec Material Design 3, et une séparation claire des responsabilités.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Pointage    │  │   Report     │  │   Report     │      │
│  │  List Page   │  │ Supervisor   │  │    Site      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Pointage    │  │    Report    │  │    Cache     │      │
│  │  Provider    │  │   Generator  │  │   Manager    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Pointage    │  │  Aggregation │  │    Local     │      │
│  │  Repository  │  │   Service    │  │   Storage    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌──────────────┐
                    │   Firebase   │
                    │  Firestore   │
                    └──────────────┘
```

### Technology Stack

- **Frontend Framework**: Flutter Web
- **State Management**: Provider (existant) + ChangeNotifier
- **Database**: Firebase Firestore
- **Caching**: SharedPreferences / Hive
- **Charts**: fl_chart
- **Excel Generation**: syncfusion_flutter_xlsio (existant)
- **PDF Generation**: pdf package (existant)
- **Date Picker**: flutter_date_range_picker
- **UI Components**: Material Design 3

## Components and Interfaces

### 1. Presentation Layer Components

#### 1.1 PointageListPage (Refactored)

**Responsabilités:**
- Afficher la liste paginée des pointages
- Gérer les filtres et la recherche
- Afficher les statistiques en temps réel
- Navigation vers les rapports

**Widgets principaux:**

```dart
PointageListPage
├── AppBar (avec actions)
├── StatisticsCard (dashboard résumé)
├── FilterBar (recherche + filtres avancés)
├── PointageDataTable (table moderne paginée)
└── FloatingActionButtons (exports rapides)
```

**État géré:**
- Filtres actifs (date range, supervisor, site, zone)
- Pagination (page courante, items par page)
- Tri (colonne, direction)
- Mode d'affichage (table/cards)

#### 1.2 ReportSupervisorPage (Refactored)

**Responsabilités:**
- Sélection de période pour rapport
- Génération de rapport avec progression
- Téléchargement automatique
- Prévisualisation des données

**Widgets principaux:**

```dart
ReportSupervisorPage
├── ReportHeader (titre + description)
├── DateRangePicker (sélection période)
├── SupervisorFilter (optionnel: filtrer superviseurs)
├── GenerationProgressCard (barre de progression)
├── PreviewDataTable (aperçu avant génération)
└── ActionButtons (générer, annuler, télécharger)
```

**État géré:**
- Date range sélectionnée
- Superviseurs sélectionnés
- État de génération (idle, loading, success, error)
- Progression (0-100%)
- Données de prévisualisation

#### 1.3 ReportSitePage (Refactored)

**Responsabilités:**
- Sélection de période pour rapport par site
- Génération de rapport avec progression
- Affichage de graphiques de visites
- Export multi-formats

**Widgets principaux:**

```dart
ReportSitePage
├── ReportHeader
├── DateRangePicker
├── SiteFilter (optionnel: filtrer sites)
├── VisitChartCard (graphique des visites)
├── GenerationProgressCard
└── ActionButtons (générer Excel/PDF)
```

### 2. Business Logic Layer

#### 2.1 PointageProvider

**Responsabilités:**
- Gestion de l'état des pointages
- Coordination entre UI et Repository
- Gestion du cache
- Notification des changements

**Interface:**

```dart
class PointageProvider extends ChangeNotifier {
  // État
  List<PointingSite> _pointages = [];
  PointageFilters _filters = PointageFilters();
  PaginationState _pagination = PaginationState();
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<PointingSite> get pointages;
  PointageFilters get filters;
  bool get isLoading;
  String? get error;
  
  // Actions
  Future<void> loadPointages({bool refresh = false});
  Future<void> applyFilters(PointageFilters filters);
  Future<void> loadNextPage();
  Future<void> refreshData();
  void clearError();
}
```

#### 2.2 ReportGenerator

**Responsabilités:**
- Génération de rapports Excel/PDF
- Agrégation des données
- Calcul des statistiques
- Gestion de la progression

**Interface:**

```dart
class ReportGenerator {
  // Génération rapport superviseur
  Future<ReportResult> generateSupervisorReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? supervisorIds,
    ReportFormat format = ReportFormat.excel,
    Function(double progress)? onProgress,
  });
  
  // Génération rapport site
  Future<ReportResult> generateSiteReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? siteIds,
    ReportFormat format = ReportFormat.excel,
    Function(double progress)? onProgress,
  });
  
  // Prévisualisation données
  Future<ReportPreview> previewSupervisorReport({
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

#### 2.3 CacheManager

**Responsabilités:**
- Gestion du cache local
- Invalidation intelligente
- Stratégies de cache

**Interface:**

```dart
class CacheManager {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> invalidate(String key);
  Future<void> invalidatePattern(String pattern);
  Future<void> clear();
  bool isValid(String key);
}
```

### 3. Data Layer

#### 3.1 PointageRepository

**Responsabilités:**
- Accès aux données Firestore
- Requêtes optimisées
- Pagination côté serveur
- Agrégation

**Interface:**

```dart
class PointageRepository {
  // Requêtes paginées
  Future<PaginatedResult<PointingSite>> getPointages({
    required int page,
    required int pageSize,
    PointageFilters? filters,
    SortConfig? sort,
  });
  
  // Agrégations serveur
  Future<Map<String, int>> countPointagesBySupervisor({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? supervisorIds,
  });
  
  Future<Map<String, int>> countPointagesBySite({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? siteIds,
  });
  
  // Statistiques
  Future<PointageStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

#### 3.2 AggregationService

**Responsabilités:**
- Requêtes d'agrégation optimisées
- Utilisation de Firebase Aggregation Queries
- Batch processing pour gros volumes

**Interface:**

```dart
class AggregationService {
  // Agrégation par superviseur et jour
  Future<Map<String, Map<DateTime, int>>> aggregateBySupervisorAndDay({
    required List<String> supervisorIds,
    required List<DateTime> days,
  });
  
  // Agrégation par site et période
  Future<Map<String, int>> aggregateBySiteAndPeriod({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  // Statistiques globales
  Future<GlobalStats> getGlobalStats({
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

## Data Models

### Core Models (Enhanced)

```dart
// Filtres de pointage
class PointageFilters {
  DateTimeRange? dateRange;
  List<String>? supervisorIds;
  List<String>? siteIds;
  List<String>? zoneIds;
  String? searchQuery;
  
  Map<String, dynamic> toFirestoreQuery();
  bool get isEmpty;
}

// Configuration de pagination
class PaginationState {
  int currentPage;
  int itemsPerPage;
  int totalItems;
  bool hasMore;
  
  int get totalPages;
  bool get canGoNext;
  bool get canGoPrevious;
}

// Résultat paginé
class PaginatedResult<T> {
  List<T> items;
  int totalCount;
  int page;
  int pageSize;
  bool hasMore;
}

// Configuration de tri
class SortConfig {
  String field;
  bool ascending;
}

// Statistiques de pointage
class PointageStats {
  int totalPointages;
  int uniqueSites;
  int uniqueSupervisors;
  double averagePointagesPerDay;
  Map<String, int> pointagesBySupervisor;
  Map<String, int> pointagesBySite;
}

// Résultat de rapport
class ReportResult {
  Uint8List fileBytes;
  String filename;
  ReportFormat format;
  DateTime generatedAt;
  ReportMetadata metadata;
}

// Métadonnées de rapport
class ReportMetadata {
  DateTime startDate;
  DateTime endDate;
  int totalRecords;
  Duration generationTime;
  Map<String, dynamic> filters;
}

// Prévisualisation de rapport
class ReportPreview {
  List<SupervisorReportRow> rows;
  int totalSupervisors;
  int totalPointages;
  double averagePerformance;
}

// Ligne de rapport superviseur
class SupervisorReportRow {
  Supervisor supervisor;
  int nbSites;
  int maxPointages;
  int actualPointages;
  double performance;
  Map<DateTime, int> dailyPointages;
}

// Format de rapport
enum ReportFormat {
  excel,
  pdf,
  csv
}
```

## UI/UX Design Specifications

### Design System

**Colors:**
```dart
class PointageColors {
  static const primary = Color(0xFF3F51B5); // Indigo
  static const secondary = Color(0xFF00BCD4); // Cyan
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}
```

**Typography:**
```dart
class PointageTextStyles {
  static const headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: PointageColors.textPrimary,
  );
  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: PointageColors.textPrimary,
  );
  static const body1 = TextStyle(
    fontSize: 16,
    color: PointageColors.textPrimary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    color: PointageColors.textSecondary,
  );
}
```

**Spacing:**
```dart
class PointageSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

### Component Designs

#### Modern Dialog Design

```dart
// Remplacement des AlertDialog basiques
class ModernDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<DialogAction> actions;
  
  // Design:
  // - Coins arrondis (16px)
  // - Padding généreux
  // - Boutons avec états hover
  // - Animation d'entrée smooth
  // - Backdrop blur
}
```

#### Enhanced Date Picker

```dart
// Remplacement du DateTimeField basique
class ModernDateRangePicker extends StatelessWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange) onRangeSelected;
  
  // Features:
  // - Calendrier visuel
  // - Sélection rapide (Cette semaine, Ce mois, etc.)
  // - Validation en temps réel
  // - Prévisualisation du nombre de jours
}
```

#### Progress Card

```dart
class GenerationProgressCard extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String currentStep;
  final bool canCancel;
  final VoidCallback? onCancel;
  
  // Design:
  // - Barre de progression animée
  // - Pourcentage affiché
  // - Étape courante
  // - Bouton annuler si applicable
  // - Estimation du temps restant
}
```

#### Statistics Dashboard Card

```dart
class StatisticsCard extends StatelessWidget {
  final PointageStats stats;
  
  // Layout:
  // ┌─────────────────────────────────────┐
  // │  Total Pointages    Unique Sites    │
  // │      1,234              45           │
  // │                                      │
  // │  Superviseurs      Moy/Jour         │
  // │       12              41            │
  // └─────────────────────────────────────┘
}
```

#### Modern Data Table

```dart
class ModernPointageTable extends StatelessWidget {
  final List<PointingSite> pointages;
  final SortConfig sort;
  final Function(SortConfig) onSort;
  
  // Features:
  // - Hover effects sur les lignes
  // - Tri avec icônes animées
  // - Colonnes redimensionnables
  // - Actions rapides (icônes)
  // - Alternance de couleurs subtile
  // - Skeleton loading
}
```

## Error Handling

### Error Types

```dart
enum PointageErrorType {
  networkError,
  permissionDenied,
  dataNotFound,
  invalidInput,
  generationFailed,
  cacheError,
}

class PointageException implements Exception {
  final PointageErrorType type;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  
  String get userMessage; // Message convivial
  bool get isRetryable;
}
```

### Error Handling Strategy

1. **Network Errors**: Afficher snackbar avec bouton retry
2. **Permission Errors**: Rediriger vers login ou afficher message
3. **Data Errors**: Afficher message explicatif avec suggestions
4. **Generation Errors**: Permettre retry ou export partiel
5. **Cache Errors**: Fallback sur données serveur

## Testing Strategy

### Unit Tests

- **Providers**: Test de la logique métier
- **Repositories**: Mock Firestore, test des requêtes
- **Generators**: Test de génération de rapports
- **Cache Manager**: Test des stratégies de cache

### Widget Tests

- **Pages**: Test du rendu et des interactions
- **Dialogs**: Test de validation et soumission
- **Tables**: Test du tri et pagination
- **Charts**: Test de l'affichage des données

### Integration Tests

- **Flow complet**: De la liste au téléchargement de rapport
- **Filtrage**: Application de filtres multiples
- **Pagination**: Navigation entre pages
- **Cache**: Invalidation et refresh

## Performance Optimizations

### Firebase Query Optimization

**Avant:**
```dart
// ❌ Charge tout en mémoire
final allPointages = await collection.get();
final filtered = allPointages.where(...).toList();
```

**Après:**
```dart
// ✅ Filtre côté serveur
final query = collection
  .where('date', isGreaterThanOrEqualTo: startDate)
  .where('date', isLessThan: endDate)
  .limit(pageSize);
final pointages = await query.get();
```

### Aggregation Optimization

**Avant:**
```dart
// ❌ N×M requêtes (10 superviseurs × 30 jours = 300 requêtes)
for (supervisor in supervisors) {
  for (day in days) {
    final count = await countForDate(supervisor, day);
  }
}
```

**Après:**
```dart
// ✅ 1 requête avec agrégation
final counts = await collection
  .where('supervisor.UID', whereIn: supervisorIds)
  .where('date', isGreaterThanOrEqualTo: startDate)
  .where('date', isLessThan: endDate)
  .count()
  .get();
```

### Caching Strategy

```dart
// Cache avec TTL
final cacheKey = 'pointages_${filters.hashCode}';
final cached = await cacheManager.get(cacheKey);

if (cached != null && cacheManager.isValid(cacheKey)) {
  return cached; // Retour immédiat
}

final fresh = await repository.getPointages(filters);
await cacheManager.set(cacheKey, fresh, ttl: Duration(minutes: 5));
return fresh;
```

### Lazy Loading

```dart
// Chargement progressif des données
class PointageListView extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: pointages.length + 1,
      itemBuilder: (context, index) {
        if (index == pointages.length) {
          // Trigger load more
          provider.loadNextPage();
          return LoadingIndicator();
        }
        return PointageCard(pointages[index]);
      },
    );
  }
}
```

## Migration Strategy

### Phase 1: Infrastructure (Week 1)
- Créer les nouveaux models
- Implémenter Repository pattern
- Setup Provider architecture
- Créer CacheManager

### Phase 2: Data Layer (Week 1-2)
- Implémenter PointageRepository
- Créer AggregationService
- Optimiser les requêtes Firebase
- Tests unitaires

### Phase 3: Business Logic (Week 2)
- Implémenter PointageProvider
- Créer ReportGenerator
- Intégrer cache
- Tests unitaires

### Phase 4: UI Components (Week 2-3)
- Créer design system
- Implémenter composants réutilisables
- Créer dialogs modernes
- Widget tests

### Phase 5: Pages (Week 3-4)
- Refactoriser PointageListPage
- Refactoriser ReportSupervisorPage
- Refactoriser ReportSitePage
- Integration tests

### Phase 6: Polish & Deploy (Week 4)
- Performance tuning
- Error handling
- Documentation
- Déploiement

## Security Considerations

- Validation des inputs côté client ET serveur
- Sanitization des données avant export
- Vérification des permissions Firebase
- Rate limiting sur les requêtes coûteuses
- Logs d'audit pour les exports de rapports

## Accessibility

- Labels ARIA sur tous les éléments interactifs
- Navigation au clavier complète
- Contraste de couleurs WCAG AA
- Tailles de texte ajustables
- Annonces pour les lecteurs d'écran
