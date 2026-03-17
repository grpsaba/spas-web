import 'package:flutter/material.dart';

import '../administration/home.dart';
import '../model.dart';
import '../pointage_redesign/presentation/design_system.dart';
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
