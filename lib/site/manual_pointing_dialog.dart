import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/pointerSite.dart';
import 'package:spas_web/services/supervisor.dart';

class ManualPointingDialog extends StatefulWidget {
  final Site site;

  const ManualPointingDialog({
    super.key,
    required this.site,
  });

  @override
  State<ManualPointingDialog> createState() => _ManualPointingDialogState();
}

class _ManualPointingDialogState extends State<ManualPointingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  Supervisor? _selectedSupervisor;
  List<Supervisor> _supervisors = [];
  bool _isLoading = false;
  bool _isValidating = false;
  String? _validationMessage;
  double? _calculatedDistance;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
    _setCurrentDateTime();
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
        _supervisors = supervisors
            .where((s) =>
                s.UID == widget.site.supervisor?.UID ||
                s.UID == widget.site.supervisor_2?.UID)
            .toList();

        // Sélectionner automatiquement le superviseur principal s'il n'y en a qu'un
        if (_supervisors.length == 1) {
          _selectedSupervisor = _supervisors.first;
        }
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

  Future<void> _validateLocation() async {
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      _showErrorSnackBar('Veuillez saisir les coordonnées GPS');
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
      _calculatedDistance = null;
    });

    try {
      final lat = double.parse(_latitudeController.text);
      final lng = double.parse(_longitudeController.text);

      // Calculer la distance entre la position saisie et le site
      final distance = _calculateDistance(
          lat, lng, widget.site.latLng.lat, widget.site.latLng.lng);

      setState(() {
        _calculatedDistance = distance;
        _validationMessage = distance <= 200
            ? '✅ Position valide (${distance.toStringAsFixed(0)}m du site)'
            : '⚠️ Position éloignée (${distance.toStringAsFixed(0)}m du site)';
      });
    } catch (e) {
      setState(() {
        _validationMessage = '❌ Coordonnées GPS invalides';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // Formule de Haversine pour calculer la distance entre deux points GPS
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);

    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (Math.pi / 180);
  }

  Future<void> _savePointing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupervisor == null) {
      _showErrorSnackBar('Veuillez sélectionner un superviseur');
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

      final pointingSite = PointingSite(
        site: widget.site,
        supervisor: _selectedSupervisor,
        latlng: LatLngModel(lat: lat, lng: lng),
        date: date,
        distance: _calculatedDistance ?? 0,
      );

      await PointingSiteService().add(pointingSite);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar('Pointage enregistré avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'enregistrement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pointage manuel - ${widget.site.name}',
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

              // Informations du site
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Site: ${widget.site.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Adresse: ${widget.site.adresse}'),
                    Text(
                        'Position GPS: ${widget.site.latLng.lat}, ${widget.site.latLng.lng}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sélection du superviseur
              DropdownButtonFormField<Supervisor>(
                value: _selectedSupervisor,
                decoration: const InputDecoration(
                  labelText: 'Superviseur',
                  border: OutlineInputBorder(),
                ),
                items: _supervisors.map((supervisor) {
                  return DropdownMenuItem(
                    value: supervisor,
                    child:
                        Text('${supervisor.firstName} ${supervisor.lastName}'),
                  );
                }).toList(),
                onChanged: (Supervisor? value) {
                  setState(() {
                    _selectedSupervisor = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Sélectionnez un superviseur' : null,
              ),
              const SizedBox(height: 16),

              // Date et heure
              Row(
                children: [
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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isValidating ? null : _validateLocation,
                    child: _isValidating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                ],
              ),

              // Message de validation
              if (_validationMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _calculatedDistance != null &&
                            _calculatedDistance! <= 200
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _calculatedDistance != null &&
                              _calculatedDistance! <= 200
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: _calculatedDistance != null &&
                              _calculatedDistance! <= 200
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

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
                    onPressed: _isLoading ? null : _savePointing,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer le pointage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
