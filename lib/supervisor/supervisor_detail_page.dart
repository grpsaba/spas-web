import 'package:flutter/material.dart';

import '../administration/home.dart';
import '../liste_selection_pages/supervisor_search_dialog.dart';
import '../model.dart';
import '../pointage_redesign/presentation/design_system.dart';
import '../services/access_control.dart';
import '../services/loading.dart';
import '../services/site.dart';
import 'supervisor_form.dart';

class SupervisorDetailPage extends StatefulWidget {
  const SupervisorDetailPage({
    super.key,
    required this.supervisor,
  });

  final Supervisor supervisor;

  @override
  State<SupervisorDetailPage> createState() => _SupervisorDetailPageState();
}

class _SupervisorDetailPageState extends State<SupervisorDetailPage> {
  late Supervisor _supervisor;

  @override
  void initState() {
    super.initState();
    _supervisor = widget.supervisor;
  }

  Future<List<Site>> _loadSites() {
    return SiteService().allBySupervisor(_supervisor);
  }

  Future<void> _openSiteMigrationDialog() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _SupervisorSiteMigrationDialog(
        sourceSupervisor: _supervisor,
      ),
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  String _pointageTypeLabel(String value) {
    switch (value) {
      case 'jour':
        return 'Jour';
      case 'nuit':
        return 'Nuit';
      case 'jour_nuit':
      case 'jour-nuit':
      case 'jour/nuit':
        return 'Jour / Nuit';
      default:
        return 'Non défini';
    }
  }

  Color _pointageTypeColor(String value) {
    switch (value) {
      case 'jour':
        return PointageColors.warning;
      case 'nuit':
        return const Color(0xFF455A64);
      case 'jour_nuit':
      case 'jour-nuit':
      case 'jour/nuit':
        return PointageColors.success;
      default:
        return PointageColors.textSecondary;
    }
  }

  Widget _buildHeader() {
    final fullName = '${_supervisor.firstName} ${_supervisor.lastName}'.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: PointageColors.primary.withValues(alpha: 0.15),
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PointageColors.primary,
              ),
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: PointageTextStyles.headline4),
                const SizedBox(height: PointageSpacing.xs),
                Text('Code: ${_supervisor.code}',
                    style: PointageTextStyles.body2),
                const SizedBox(height: PointageSpacing.xs),
                Text(
                  _supervisor.department?.label ?? 'Département non défini',
                  style: PointageTextStyles.caption,
                ),
              ],
            ),
          ),
          if (AccessControl.canAdd(ModuleName.SITE) ||
              AccessControl.canValidate(ModuleName.SITE)) ...[
            OutlinedButton.icon(
              style: PointageButtonStyles.outlined,
              onPressed: _openSiteMigrationDialog,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Migrer des sites'),
            ),
            const SizedBox(width: PointageSpacing.md),
          ],
          Chip(
            backgroundColor: (_supervisor.actif ?? false)
                ? PointageColors.success
                : PointageColors.error,
            label: Text(
              (_supervisor.actif ?? false) ? 'Actif' : 'Inactif',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSitesTab() {
    return FutureBuilder<List<Site>>(
      future: _loadSites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Loading(size: 48, inline: false));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: PointageColors.error),
                const SizedBox(height: PointageSpacing.sm),
                Text('Erreur de chargement des sites: ${snapshot.error}'),
                const SizedBox(height: PointageSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: PointageButtonStyles.outlined,
                ),
              ],
            ),
          );
        }

        final sites = snapshot.data ?? [];
        if (sites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_city_outlined,
                    color: PointageColors.textSecondary),
                SizedBox(height: PointageSpacing.sm),
                Text('Aucun site affecté à ce superviseur'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(PointageSpacing.md),
          itemCount: sites.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: PointageSpacing.sm),
          itemBuilder: (context, index) {
            final site = sites[index];
            final badgeLabel = _pointageTypeLabel(site.pointageType);
            final badgeColor = _pointageTypeColor(site.pointageType);

            return Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: PointageCardDecorations.standard,
              child: Row(
                children: [
                  const Icon(Icons.business, color: PointageColors.primary),
                  const SizedBox(width: PointageSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.name, style: PointageTextStyles.label),
                        const SizedBox(height: PointageSpacing.xs),
                        Text('Code: ${site.codeSite}',
                            style: PointageTextStyles.caption),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: badgeColor,
                    label: Text(
                      badgeLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 4,
      title: 'Détail superviseur',
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.all(PointageSpacing.md),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: PointageSpacing.md),
              Container(
                decoration: PointageCardDecorations.outlined,
                child: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.badge_outlined), text: 'Informations'),
                    Tab(
                        icon: Icon(Icons.location_city_outlined),
                        text: 'Sites'),
                  ],
                ),
              ),
              const SizedBox(height: PointageSpacing.md),
              Expanded(
                child: TabBarView(
                  children: [
                    AddSupervisor(
                      supervisor: _supervisor,
                      embedded: true,
                      closeAfterSubmit: false,
                      onChanged: () => setState(() {}),
                    ),
                    _buildSitesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteMigrationOption {
  const _SiteMigrationOption({
    required this.site,
    required this.slot,
  });

  final Site site;
  final SiteSupervisorSlot slot;

  String get key => '${site.UID}:${slot.name}';

  bool conflictsWith(Supervisor supervisor) {
    switch (slot) {
      case SiteSupervisorSlot.primary:
        return site.supervisor_2?.UID == supervisor.UID;
      case SiteSupervisorSlot.secondary:
        return site.supervisor?.UID == supervisor.UID;
    }
  }

  String otherSupervisorName() {
    final supervisor = slot == SiteSupervisorSlot.primary
        ? site.supervisor_2
        : site.supervisor;
    if (supervisor == null) return 'Aucun';
    return _supervisorName(supervisor);
  }
}

class _SupervisorSiteMigrationDialog extends StatefulWidget {
  const _SupervisorSiteMigrationDialog({
    required this.sourceSupervisor,
  });

  final Supervisor sourceSupervisor;

  @override
  State<_SupervisorSiteMigrationDialog> createState() =>
      _SupervisorSiteMigrationDialogState();
}

class _SupervisorSiteMigrationDialogState
    extends State<_SupervisorSiteMigrationDialog> {
  final SiteService _siteService = SiteService();
  final Set<String> _selectedKeys = <String>{};

  List<_SiteMigrationOption> _options = <_SiteMigrationOption>[];
  Supervisor? _targetSupervisor;
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final sites = await _siteService.allAssignedToSupervisor(
        widget.sourceSupervisor,
      );
      final options = <_SiteMigrationOption>[];

      for (final site in sites) {
        if (site.supervisor?.UID == widget.sourceSupervisor.UID) {
          options.add(
            _SiteMigrationOption(
              site: site,
              slot: SiteSupervisorSlot.primary,
            ),
          );
        }
        if (site.supervisor_2?.UID == widget.sourceSupervisor.UID) {
          options.add(
            _SiteMigrationOption(
              site: site,
              slot: SiteSupervisorSlot.secondary,
            ),
          );
        }
      }

      options.sort((a, b) => a.site.name.compareTo(b.site.name));

      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusIsError = true;
        _statusMessage = 'Chargement impossible: $error';
      });
    }
  }

  Future<void> _selectTargetSupervisor() async {
    final selected = await showDialog<Supervisor>(
      context: context,
      builder: (pickerContext) {
        return AlertDialog(
          alignment: Alignment.center,
          contentPadding: EdgeInsets.zero,
          content: SupervisorSearchDialog(
            onSelected: (supervisor) {
              Navigator.of(pickerContext).pop(supervisor);
            },
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    if (selected.UID == widget.sourceSupervisor.UID) {
      setState(() {
        _statusIsError = true;
        _statusMessage =
            'Choisissez un superviseur different du superviseur source.';
      });
      return;
    }

    if (selected.actif != true) {
      setState(() {
        _statusIsError = true;
        _statusMessage = 'Le nouveau superviseur doit etre actif.';
      });
      return;
    }

    setState(() {
      _targetSupervisor = selected;
      _selectedKeys.removeWhere((key) {
        final option = _optionForKey(key);
        return option != null && option.conflictsWith(selected);
      });
      _statusMessage = null;
      _statusIsError = false;
    });
  }

  _SiteMigrationOption? _optionForKey(String key) {
    for (final option in _options) {
      if (option.key == key) return option;
    }
    return null;
  }

  Future<void> _saveMigration() async {
    final target = _targetSupervisor;
    if (target == null) {
      setState(() {
        _statusIsError = true;
        _statusMessage = 'Choisissez le nouveau superviseur.';
      });
      return;
    }

    final selectedOptions = _options
        .where((option) => _selectedKeys.contains(option.key))
        .toList(growable: false);

    if (selectedOptions.isEmpty) {
      setState(() {
        _statusIsError = true;
        _statusMessage = 'Selectionnez au moins un site a migrer.';
      });
      return;
    }

    final conflicts = selectedOptions
        .where((option) => option.conflictsWith(target))
        .toList(growable: false);

    if (conflicts.isNotEmpty) {
      setState(() {
        _statusIsError = true;
        _statusMessage =
            'Certains sites ont deja ce superviseur dans l autre role.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _statusIsError = false;
      _statusMessage = 'Migration en cours...';
    });

    final migrations = selectedOptions
        .map(
          (option) => SiteSupervisorMigration(
            site: option.site,
            slot: option.slot,
          ),
        )
        .toList(growable: false);

    try {
      await _siteService.migrateSupervisorSites(
        targetSupervisor: target,
        migrations: migrations,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _changed = true;
        _statusIsError = false;
        _statusMessage =
            '${migrations.length} affectation(s) migree(s) vers ${_supervisorName(target)}.';
        _options = _options
            .where((option) => !_selectedKeys.contains(option.key))
            .toList(growable: false);
        _selectedKeys.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _statusIsError = true;
        _statusMessage = 'Migration impossible: $error';
      });
    }
  }

  bool get _canSave =>
      !_saving && _targetSupervisor != null && _selectedKeys.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.of(context).size.height * 0.72;

    return AlertDialog(
      title: const Text('Migration des sites'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SizedBox(
        width: 780,
        height: dialogHeight,
        child: _loading
            ? Center(child: Loading(size: 48, inline: false))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: PointageSpacing.sm),
                  _buildStatus(),
                  const SizedBox(height: PointageSpacing.sm),
                  Expanded(child: _buildOptionsList()),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(_changed),
          child: const Text('Fermer'),
        ),
        ElevatedButton.icon(
          style: PointageButtonStyles.primary,
          onPressed: _canSave ? _saveMigration : null,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle),
          label: const Text('Migrer'),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final selectedCount = _selectedKeys.length;

    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: PointageCardDecorations.outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sourceInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Source', style: PointageTextStyles.caption),
              Text(
                _supervisorName(widget.sourceSupervisor),
                style: PointageTextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: PointageSpacing.xs),
              Text(
                '$selectedCount affectation(s) selectionnee(s)',
                style: PointageTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          Widget targetButton() {
            return OutlinedButton.icon(
              style: PointageButtonStyles.outlined,
              onPressed: _saving ? null : _selectTargetSupervisor,
              icon: const Icon(Icons.person_search),
              label: Text(
                _targetSupervisor == null
                    ? 'Choisir le nouveau superviseur'
                    : _supervisorName(_targetSupervisor!),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sourceInfo,
                const SizedBox(height: PointageSpacing.sm),
                targetButton(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: sourceInfo),
              const SizedBox(width: PointageSpacing.md),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: targetButton(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatus() {
    final message = _statusMessage;
    if (message == null) return const SizedBox.shrink();

    final color =
        _statusIsError ? PointageColors.error : PointageColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          if (_saving)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              _statusIsError ? Icons.error_outline : Icons.check_circle,
              color: color,
              size: 18,
            ),
          const SizedBox(width: PointageSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList() {
    if (_options.isEmpty) {
      return const Center(
        child: Text('Aucune affectation directe a migrer.'),
      );
    }

    return ListView.separated(
      itemCount: _options.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final option = _options[index];
        final target = _targetSupervisor;
        final hasConflict = target != null && option.conflictsWith(target);
        final selected = _selectedKeys.contains(option.key);

        return CheckboxListTile(
          value: selected && !hasConflict,
          onChanged: _saving || hasConflict
              ? null
              : (value) {
                  setState(() {
                    if (value == true) {
                      _selectedKeys.add(option.key);
                    } else {
                      _selectedKeys.remove(option.key);
                    }
                    _statusMessage = null;
                    _statusIsError = false;
                  });
                },
          secondary: CircleAvatar(
            backgroundColor: hasConflict
                ? PointageColors.error.withValues(alpha: 0.12)
                : PointageColors.primary.withValues(alpha: 0.12),
            child: Icon(
              hasConflict ? Icons.block : Icons.business,
              color:
                  hasConflict ? PointageColors.error : PointageColors.primary,
            ),
          ),
          title: Text(option.site.name),
          subtitle: Text(
            hasConflict
                ? 'Conflit: le nouveau superviseur est deja ${option.otherSupervisorName()}'
                : '${option.slot.label} sera remplace. Autre role: ${option.otherSupervisorName()}',
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}

String _supervisorName(Supervisor supervisor) {
  final fullName = '${supervisor.firstName} ${supervisor.lastName}'.trim();
  return fullName.isEmpty ? supervisor.code : fullName;
}
