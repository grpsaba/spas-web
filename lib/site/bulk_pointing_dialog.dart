import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/pointerSite.dart';
import 'package:spas_web/services/supervisor.dart';

class BulkPointingDialog extends StatefulWidget {
  final List<Site> sites;

  const BulkPointingDialog({
    super.key,
    required this.sites,
  });

  @override
  State<BulkPointingDialog> createState() => _BulkPointingDialogState();
}

class _BulkPointingDialogState extends State<BulkPointingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  Supervisor? _selectedSupervisor;
  List<Supervisor> _supervisors = [];
  List<Site> _selectedSites = [];
  List<Site> _filteredSites = [];
  bool _isLoading = false;
  bool _skipValidation = false;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
    _setCurrentDateTime();
    _selectedSites = List.from(widget.sites);
    _filteredSites = List.from(widget.sites);
    _longitudeController.text = "-7.9955415";
    _latitudeController.text = "12.622504";
    _skipValidation = true;
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadSupervisors() async {
    try {
      final supervisors = await SupervisorService().allFuture();
      setState(() {
        _supervisors = supervisors.where((s) => s.actif == true).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des superviseurs: $e');
    }
  }

  void _setCurrentDateTime() {
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _timeController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _toggleSiteSelection(Site site) {
    setState(() {
      if (_selectedSites.contains(site)) {
        _selectedSites.remove(site);
      } else {
        _selectedSites.add(site);
      }
    });
  }

  void _selectAllSites() {
    setState(() {
      _selectedSites = List.from(_filteredSites);
    });
  }

  void _deselectAllSites() {
    setState(() {
      _selectedSites.clear();
    });
  }

  void _filterSitesBySupervisor(Supervisor? supervisor) {
    setState(() {
      if (supervisor == null) {
        _filteredSites = List.from(widget.sites);
      } else {
        _filteredSites = widget.sites.where((site) {
          // Vérifier si le superviseur est assigné au site (supervisor principal ou secondaire)
          return site.supervisor?.UID == supervisor.UID ||
              site.supervisor_2?.UID == supervisor.UID;
        }).toList();
      }

      // Mettre à jour les sites sélectionnés pour ne garder que ceux qui sont encore dans la liste filtrée
      _selectedSites = _selectedSites
          .where((site) => _filteredSites.contains(site))
          .toList();
    });
  }

  Future<void> _saveBulkPointings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupervisor == null) {
      _showErrorSnackBar('Veuillez sélectionner un superviseur');
      return;
    }
    if (_selectedSites.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner au moins un site');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parser la date et l'heure
      final dateParts = _dateController.text.split('/');
      final timeParts = _timeController.text.split(':');

      final date = DateTime(
        int.parse(dateParts[2]), // année
        int.parse(dateParts[1]), // mois
        int.parse(dateParts[0]), // jour
        int.parse(timeParts[0]), // heure
        int.parse(timeParts[1]), // minute
      );

      final lat = double.parse(_latitudeController.text);
      final lng = double.parse(_longitudeController.text);

      int successCount = 0;
      int errorCount = 0;

      // Créer les pointages pour tous les sites sélectionnés
      for (final site in _selectedSites) {
        try {
          final pointingSite = PointingSite(
            site: site,
            supervisor: _selectedSupervisor,
            latlng: LatLngModel(lat: lat, lng: lng),
            date: date,
            distance: _skipValidation
                ? 0
                : _calculateDistance(
                    lat, lng, site.latLng.lat, site.latLng.lng),
          );

          await PointingSiteService().add(pointingSite);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Erreur pour le site ${site.name}: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar(
            'Pointages créés: $successCount succès, $errorCount erreurs');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'enregistrement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // Formule de Haversine pour calculer la distance entre deux points GPS
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800,
        height: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Icon(Icons.checklist,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pointage en lot - ${_selectedSites.length} site(s) sélectionné(s)',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Informations générales
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Supervisor>(
                        initialValue: _selectedSupervisor,
                        decoration: const InputDecoration(
                          labelText: 'Superviseur',
                          border: OutlineInputBorder(),
                        ),
                        items: _supervisors.map((supervisor) {
                          return DropdownMenuItem(
                            value: supervisor,
                            child: Text(
                                '${supervisor.firstName} ${supervisor.lastName}'),
                          );
                        }).toList(),
                        onChanged: (Supervisor? value) {
                          setState(() {
                            _selectedSupervisor = value;
                          });
                          _filterSitesBySupervisor(value);
                        },
                        validator: (value) => value == null
                            ? 'Sélectionnez un superviseur'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date (JJ/MM/AAAA)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Date requise';
                          }
                          final parts = value.split('/');
                          if (parts.length != 3) {
                            return 'Format invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Heure (HH:MM)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Heure requise';
                          }
                          final parts = value.split(':');
                          if (parts.length != 2) {
                            return 'Format invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Coordonnées GPS
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 5.123456',
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Latitude requise';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Latitude invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: -3.123456',
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Longitude requise';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Longitude invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Option de validation GPS
                CheckboxListTile(
                  title: const Text('Ignorer validation GPS'),
                  subtitle: const Text(
                      'Cocher si vous faites confiance aux coordonnées'),
                  value: _skipValidation,
                  onChanged: (bool? value) {
                    setState(() {
                      _skipValidation = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),

                // Sélection des sites
                if (_selectedSupervisor != null && _filteredSites.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        'Sites à pointer (${_selectedSites.length}/${_filteredSites.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _selectAllSites,
                        child: const Text('Tout sélectionner'),
                      ),
                      TextButton(
                        onPressed: _deselectAllSites,
                        child: const Text('Tout désélectionner'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Message informatif
                if (_selectedSupervisor == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sélectionnez un superviseur pour voir ses sites assignés',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectedSupervisor != null && _filteredSites.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_outlined,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucun site assigné à ce superviseur',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectedSupervisor != null && _filteredSites.isNotEmpty)
                  const SizedBox(height: 8),

                // Liste des sites avec checkboxes
                if (_selectedSupervisor != null && _filteredSites.isNotEmpty)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredSites.length,
                        itemBuilder: (context, index) {
                          final site = _filteredSites[index];
                          final isSelected = _selectedSites.contains(site);

                          return CheckboxListTile(
                            title: Text(site.name),
                            subtitle: Text(
                                '${site.adresse} - GPS: ${site.latLng.lat}, ${site.latLng.lng}'),
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleSiteSelection(site);
                            },
                            secondary: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveBulkPointings,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Créer ${_selectedSites.length} pointage(s)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
