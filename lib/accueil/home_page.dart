import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:spas_web/administration/home.dart';
import 'package:spas_web/accueil/site_pointing_staus_list.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/error_logs/providers/error_log_provider.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/providers/home_provider.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/note.dart';
import 'package:spas_web/services/pointerSite.dart';
import 'package:spas_web/zone/progression_pointage_zone.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeProvider _homeProvider;
  final manager = AuthService.currentManager;

  @override
  void initState() {
    super.initState();
    _homeProvider = Provider.of<HomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  Future<void> _initializeData() async {
    if (_homeProvider.needsRefresh) {
      await _homeProvider.loadData();
    }
    if (mounted) {
      context.read<ErrorLogProvider>().loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        return PageModel(
          title: 'SPAS GROUPE SABA',
          pageIndex: 0,
          child: RefreshIndicator(
            color: _HomeColors.primary,
            onRefresh: () async {
              await provider.refresh();
              if (!context.mounted) return;
              await context.read<ErrorLogProvider>().loadStats();
            },
            child: _buildContent(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeProvider provider) {
    if (provider.hasError) return _ErrorState(provider: provider);
    if (provider.isLoading && provider.allSites.isEmpty) {
      return const _LoadingState();
    }
    return _buildDashboard(context, provider);
  }

  Widget _buildDashboard(BuildContext context, HomeProvider provider) {
    final width = MediaQuery.sizeOf(context).width;
    final contentPadding = width >= 1400
        ? 32.0
        : width >= 900
            ? 24.0
            : 16.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(contentPadding, 24, contentPadding, 32),
      children: [
        _buildHeader(context, provider),
        const SizedBox(height: 28),
        _buildSectionTitle(
          title: 'Vue d’ensemble',
          subtitle: 'Les chiffres clés de votre organisation',
        ),
        const SizedBox(height: 14),
        _buildStatsGrid(provider),
        const SizedBox(height: 30),
        _buildSectionTitle(
          title: 'Progression des pointages',
          subtitle:
              'Suivi journalier des superviseurs et mensuel des chefs de zone',
        ),
        const SizedBox(height: 14),
        _buildPointingProgressGrid(provider),
        const SizedBox(height: 30),
        _buildMainGrid(context),
        const SizedBox(height: 30),
        _buildSectionTitle(
          title: 'Suivi opérationnel',
          subtitle: 'Les sites actifs disponibles aujourd’hui',
        ),
        const SizedBox(height: 14),
        _buildOperationalGrid(provider),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, HomeProvider provider) {
    final managerName = manager?.lastName.trim();
    final greeting = managerName == null || managerName.isEmpty
        ? 'Bonjour'
        : 'Bonjour, $managerName';
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: _HomeColors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voici l’état de SPAS GROUPE SABA pour le ${_formatDate(today)}.',
              style: const TextStyle(
                color: _HomeColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderAction(
              tooltip: 'Actualiser les données',
              icon: provider.isLoading ? Icons.sync : Icons.refresh,
              onPressed: provider.isLoading ? null : provider.refresh,
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => context.go('/pointages'),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Voir les pointages'),
              style: FilledButton.styleFrom(
                backgroundColor: _HomeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [content, const SizedBox(height: 18), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: content), actions],
        );
      },
    );
  }

  Widget _buildStatsGrid(HomeProvider provider) {
    final stats = [
      _StatData(
        label: 'Sites actifs',
        value: provider.activeSites,
        detail: '${provider.totalSites} sites au total',
        icon: Icons.location_on_outlined,
        color: _HomeColors.green,
      ),
      _StatData(
        label: 'Sites inactifs',
        value: provider.inactiveSites,
        detail: 'À vérifier si nécessaire',
        icon: Icons.location_off_outlined,
        color: _HomeColors.orange,
      ),
      _StatData(
        label: 'Superviseurs actifs',
        value: provider.activeSupervisors,
        detail: '${provider.supervisors.length} superviseurs au total',
        icon: Icons.supervisor_account_outlined,
        color: _HomeColors.primary,
      ),
      _StatData(
        label: 'Agents actifs',
        value: provider.activeAgents,
        detail: '${provider.agents.length} agents au total',
        icon: Icons.groups_outlined,
        color: _HomeColors.teal,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        const gap = 14.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: cardWidth,
                  child: _StatCard(data: stat),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMainGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final quickActions = _HomePanel(
          title: 'Accès rapides',
          subtitle: 'Les espaces les plus utilisés',
          child: LayoutBuilder(
            builder: (context, actionConstraints) {
              final columns = actionConstraints.maxWidth >= 520 ? 4 : 2;
              const gap = 10.0;
              final width =
                  (actionConstraints.maxWidth - gap * (columns - 1)) / columns;
              const actions = [
                _QuickActionData(
                  label: 'Pointages',
                  icon: Icons.fact_check_outlined,
                  route: '/pointages',
                  color: _HomeColors.primary,
                ),
                _QuickActionData(
                  label: 'Sites',
                  icon: Icons.business_outlined,
                  route: '/sites',
                  color: _HomeColors.green,
                ),
                _QuickActionData(
                  label: 'Utilisateurs',
                  icon: Icons.manage_accounts_outlined,
                  route: '/users',
                  color: _HomeColors.orange,
                ),
                _QuickActionData(
                  label: 'Agents',
                  icon: Icons.groups_outlined,
                  route: '/agents',
                  color: _HomeColors.teal,
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width: width,
                        child: _QuickAction(data: action),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        );

        final activity = _HomePanel(
          title: 'Aujourd’hui',
          subtitle: 'Les derniers signaux de l’application',
          child: _buildTodayActivity(context),
        );

        if (compact) {
          return Column(
            children: [quickActions, const SizedBox(height: 14), activity],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: quickActions),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: activity),
          ],
        );
      },
    );
  }

  Widget _buildPointingProgressGrid(HomeProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const panelHeight = 560.0;
        final stacked = constraints.maxWidth < 1120;
        final supervisorProgress = SitePointingListWithStatus(
          supList: provider.supervisors,
          height: panelHeight,
        );
        const zoneProgress = ZonePointageProgressionList(height: panelHeight);

        if (stacked) {
          return Column(
            children: [
              supervisorProgress,
              const SizedBox(height: 14),
              zoneProgress,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: supervisorProgress),
            const SizedBox(width: 14),
            const Expanded(child: zoneProgress),
          ],
        );
      },
    );
  }

  Widget _buildTodayActivity(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: PointingSiteService().all(),
          builder: (context, snapshot) {
            return _ActivityMetric(
              icon: Icons.fact_check_outlined,
              label: 'Pointages enregistrés',
              value: snapshot.hasError
                  ? '—'
                  : '${snapshot.data?.docs.length ?? 0}',
              color: _HomeColors.primary,
            );
          },
        ),
        const Divider(height: 22, color: _HomeColors.border),
        StreamBuilder<QuerySnapshot>(
          stream: NoteService().allNoViewedNote(),
          builder: (context, snapshot) {
            return _ActivityMetric(
              icon: Icons.sticky_note_2_outlined,
              label: 'Notes non consultées',
              value: snapshot.hasError
                  ? '—'
                  : '${snapshot.data?.docs.length ?? 0}',
              color: _HomeColors.orange,
            );
          },
        ),
        const Divider(height: 22, color: _HomeColors.border),
        Consumer<ErrorLogProvider>(
          builder: (context, errorProvider, _) {
            final ErrorLogStats stats = errorProvider.stats;
            return _ActivityMetric(
              icon: Icons.warning_amber_outlined,
              label: 'Erreurs non résolues',
              value: errorProvider.isLoading ? '…' : '${stats.unresolved}',
              color: stats.unresolved > 0 ? _HomeColors.red : _HomeColors.green,
              onTap: () => context.go('/errorlogs'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOperationalGrid(HomeProvider provider) {
    return _SitesPanel(sites: provider.sites);
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _HomeColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _HomeColors.muted, fontSize: 13),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _HomeColors {
  static const primary = Color(0xFF4657C8);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE5EAF2);
  static const green = Color(0xFF198754);
  static const orange = Color(0xFFB76E00);
  static const red = Color(0xFFD14343);
  static const teal = Color(0xFF087F8C);
  static const softSurface = Color(0xFFFBFCFE);
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _HomeColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A172033),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    color: _HomeColors.ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: _HomeColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _HomeColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08172033),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _HomeColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: _HomeColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
  });

  final String label;
  final IconData icon;
  final String route;
  final Color color;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.softSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => context.go(data.route),
        borderRadius: BorderRadius.circular(8),
        hoverColor: data.color.withValues(alpha: 0.08),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _HomeColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: data.color, size: 24),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.label,
                      style: const TextStyle(
                        color: _HomeColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: _HomeColors.muted,
                    size: 16,
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

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: _HomeColors.ink,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _HomeColors.ink,
        side: const BorderSide(color: _HomeColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _HomeColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    return onTap == null
        ? child
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: child,
            ),
          );
  }
}

class _SitesPanel extends StatelessWidget {
  const _SitesPanel({required this.sites});

  final List<Site> sites;

  @override
  Widget build(BuildContext context) {
    final visibleSites = sites.take(6).toList();
    return _HomePanel(
      title: 'Sites actifs',
      subtitle: 'Accès rapide aux sites suivis',
      child: visibleSites.isEmpty
          ? const _EmptyPanelState(label: 'Aucun site actif')
          : Column(
              children: [
                for (var index = 0; index < visibleSites.length; index++) ...[
                  _SiteRow(site: visibleSites[index]),
                  if (index != visibleSites.length - 1)
                    const Divider(height: 18, color: _HomeColors.border),
                ],
                if (sites.length > 6) ...[
                  const SizedBox(height: 14),
                  _PanelLink(
                    label: 'Voir tous les sites',
                    onTap: () => context.go('/sites'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SiteRow extends StatelessWidget {
  const _SiteRow({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/sites'),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _HomeColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.business_outlined,
                color: _HomeColors.green,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    site.zone?.name ?? site.adresse,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${site.nbAgent} agents',
              style: const TextStyle(color: _HomeColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelLink extends StatelessWidget {
  const _PanelLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_forward, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: _HomeColors.primary,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _EmptyPanelState extends StatelessWidget {
  const _EmptyPanelState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(label, style: const TextStyle(color: _HomeColors.muted)),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.provider});

  final HomeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF3C5C5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _HomeColors.red, size: 42),
            const SizedBox(height: 14),
            const Text(
              'Impossible de charger le tableau de bord',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _HomeColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _HomeColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
