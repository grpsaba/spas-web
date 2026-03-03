import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/pointage_weighted_engine.dart';
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
  @override
  Widget build(BuildContext context) {
    final supervisor = widget.supervisor;

    return PageModel(
      pageIndex: 4,
      title: "Superviseur - ${supervisor.firstName} ${supervisor.lastName}",
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.all(PointageSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(supervisor: supervisor),
              const SizedBox(height: PointageSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: PointageBorderRadius.large,
                  border: Border.all(color: PointageColors.divider),
                  boxShadow: PointageShadows.sm,
                ),
                child: TabBar(
                  labelColor: PointageColors.primary,
                  unselectedLabelColor: PointageColors.textSecondary,
                  indicatorColor: PointageColors.primary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.person_outline),
                      text: "Informations",
                    ),
                    Tab(
                      icon: Icon(Icons.location_city_outlined),
                      text: "Sites",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PointageSpacing.md),
              Expanded(
                child: TabBarView(
                  children: [
                    AddSupervisor(
                      supervisor: supervisor,
                      embedded: true,
                      closeAfterSubmit: false,
                      onChanged: () {
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    _SupervisorSitesTab(supervisor: supervisor),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.supervisor});

  final Supervisor supervisor;

  @override
  Widget build(BuildContext context) {
    final departmentLabel = supervisor.department?.label ?? '-';

    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: PointageBorderRadius.large,
        border: Border.all(color: PointageColors.divider),
        boxShadow: PointageShadows.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: PointageColors.primary,
            child: Text(
              "${supervisor.firstName.isNotEmpty ? supervisor.firstName[0] : ''}${supervisor.lastName.isNotEmpty ? supervisor.lastName[0] : ''}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${supervisor.firstName} ${supervisor.lastName}",
                  style: PointageTextStyles.headline4,
                ),
                const SizedBox(height: PointageSpacing.xs),
                Text(
                  "Code: ${supervisor.code}",
                  style: PointageTextStyles.body2.copyWith(
                    color: PointageColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PointageSpacing.xs),
                Text(
                  "Département: $departmentLabel",
                  style: PointageTextStyles.body2.copyWith(
                    color: PointageColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PointageSpacing.md,
              vertical: PointageSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: (supervisor.actif ?? false)
                  ? PointageColors.success.withAlpha(32)
                  : PointageColors.error.withAlpha(32),
              borderRadius: PointageBorderRadius.extraLarge,
            ),
            child: Text(
              (supervisor.actif ?? false) ? 'Actif' : 'Inactif',
              style: PointageTextStyles.label.copyWith(
                color: (supervisor.actif ?? false)
                    ? PointageColors.success
                    : PointageColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorSitesTab extends StatefulWidget {
  const _SupervisorSitesTab({required this.supervisor});

  final Supervisor supervisor;

  @override
  State<_SupervisorSitesTab> createState() => _SupervisorSitesTabState();
}

class _SupervisorSitesTabState extends State<_SupervisorSitesTab> {
  late Future<List<Site>> _sitesFuture;

  @override
  void initState() {
    super.initState();
    _sitesFuture = _loadSites();
  }

  @override
  void didUpdateWidget(covariant _SupervisorSitesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supervisor.UID != widget.supervisor.UID) {
      _sitesFuture = _loadSites();
    }
  }

  Future<List<Site>> _loadSites() {
    return SiteService().allBySupervisor(widget.supervisor);
  }

  void _refresh() {
    setState(() {
      _sitesFuture = _loadSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: PointageBorderRadius.large,
        border: Border.all(color: PointageColors.divider),
      ),
      child: FutureBuilder<List<Site>>(
        future: _sitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Loading(
                size: 48,
                inline: false,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PointageSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: PointageColors.error),
                    const SizedBox(height: PointageSpacing.sm),
                    const Text('Erreur lors du chargement des sites.'),
                    const SizedBox(height: PointageSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: PointageButtonStyles.outlined,
                    ),
                  ],
                ),
              ),
            );
          }

          final sites = snapshot.data ?? [];
          if (sites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PointageSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      color: PointageColors.textSecondary.withAlpha(180),
                    ),
                    const SizedBox(height: PointageSpacing.sm),
                    const Text('Aucun site affecté à ce superviseur.'),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PointageSpacing.md,
                  PointageSpacing.md,
                  PointageSpacing.sm,
                  PointageSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      '${sites.length} site(s) affecté(s)',
                      style: PointageTextStyles.label,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _refresh,
                      tooltip: 'Actualiser',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(PointageSpacing.md),
                  itemCount: sites.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: PointageSpacing.sm),
                  itemBuilder: (context, index) {
                    final site = sites[index];
                    return _SiteTile(site: site);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SiteTile extends StatelessWidget {
  const _SiteTile({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: PointageColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: PointageColors.primary),
          const SizedBox(width: PointageSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name,
                  style: PointageTextStyles.label,
                ),
                const SizedBox(height: PointageSpacing.xs),
                Text(
                  'Code: ${site.codeSite} • Zone: ${site.zone?.name ?? '-'}',
                  style: PointageTextStyles.caption,
                ),
                const SizedBox(height: PointageSpacing.xs),
                Text(
                  'Téléphone: ${site.phone}',
                  style: PointageTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: PointageSpacing.sm),
          _PointingTypeBadge(type: site.pointingType),
        ],
      ),
    );
  }
}

class _PointingTypeBadge extends StatelessWidget {
  const _PointingTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final normalized = PointageWeightedEngine.normalizePointingType(type);

    late final String label;
    late final Color background;
    late final Color foreground;

    if (normalized == SitePointingType.nuit) {
      label = 'Pointage Nuit';
      background = Colors.orange.shade100;
      foreground = Colors.orange.shade900;
    } else if (normalized == SitePointingType.jourNuit) {
      label = 'Pointage Jour/Nuit';
      background = Colors.grey.shade200;
      foreground = Colors.grey.shade900;
    } else {
      label = 'Pointage Jour';
      background = Colors.blue.shade100;
      foreground = Colors.blue.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: PointageBorderRadius.extraLarge,
      ),
      child: Text(
        label,
        style: PointageTextStyles.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
