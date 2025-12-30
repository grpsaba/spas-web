import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../administration/home.dart';
import '../model.dart';
import '../services/zoneMember.dart';
import '../services/pointerZone.dart';
import '../services/site.dart';
import '../pointage_redesign/presentation/design_system.dart';
import '../pointage_redesign/presentation/widgets/success_snackbar.dart';
import '../pointage_redesign/presentation/widgets/error_display.dart';
import '../pointage_redesign/models/pointage_exception.dart';

/// Dedicated page for manual zone pointing
/// Replaces the dialog-based approach with a full page experience
class ManualZonePointingPage extends StatefulWidget {
  const ManualZonePointingPage({super.key});

  @override
  State<ManualZonePointingPage> createState() => _ManualZonePointingPageState();
}

class _ManualZonePointingPageState extends State<ManualZonePointingPage> {
  final ZoneMemberService _zoneMemberService = ZoneMemberService();
  final SiteService _siteService = SiteService();
  final PointingZoneService _pointingService = PointingZoneService();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  ZoneMember? _selectedZoneMember;
  
  // Pointing form state
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Site> _sitesInZone = [];
  final Set<Site> _selectedSites = {};
  bool _isLoadingSites = false;
  bool _isSaving = false;
  PointageException? _error;
  String _siteSearchQuery = '';
  final TextEditingController _siteSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _siteSearchController.dispose();
    super.dispose();
  }


  List<Site> get _filteredSites {
    if (_siteSearchQuery.isEmpty) return _sitesInZone;
    
    final query = _siteSearchQuery.toLowerCase();
    return _sitesInZone.where((site) {
      return site.name.toLowerCase().contains(query) ||
          site.codeSite.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadSitesForZoneMember(ZoneMember zoneMember) async {
    if (zoneMember.zone == null) return;
    
    setState(() {
      _isLoadingSites = true;
      _error = null;
      _selectedSites.clear();
      _siteSearchQuery = '';
      _siteSearchController.clear();
    });

    try {
      final sites = await _siteService.allSitesByZone(zoneMember.zone!);
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

  void _selectZoneMember(ZoneMember zoneMember) {
    setState(() {
      _selectedZoneMember = zoneMember;
      _error = null;
    });
    _loadSitesForZoneMember(zoneMember);
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
    if (_selectedZoneMember == null) {
      return 'Veuillez sélectionner un chef de zone';
    }
    if (_selectedZoneMember!.zone == null) {
      return 'Le chef de zone n\'a pas de zone assignée';
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
          zoneMember: _selectedZoneMember,
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

      // Reset form
      setState(() {
        _selectedSites.clear();
        _isSaving = false;
      });
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
    return PageModel(
      pageIndex: 16,
      title: "Pointage manuel - Chefs de zone",
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: Zone member list with search
          Expanded(
            flex: 1,
            child: _buildZoneMemberList(),
          ),
          
          // Right panel: Pointing form (shown when member selected)
          Expanded(
            flex: 2,
            child: _buildPointingForm(),
          ),
        ],
      ),
    );
  }


  Widget _buildZoneMemberList() {
    return Container(
      margin: const EdgeInsets.all(PointageSpacing.md),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              color: PointageColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(PointageSpacing.sm),
                  decoration: BoxDecoration(
                    color: PointageColors.primary,
                    borderRadius: PointageBorderRadius.small,
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: PointageSpacing.sm),
                const Expanded(
                  child: Text(
                    'Chefs de zone',
                    style: PointageTextStyles.headline4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/chefszone'),
                  tooltip: 'Retour à la liste',
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(PointageSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: PointageInputDecorations.standard(
                hintText: 'Rechercher un chef de zone...',
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
          ),
          
          // Zone member list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _zoneMemberService.all(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs
                    .map((e) => jsonDecode(jsonEncode(e.data())))
                    .toList();
                final allMembers = docs?.map((e) => ZoneMember.fromJson(e)).toList() ?? [];
                
                // Filter active members with zones
                var activeMembers = allMembers
                    .where((zm) => zm.actif == true && zm.zone != null)
                    .toList();
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  activeMembers = activeMembers.where((member) {
                    return member.firstName.toLowerCase().contains(query) ||
                        member.lastName.toLowerCase().contains(query) ||
                        member.code.toLowerCase().contains(query) ||
                        (member.zone?.name.toLowerCase().contains(query) ?? false);
                  }).toList();
                }

                if (activeMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: PointageSpacing.md),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucun chef de zone trouvé'
                              : 'Aucun chef de zone actif disponible',
                          style: PointageTextStyles.body2.copyWith(
                            color: PointageColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: PointageSpacing.sm),
                  itemCount: activeMembers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: PointageSpacing.xs),
                  itemBuilder: (context, index) {
                    final zoneMember = activeMembers[index];
                    return _ZoneMemberListItem(
                      zoneMember: zoneMember,
                      isSelected: _selectedZoneMember?.UID == zoneMember.UID,
                      onTap: () => _selectZoneMember(zoneMember),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPointingForm() {
    return Container(
      margin: const EdgeInsets.all(PointageSpacing.md),
      decoration: PointageCardDecorations.standard,
      child: _selectedZoneMember == null
          ? _buildEmptyState()
          : _buildFormContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(PointageSpacing.xl),
            decoration: BoxDecoration(
              color: PointageColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_location_alt,
              size: 64,
              color: PointageColors.primary,
            ),
          ),
          const SizedBox(height: PointageSpacing.lg),
          Text(
            'Sélectionnez un chef de zone',
            style: PointageTextStyles.headline3.copyWith(
              color: PointageColors.textSecondary,
            ),
          ),
          const SizedBox(height: PointageSpacing.sm),
          Text(
            'Choisissez un chef de zone dans la liste à gauche\npour effectuer un pointage manuel',
            textAlign: TextAlign.center,
            style: PointageTextStyles.body2.copyWith(
              color: PointageColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with selected zone member info
          _buildSelectedMemberHeader(),
          
          const SizedBox(height: PointageSpacing.lg),
          
          // Error display
          if (_error != null) ...[
            ErrorDisplay(
              exception: _error,
              compact: true,
            ),
            const SizedBox(height: PointageSpacing.md),
          ],
          
          // Date and time selection
          _buildDateTimeSection(),
          
          const SizedBox(height: PointageSpacing.lg),
          
          // Sites selection
          _buildSitesSection(),
          
          const SizedBox(height: PointageSpacing.lg),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSelectedMemberHeader() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: PointageColors.success.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: PointageColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PointageColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedZoneMember!.firstName} ${_selectedZoneMember!.lastName}',
                  style: PointageTextStyles.headline4,
                ),
                const SizedBox(height: PointageSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: PointageColors.textSecondary,
                    ),
                    const SizedBox(width: PointageSpacing.xs),
                    Text(
                      _selectedZoneMember!.zone?.name ?? 'Aucune zone',
                      style: PointageTextStyles.body2.copyWith(
                        color: PointageColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedZoneMember = null;
                _sitesInZone.clear();
                _selectedSites.clear();
                _error = null;
              });
            },
            tooltip: 'Désélectionner',
          ),
        ],
      ),
    );
  }


  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date et heure du pointage',
          style: PointageTextStyles.label,
        ),
        const SizedBox(height: PointageSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _DateTimeSelector(
                icon: Icons.calendar_today,
                label: _selectedDate != null
                    ? _formatDate(_selectedDate!)
                    : 'Sélectionner une date',
                onTap: _selectDate,
              ),
            ),
            const SizedBox(width: PointageSpacing.md),
            Expanded(
              child: _DateTimeSelector(
                icon: Icons.access_time,
                label: _selectedTime != null
                    ? _formatTime(_selectedTime!)
                    : 'Sélectionner une heure',
                onTap: _selectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sites visités dans ${_selectedZoneMember?.zone?.name ?? "la zone"}',
              style: PointageTextStyles.label,
            ),
            if (_sitesInZone.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedSites.length == _filteredSites.length) {
                      _selectedSites.removeAll(_filteredSites);
                    } else {
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
            controller: _siteSearchController,
            decoration: PointageInputDecorations.standard(
              hintText: 'Rechercher un site par nom ou code...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _siteSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _siteSearchController.clear();
                          _siteSearchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _siteSearchQuery = value;
              });
            },
          ),
          const SizedBox(height: PointageSpacing.sm),
        ],
        
        // Sites list
        _buildSitesList(),
        
        const SizedBox(height: PointageSpacing.md),
        
        // Selected sites counter
        _buildSelectedSitesCounter(),
      ],
    );
  }

  Widget _buildSitesList() {
    if (_isLoadingSites) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: PointageColors.divider),
          borderRadius: PointageBorderRadius.medium,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_sitesInZone.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: PointageColors.background,
          borderRadius: PointageBorderRadius.medium,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: PointageSpacing.sm),
              const Text(
                'Aucun site trouvé dans cette zone',
                style: PointageTextStyles.body2,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredSites.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: PointageColors.background,
          borderRadius: PointageBorderRadius.medium,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return Container(
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
    );
  }


  Widget _buildSelectedSitesCounter() {
    return Container(
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
          if (_siteSearchQuery.isNotEmpty && _sitesInZone.isNotEmpty) ...[
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/chefszone'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour'),
          style: PointageButtonStyles.outlined,
        ),
        const SizedBox(width: PointageSpacing.md),
        ElevatedButton.icon(
          onPressed: _isSaving || _selectedSites.isEmpty ? null : _savePointings,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(
            _isSaving
                ? 'Enregistrement...'
                : 'Enregistrer ${_selectedSites.length} pointage(s)',
          ),
          style: PointageButtonStyles.primary,
        ),
      ],
    );
  }
}

/// Zone member list item with glass smooth hover effect
class _ZoneMemberListItem extends StatefulWidget {
  final ZoneMember zoneMember;
  final bool isSelected;
  final VoidCallback onTap;

  const _ZoneMemberListItem({
    required this.zoneMember,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ZoneMemberListItem> createState() => _ZoneMemberListItemState();
}

class _ZoneMemberListItemState extends State<_ZoneMemberListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.all(PointageSpacing.md),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? PointageColors.primary.withValues(alpha: 0.15)
                : _isHovered
                    ? PointageColors.hover
                    : Colors.transparent,
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(
              color: widget.isSelected
                  ? PointageColors.primary
                  : _isHovered
                      ? PointageColors.divider
                      : Colors.transparent,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: _isHovered || widget.isSelected ? PointageShadows.sm : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: PointageAnimations.fast,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? PointageColors.primary
                      : PointageColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: widget.isSelected ? Colors.white : PointageColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.zoneMember.firstName} ${widget.zoneMember.lastName}',
                      style: PointageTextStyles.body2.copyWith(
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: PointageColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.zoneMember.zone?.name ?? 'Aucune zone',
                            style: PointageTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_circle,
                  color: PointageColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date/Time selector widget with glass smooth hover effect
class _DateTimeSelector extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeSelector({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_DateTimeSelector> createState() => _DateTimeSelectorState();
}

class _DateTimeSelectorState extends State<_DateTimeSelector> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.all(PointageSpacing.md),
          decoration: BoxDecoration(
            color: _isHovered ? PointageColors.hover : Colors.transparent,
            border: Border.all(
              color: _isHovered ? PointageColors.primary : PointageColors.divider,
              width: _isHovered ? 2 : 1,
            ),
            borderRadius: PointageBorderRadius.medium,
            boxShadow: _isHovered ? PointageShadows.sm : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: PointageIconSizes.sm,
                color: PointageColors.primary,
              ),
              const SizedBox(width: PointageSpacing.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: PointageTextStyles.body2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
