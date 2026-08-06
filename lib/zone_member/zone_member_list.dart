import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/zoneMember.dart';
import '../services/pointerZone.dart';
import '../services/site.dart';
import '../pointage_redesign/presentation/widgets/success_snackbar.dart';
import '../pointage_redesign/presentation/widgets/error_display.dart';
import '../pointage_redesign/models/pointage_exception.dart';
import '../pointage_redesign/presentation/design_system.dart';
import 'manual_zone_pointing_dialog.dart';

class ZoneMemberList extends StatefulWidget {
  const ZoneMemberList({super.key});

  @override
  _ZoneMemberListState createState() => _ZoneMemberListState();
}

class _ZoneMemberListState extends State<ZoneMemberList> {
  final ZoneMemberService _service = ZoneMemberService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showManualPointingDialog(
      BuildContext context, List<ZoneMember> zoneMembers) {
    // Show dialog to select a zone member first
    final activeMembers =
        zoneMembers.where((zm) => zm.actif == true && zm.zone != null).toList();

    if (activeMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun chef de zone actif disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sélectionner un chef de zone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: activeMembers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final zoneMember = activeMembers[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => ManualZonePointingDialog(
                            zoneMember: zoneMember,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${zoneMember.firstName} ${zoneMember.lastName}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        zoneMember.zone?.name ?? 'Aucune zone',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 16,
      title: "Gestion des chefs de zone",
      child: StreamBuilder(
        stream: _service.all(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Loading(size: 64, inline: true),
            );
          }

          var docs = snapshot.data?.docs
              .map((e) => jsonDecode(jsonEncode(e.data())))
              .toList();
          var allMembers = docs?.map((e) => ZoneMember.fromJson(e)).toList() ?? [];

          // Filter members based on search
          var filteredMembers = allMembers.where((member) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return member.firstName.toLowerCase().contains(query) ||
                member.lastName.toLowerCase().contains(query) ||
                member.code.toLowerCase().contains(query) ||
                member.phone.toLowerCase().contains(query) ||
                (member.zone?.name.toLowerCase().contains(query) ?? false);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(PointageSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with actions
                _buildHeader(context, allMembers),
                const SizedBox(height: PointageSpacing.lg),
                
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: PointageSpacing.lg),
                
                // Stats cards
                _buildStatsCards(allMembers),
                const SizedBox(height: PointageSpacing.lg),
                
                // Members grid
                _buildMembersGrid(filteredMembers),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<ZoneMember> allMembers) {
    final canAdd = AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!.add;
    
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              color: PointageColors.primary.withValues(alpha: 0.1),
              borderRadius: PointageBorderRadius.medium,
            ),
            child: const Icon(
              Icons.people_outline,
              color: PointageColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chefs de zone',
                  style: PointageTextStyles.headline3,
                ),
                Text(
                  'Gérez les chefs de zone et leurs pointages',
                  style: PointageTextStyles.body2.copyWith(
                    color: PointageColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (canAdd) ...[
            _ManualPointingButton(
              onPressed: () {
                context.go('/chefszone/pointing');
              },
            ),
            const SizedBox(width: PointageSpacing.md),
            ElevatedButton.icon(
              onPressed: () {
                ZoneMember zm = ZoneMember(
                  UID: '',
                  code: '',
                  firstName: '',
                  lastName: '',
                  phone: '',
                  email: '',
                  actif: false,
                  poste: '',
                  zone: null,
                );
                context.go("/chefszone/add", extra: zm);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: PointageButtonStyles.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: PointageCardDecorations.standard,
      child: TextField(
        controller: _searchController,
        decoration: PointageInputDecorations.standard(
          hintText: 'Rechercher par nom, prénom, code, téléphone ou zone...',
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
    );
  }

  Widget _buildStatsCards(List<ZoneMember> allMembers) {
    final activeCount = allMembers.where((m) => m.actif == true).length;
    final inactiveCount = allMembers.length - activeCount;
    final zones = allMembers.where((m) => m.zone != null).map((m) => m.zone!.codeZone).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            allMembers.length.toString(),
            Icons.people,
            PointageColors.primary,
          ),
        ),
        const SizedBox(width: PointageSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Actifs',
            activeCount.toString(),
            Icons.check_circle,
            PointageColors.success,
          ),
        ),
        const SizedBox(width: PointageSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Inactifs',
            inactiveCount.toString(),
            Icons.cancel,
            PointageColors.error,
          ),
        ),
        const SizedBox(width: PointageSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Zones',
            zones.toString(),
            Icons.location_on,
            PointageColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PointageSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: PointageBorderRadius.small,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: PointageTextStyles.headline3.copyWith(color: color),
                ),
                Text(
                  label,
                  style: PointageTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersGrid(List<ZoneMember> members) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(PointageSpacing.xl),
        decoration: PointageCardDecorations.standard,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: PointageSpacing.md),
              Text(
                'Aucun chef de zone trouvé',
                style: PointageTextStyles.body1.copyWith(
                  color: PointageColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: PointageSpacing.md,
        mainAxisSpacing: PointageSpacing.md,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(members[index]);
      },
    );
  }

  Widget _buildMemberCard(ZoneMember member) {
    final canEdit = AuthService.currentManager!.profil!.getModule(ModuleName.SUPERVISEUR)!.validation;
    
    return Container(
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              color: member.actif == true 
                  ? PointageColors.success.withValues(alpha: 0.1)
                  : PointageColors.error.withValues(alpha: 0.1),
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
                    color: member.actif == true 
                        ? PointageColors.success
                        : PointageColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    member.actif == true ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: PointageSpacing.sm),
                Expanded(
                  child: Text(
                    member.actif == true ? 'Actif' : 'Inactif',
                    style: PointageTextStyles.label.copyWith(
                      color: member.actif == true 
                          ? PointageColors.success
                          : PointageColors.error,
                    ),
                  ),
                ),
                if (member.actif == true && canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      context.go("/chefszone/add", extra: member);
                    },
                    color: PointageColors.primary,
                    tooltip: 'Modifier',
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(PointageSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    '${member.firstName} ${member.lastName}',
                    style: PointageTextStyles.headline4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: PointageSpacing.xs),
                  
                  // Zone
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: PointageColors.textSecondary,
                      ),
                      const SizedBox(width: PointageSpacing.xs),
                      Expanded(
                        child: Text(
                          member.zone?.name ?? 'Aucune zone',
                          style: PointageTextStyles.body2.copyWith(
                            color: PointageColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PointageSpacing.xs),
                  
                  // Phone
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: PointageColors.textSecondary,
                      ),
                      const SizedBox(width: PointageSpacing.xs),
                      Expanded(
                        child: Text(
                          member.phone,
                          style: PointageTextStyles.body2.copyWith(
                            color: PointageColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  if (member.poste != null && member.poste!.isNotEmpty) ...[
                    const SizedBox(height: PointageSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 16,
                          color: PointageColors.textSecondary,
                        ),
                        const SizedBox(width: PointageSpacing.xs),
                        Expanded(
                          child: Text(
                            member.poste!,
                            style: PointageTextStyles.body2.copyWith(
                              color: PointageColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Footer with toggle
          if (canEdit)
            Container(
              padding: const EdgeInsets.all(PointageSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: PointageColors.divider),
                ),
              ),
              child: ZoneMemberStatut(zoneMember: member),
            ),
        ],
      ),
    );
  }
}

/// Widget for zone member status toggle
class ZoneMemberStatut extends StatefulWidget {
  final ZoneMember zoneMember;
  
  const ZoneMemberStatut({super.key, required this.zoneMember});

  @override
  _ZoneMemberStatutState createState() => _ZoneMemberStatutState();
}

class _ZoneMemberStatutState extends State<ZoneMemberStatut> {
  bool _updating = false;
  
  @override
  Widget build(BuildContext context) {
    if (_updating) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final canToggle = AuthService.currentManager!.profil!
        .getModule(ModuleName.SUPERVISEUR)!
        .validation;

    return SwitchListTile(
      value: widget.zoneMember.actif ?? false,
      onChanged: canToggle ? (value) => actifInactifAgent() : null,
      title: Text(
        widget.zoneMember.actif == true ? 'Activer' : 'Désactiver',
        style: PointageTextStyles.body2,
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeTrackColor: PointageColors.success.withValues(alpha: 0.5),
      inactiveTrackColor: PointageColors.divider,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return PointageColors.success;
        }
        return Colors.grey;
      }),
    );
  }

  void actifInactifAgent() {
    setState(() {
      _updating = true;
    });

    // Detect if we're activating the zone member (wasInactive → actif)
    final bool wasInactive = !widget.zoneMember.actif!;
    widget.zoneMember.actif = widget.zoneMember.actif! ? false : true;

    ZoneMemberService().update(widget.zoneMember).then((value) {
      setState(() {
        _updating = false;
      });

      // Activation only changes account availability. Pointings must come from
      // mobile/manual pointing flows, never from status toggles.
    }).onError((error, stackTrace) {
      setState(() {
        _updating = false;
      });
    });
  }

  /// Generate monthly pointings for a newly activated zone member
  Future<void> _generateMonthlyPointingsForZoneMember(
      ZoneMember zoneMember) async {
    // Validate that zone member has a zone assigned
    if (zoneMember.zone == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ErrorDisplay(
              exception: PointageException.invalidInput(
                message: 'Le chef de zone n\'a pas de zone assignée',
              ),
              compact: true,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Fetch all sites in the zone
      final sites = await SiteService().allSitesByZone(zoneMember.zone!);

      if (sites.isEmpty) {
        if (mounted) {
          SuccessSnackbar.show(
            context,
            message: 'Aucun site trouvé dans la zone ${zoneMember.zone!.name}',
            icon: Icons.info,
          );
        }
        return;
      }

      int totalPointingsCreated = 0;

      // Generate pointings for each day from start of month to today
      for (DateTime date = startOfMonth;
          date.isBefore(now.add(const Duration(days: 1))) &&
              date.day <= now.day;
          date = date.add(const Duration(days: 1))) {
        // Create one pointing per site per day
        for (final site in sites) {
          // Create pointing at 8:00 AM by default
          final pointingDate = DateTime(date.year, date.month, date.day, 8, 0);

          final pointing = PointingZone(
            zoneMember: zoneMember,
            site: site,
            date: pointingDate,
            latlng: site.latLng, // Use site's location
            distance: 0, // Default distance
          );

          // Add to Firebase with unique ID to avoid duplicates
          // The service uses: "${site.UID} ${date.year}-${date.month}-${date.day}"
          await PointingZoneService().add(pointing);
          totalPointingsCreated++;
        }
      }

      // Show success notification
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message:
              '$totalPointingsCreated pointage(s) généré(s) automatiquement pour ${zoneMember.firstName} ${zoneMember.lastName}',
          icon: Icons.check_circle,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      // Show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ErrorDisplay(
              exception: PointageException.unknown(
                message:
                    'Erreur lors de la génération des pointages: ${e.toString()}',
              ),
              compact: true,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}


/// Button widget for manual pointing with glass smooth hover effect
/// Uses design system styles for consistency
class _ManualPointingButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _ManualPointingButton({required this.onPressed});

  @override
  State<_ManualPointingButton> createState() => _ManualPointingButtonState();
}

class _ManualPointingButtonState extends State<_ManualPointingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.lg,
            vertical: PointageSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered 
                ? PointageColors.warning.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: PointageColors.warning,
              width: _isHovered ? 2.0 : 1.5,
            ),
            borderRadius: PointageBorderRadius.medium,
            boxShadow: _isHovered ? PointageShadows.sm : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: PointageAnimations.fast,
                transform: Matrix4.identity()
                  ..scale(_isHovered ? 1.1 : 1.0),
                child: Icon(
                  Icons.add_location_alt,
                  color: PointageColors.warning,
                  size: _isHovered ? 22 : 20,
                ),
              ),
              const SizedBox(width: PointageSpacing.sm),
              Text(
                'Pointage manuel',
                style: PointageTextStyles.button.copyWith(
                  color: PointageColors.warning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
