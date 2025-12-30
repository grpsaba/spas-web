import 'package:flutter/material.dart';
import '../model.dart';
import '../services/pointerZone.dart';
import '../services/site.dart';
import '../pointage_redesign/presentation/design_system.dart';
import '../pointage_redesign/presentation/dialogs/modern_dialog.dart';
import '../pointage_redesign/presentation/widgets/success_snackbar.dart';
import '../pointage_redesign/presentation/widgets/error_display.dart';
import '../pointage_redesign/models/pointage_exception.dart';

/// Dialog for manual zone pointing with multiple site selection
class ManualZonePointingDialog extends StatefulWidget {
  final ZoneMember zoneMember;

  const ManualZonePointingDialog({
    Key? key,
    required this.zoneMember,
  }) : super(key: key);

  @override
  State<ManualZonePointingDialog> createState() => _ManualZonePointingDialogState();
}

class _ManualZonePointingDialogState extends State<ManualZonePointingDialog> {
  final SiteService _siteService = SiteService();
  final PointingZoneService _pointingService = PointingZoneService();
  final TextEditingController _searchController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Zone? _selectedZone;
  List<Site> _sitesInZone = [];
  final Set<Site> _selectedSites = {};
  bool _isLoadingSites = false;
  bool _isSaving = false;
  PointageException? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize with zone member's zone if available
    if (widget.zoneMember.zone != null) {
      _selectedZone = widget.zoneMember.zone;
      _loadSitesForZone(widget.zoneMember.zone!);
    }
    // Initialize with current date and time
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Site> get _filteredSites {
    if (_searchQuery.isEmpty) return _sitesInZone;
    
    final query = _searchQuery.toLowerCase();
    return _sitesInZone.where((site) {
      return site.name.toLowerCase().contains(query) ||
          site.codeSite.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadSitesForZone(Zone zone) async {
    setState(() {
      _isLoadingSites = true;
      _error = null;
      _selectedSites.clear();
    });

    try {
      final sites = await _siteService.allSitesByZone(zone);
      setState(() {
        _sitesInZone = sites;
        _isLoadingSites = false;
      });
    } catch (e) {
      setState(() {
        _error = PointageException(
          type: PointageErrorType.queryError,
          message: 'Impossible de charger les sites de cette zone',
          technicalDetails: 'Erreur lors du chargement des sites: $e',
        );
        _isLoadingSites = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PointageColors.primary,
              onPrimary: Colors.white,
              surface: PointageColors.surface,
              onSurface: PointageColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PointageColors.primary,
              onPrimary: Colors.white,
              surface: PointageColors.surface,
              onSurface: PointageColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String? _validateInputs() {
    if (_selectedDate == null) {
      return 'Veuillez sélectionner une date';
    }
    if (_selectedTime == null) {
      return 'Veuillez sélectionner une heure';
    }
    if (_selectedZone == null) {
      return 'Veuillez sélectionner une zone';
    }
    if (_selectedSites.isEmpty) {
      return 'Veuillez sélectionner au moins un site';
    }
    return null;
  }

  Future<void> _savePointings() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      setState(() {
        _error = PointageException(
          type: PointageErrorType.invalidInput,
          message: validationError,
        );
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      // Combine date and time
      final pointingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create a pointing for each selected site
      for (final site in _selectedSites) {
        final pointing = PointingZone(
          zoneMember: widget.zoneMember,
          site: site,
          date: pointingDateTime,
          latlng: site.latLng,
          distance: 0,
        );

        await _pointingService.add(pointing);
      }

      if (!mounted) return;

      // Show success message
      SuccessSnackbar.show(
        context,
        message: '${_selectedSites.length} pointage(s) enregistré(s) avec succès',
        icon: Icons.check_circle,
      );

      // Close dialog
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = PointageException(
          type: PointageErrorType.queryError,
          message: 'Impossible d\'enregistrer les pointages',
          technicalDetails: 'Erreur lors de l\'enregistrement: $e',
        );
        _isSaving = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      title: 'Pointage manuel - ${widget.zoneMember.firstName} ${widget.zoneMember.lastName}',
      maxWidth: 800,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error display
          if (_error != null) ...[
            ErrorDisplay(
              exception: _error,
              compact: true,
            ),
            const SizedBox(height: PointageSpacing.md),
          ],

          // Date selection
        const  Text(
            'Date et heure',
            style: PointageTextStyles.label,
          ),
          const SizedBox(height: PointageSpacing.sm),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: PointageBorderRadius.medium,
                  child: Container(
                    padding: const EdgeInsets.all(PointageSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: PointageColors.divider),
                      borderRadius: PointageBorderRadius.medium,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: PointageIconSizes.sm,
                          color: PointageColors.primary,
                        ),
                        const SizedBox(width: PointageSpacing.sm),
                        Text(
                          _selectedDate != null
                              ? _formatDate(_selectedDate!)
                              : 'Sélectionner une date',
                          style: PointageTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  borderRadius: PointageBorderRadius.medium,
                  child: Container(
                    padding: const EdgeInsets.all(PointageSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: PointageColors.divider),
                      borderRadius: PointageBorderRadius.medium,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: PointageIconSizes.sm,
                          color: PointageColors.primary,
                        ),
                        const SizedBox(width: PointageSpacing.sm),
                        Text(
                          _selectedTime != null
                              ? _formatTime(_selectedTime!)
                              : 'Sélectionner une heure',
                          style: PointageTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: PointageSpacing.lg),

          // Zone selection
          Text(
            'Zone',
            style: PointageTextStyles.label,
          ),
          const SizedBox(height: PointageSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PointageSpacing.md,
              vertical: PointageSpacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: PointageColors.divider),
              borderRadius: PointageBorderRadius.medium,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Zone>(
                value: _selectedZone,
                isExpanded: true,
                hint: const Text('Sélectionner une zone'),
                items: widget.zoneMember.zone != null
                    ? [
                        DropdownMenuItem(
                          value: widget.zoneMember.zone,
                          child: Text(widget.zoneMember.zone!.name),
                        ),
                      ]
                    : [],
                onChanged: (zone) {
                  if (zone != null) {
                    setState(() {
                      _selectedZone = zone;
                    });
                    _loadSitesForZone(zone);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: PointageSpacing.lg),

          // Sites selection
          if (_selectedZone != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sites visités dans ${_selectedZone!.name}',
                  style: PointageTextStyles.label,
                ),
                if (_sitesInZone.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedSites.length == _filteredSites.length) {
                          // Remove all filtered sites
                          _selectedSites.removeAll(_filteredSites);
                        } else {
                          // Add all filtered sites
                          _selectedSites.addAll(_filteredSites);
                        }
                      });
                    },
                    child: Text(
                      _selectedSites.length == _filteredSites.length && _filteredSites.isNotEmpty
                          ? 'Tout désélectionner'
                          : 'Tout sélectionner',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: PointageSpacing.sm),

            // Search bar for sites
            if (_sitesInZone.isNotEmpty) ...[
              TextField(
                controller: _searchController,
                decoration: PointageInputDecorations.standard(
                  hintText: 'Rechercher un site par nom ou code...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: PointageSpacing.sm),
            ],

            if (_isLoadingSites)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(PointageSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_sitesInZone.isEmpty)
              Container(
                padding: const EdgeInsets.all(PointageSpacing.lg),
                decoration: BoxDecoration(
                  color: PointageColors.background,
                  borderRadius: PointageBorderRadius.medium,
                ),
                child: const Center(
                  child: Text(
                    'Aucun site trouvé dans cette zone',
                    style: PointageTextStyles.body2,
                  ),
                ),
              )
            else if (_filteredSites.isEmpty)
              Container(
                padding: const EdgeInsets.all(PointageSpacing.lg),
                decoration: BoxDecoration(
                  color: PointageColors.background,
                  borderRadius: PointageBorderRadius.medium,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: PointageSpacing.sm),
                      const Text(
                        'Aucun site ne correspond à votre recherche',
                        style: PointageTextStyles.body2,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  border: Border.all(color: PointageColors.divider),
                  borderRadius: PointageBorderRadius.medium,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredSites.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: PointageColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final site = _filteredSites[index];
                    final isSelected = _selectedSites.contains(site);

                    return CheckboxListTile(
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
                      title: Text(
                        site.name,
                        style: PointageTextStyles.body2,
                      ),
                      subtitle: Text(
                        site.codeSite,
                        style: PointageTextStyles.caption,
                      ),
                      activeColor: PointageColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),

            const SizedBox(height: PointageSpacing.md),

            // Selected sites counter with details
            Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                color: _selectedSites.isEmpty
                    ? PointageColors.error.withValues(alpha: 0.1)
                    : PointageColors.success.withValues(alpha: 0.1),
                borderRadius: PointageBorderRadius.medium,
                border: Border.all(
                  color: _selectedSites.isEmpty
                      ? PointageColors.error
                      : PointageColors.success,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedSites.isEmpty ? Icons.warning : Icons.check_circle,
                        size: PointageIconSizes.sm,
                        color: _selectedSites.isEmpty
                            ? PointageColors.error
                            : PointageColors.success,
                      ),
                      const SizedBox(width: PointageSpacing.sm),
                      Text(
                        '${_selectedSites.length} site(s) sélectionné(s)',
                        style: PointageTextStyles.body2.copyWith(
                          color: _selectedSites.isEmpty
                              ? PointageColors.error
                              : PointageColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_searchQuery.isNotEmpty && _sitesInZone.isNotEmpty) ...[
                    const SizedBox(height: PointageSpacing.xs),
                    Text(
                      '${_filteredSites.length} site(s) affiché(s) sur ${_sitesInZone.length}',
                      style: PointageTextStyles.caption.copyWith(
                        color: PointageColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        DialogAction(
          label: 'Annuler',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogAction(
          label: _isSaving
              ? 'Enregistrement...'
              : 'Enregistrer ${_selectedSites.length} pointage(s)',
          isPrimary: true,
          onPressed: _isSaving || _selectedSites.isEmpty ? () {} : _savePointings,
        ),
      ],
    );
  }
}
