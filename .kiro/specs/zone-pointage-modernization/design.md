# Design: Modernisation du système de pointage des zones

## Overview

Adapter le système moderne de pointage des sites pour les zones en réutilisant les composants existants (PointageProvider, ReportGenerator, FilterBar, etc.) avec des adaptations minimales pour les chefs de zone.

## Architecture

### Réutilisation des composants existants

```
lib/pointage_redesign/
├── providers/
│   ├── pointage_provider.dart (réutilisé avec adaptation)
│   └── report_generator.dart (réutilisé avec adaptation)
├── data/
│   ├── pointage_repository.dart (adapter pour PointingZone)
│   └── cache_manager.dart (réutilisé)
└── presentation/
    └── widgets/ (tous réutilisés)
```

### Nouvelles pages zone

```
lib/zone/
├── pointage_zone_list.dart (modernisé)
├── zone_pointage_map.dart (nouveau - rapport par chef de zone)
└── zone_site_monthly_pointage.dart (modernisé)
```

## Components and Interfaces

### 1. PointageZoneRepository

Adapter `PointageRepository` pour gérer `PointingZone`:

```dart
class PointageZoneRepository {
  final PointingZoneService _service = PointingZoneService();
  
  Future<List<PointingZone>> fetchPointages({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? zoneMemberIds,
    List<String>? zoneIds,
  }) async {
    // Logique similaire à PointageRepository
  }
  
  Stream<List<PointingZone>> streamPointages() {
    return _service.all().map((snapshot) {
      return snapshot.docs
        .map((doc) => PointingZone.fromJson(doc.data()))
        .toList();
    });
  }
}
```

### 2. PointageZoneProvider

Étendre ou adapter `PointageProvider`:

```dart
class PointageZoneProvider extends ChangeNotifier {
  final PointageZoneRepository _repository;
  
  List<PointingZone> _pointages = [];
  PointageZoneStats? _stats;
  PointageFilters _filters = PointageFilters();
  
  // Mêmes méthodes que PointageProvider
  Future<void> loadPointages() async { }
  Future<void> loadStats() async { }
  void applyFilters(PointageFilters filters) { }
}
```

### 3. Pages modernisées

#### PointageZoneList (modernisé)

```dart
class PointageZoneList extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PointageZoneProvider(
        repository: PointageZoneRepository(),
        cacheManager: CacheManager(),
      ),
      child: PageModel(
        pageIndex: 15,
        title: "Pointages des chefs de zone",
        child: Consumer<PointageZoneProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                StatisticsCard(stats: provider.stats),
                FilterBar(
                  filters: provider.filters,
                  onFiltersChanged: provider.applyFilters,
                  availableZoneMembers: _zoneMembers,
                  availableZones: _zones,
                ),
                ModernPointageTable(
                  pointages: provider.pointages,
                  // Adapter pour afficher chef de zone au lieu de superviseur
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

#### ZonePointageMap (nouveau)

Similaire à `SitePointageMap` mais pour les chefs de zone:

```dart
class ZonePointageMap extends StatefulWidget {
  final DateTime? date;
  
  @override
  Widget build(BuildContext context) {
    return PageModel(
      title: "Rapport de pointage par chef de zone",
      child: Column(
        children: [
          ReportHeader(
            title: 'Rapport des chefs de zone',
            icon: Icons.map_outlined,
          ),
          ModernDateRangePicker(
            onRangeSelected: _loadPreview,
          ),
          // Sélection des chefs de zone
          // Bouton génération avec ReportGenerator
          if (_isGenerating)
            GenerationProgressCard(
              progress: _progress,
              currentStep: _currentStep,
            ),
          if (_preview != null)
            PerformanceChart(data: _chartData),
        ],
      ),
    );
  }
}
```

#### ZoneSiteMonthlyPointage (modernisé)

Adapter `SiteMonthlyPointage` pour les zones:

```dart
class ZoneSiteMonthlyPointage extends StatefulWidget {
  final DateTime date;
  
  @override
  Widget build(BuildContext context) {
    return PageModel(
      title: "Visites des sites par chef de zone",
      child: Column(
        children: [
          ChartViewToggle(
            onModeChanged: (mode) => setState(() => _viewMode = mode),
          ),
          AnimatedViewSwitcher(
            currentMode: _viewMode,
            tableView: ModernPointageTable(pointages: _data),
            chartView: VisitFrequencyChart(data: _chartData),
          ),
        ],
      ),
    );
  }
}
```

### 4. Pointage manuel pour chefs de zone

Ajouter dans `zone_member_list.dart`:

```dart
void _showManualPointingDialog(BuildContext context, ZoneMember zoneMember) {
  showDialog(
    context: context,
    builder: (context) => ManualZonePointingDialog(
      zoneMember: zoneMember,
    ),
  );
}

class ManualZonePointingDialog extends StatefulWidget {
  final ZoneMember zoneMember;
  
  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      title: 'Pointage manuel - ${zoneMember.firstName} ${zoneMember.lastName}',
      content: Column(
        children: [
          // Sélection de date et heure
          ModernDateRangePicker(onRangeSelected: _onDateSelected),
          TimePickerField(onTimeSelected: _onTimeSelected),
          
          // Sélection de la zone
          DropdownButton<Zone>(
            value: _selectedZone,
            items: _availableZones.map((zone) {
              return DropdownMenuItem(
                value: zone,
                child: Text(zone.name),
              );
            }).toList(),
            onChanged: (zone) {
              setState(() {
                _selectedZone = zone;
                _loadSitesForZone(zone);
              });
            },
          ),
          
          // Sélection MULTIPLE des sites de la zone
          if (_selectedZone != null) ...[
            SizedBox(height: 16),
            Text('Sites visités dans ${_selectedZone!.name}:'),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: ListView.builder(
                itemCount: _sitesInZone.length,
                itemBuilder: (context, index) {
                  final site = _sitesInZone[index];
                  final isSelected = _selectedSites.contains(site);
                  
                  return CheckboxListTile(
                    title: Text(site.name),
                    subtitle: Text(site.codeSite),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedSites.add(site);
                        } else {
                          _selectedSites.remove(site);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Text(
              '${_selectedSites.length} site(s) sélectionné(s)',
              style: TextStyle(
                color: _selectedSites.isEmpty ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        DialogAction(label: 'Annuler', onPressed: () => Navigator.pop(context)),
        DialogAction(
          label: 'Enregistrer ${_selectedSites.length} pointage(s)',
          isPrimary: true,
          onPressed: _selectedSites.isEmpty ? null : _savePointings,
        ),
      ],
    );
  }
  
  Future<void> _savePointings() async {
    // Créer un pointage pour CHAQUE site sélectionné
    for (final site in _selectedSites) {
      final pointing = PointingZone(
        zoneMember: widget.zoneMember,
        zone: _selectedZone!,
        site: site, // Le site visité
        date: _selectedDateTime,
        latlng: site.latLng, // Position du site
        distance: 0,
      );
      
      await PointingZoneService().add(pointing);
    }
    
    Navigator.pop(context);
    SuccessSnackbar.show(
      context,
      message: '${_selectedSites.length} pointage(s) enregistré(s) avec succès',
    );
  }
}
```

### 5. Génération automatique de pointages

Dans `zone_member_list.dart`, modifier `actifInactifAgent()`:

```dart
void actifInactifAgent() {
  setState(() => _updating = true);
  
  final bool wasInactive = !widget.zoneMember.actif!;
  widget.zoneMember.actif = !widget.zoneMember.actif!;
  
  ZoneMemberService().update(widget.zoneMember).then((value) {
    setState(() => _updating = false);
    
    // Si activé, générer les pointages mensuels
    if (wasInactive && widget.zoneMember.actif!) {
      _generateMonthlyPointingsForZoneMember(widget.zoneMember);
    }
  });
}

Future<void> _generateMonthlyPointingsForZoneMember(ZoneMember zoneMember) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  if (zoneMember.zone == null) return;
  
  for (DateTime date = startOfMonth;
       date.isBefore(now.add(Duration(days: 1)));
       date = date.add(Duration(days: 1))) {
    
    final pointing = PointingZone(
      zoneMember: zoneMember,
      zone: zoneMember.zone!,
      date: DateTime(date.year, date.month, date.day, 8, 0),
      latlng: LatLngModel(lat: 0, lng: 0), // Position par défaut
      distance: 0,
    );
    
    await PointingZoneService().add(pointing);
  }
}
```

## Data Models

Réutiliser les modèles existants avec adaptations:

```dart
class PointageZoneStats {
  final int totalPointages;
  final int uniqueZoneMembers;
  final int uniqueZones;
  final double averagePointagesPerDay;
  
  // Même structure que PointageStats
}

class ZoneMemberReportData {
  final ZoneMember zoneMember;
  final int totalPointages;
  final List<Zone> zones;
  final double performance;
  
  // Similaire à SupervisorReportData
}
```

## Error Handling

Réutiliser `PointageException` et `ErrorDisplay` existants.

## Testing Strategy

- Tester la réutilisation des composants avec données zone
- Vérifier la génération automatique de pointages
- Tester les rapports Excel/PDF pour zones
- Valider le pointage manuel
