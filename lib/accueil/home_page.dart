import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spas_web/accueil/pointage_site_card.dart';
import 'package:spas_web/accueil/site_card.dart';
import 'package:spas_web/accueil/site_pointing_staus_list.dart';
import 'package:spas_web/accueil/site_staus_list.dart';
import 'package:spas_web/accueil/supervisor_card.dart';
import 'package:spas_web/accueil/tool_status_card.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/error_logs/providers/error_log_provider.dart';
import 'package:spas_web/error_logs/widgets/error_stats_card.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/providers/home_provider.dart';
import 'package:spas_web/services/agentType.dart';
import 'package:spas_web/services/authentication.dart';

import '../zone/progression_pointage_zone.dart';
import 'agent_card.dart';
import 'note_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeProvider homeProvider;
  final manager = AuthService.currentManager;

  bool isStatsHiden = false;
  List<AgentType> _agentTypes = [];
  bool _isLoadingAgentTypes = true;

  @override
  void initState() {
    super.initState();
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (homeProvider.needsRefresh) {
      await homeProvider.loadData();
    }
    _fetchAgentTypes();
    if (mounted) {
      context.read<ErrorLogProvider>().loadStats();
    }
  }

  Future<void> _fetchAgentTypes() async {
    try {
      final agentTypes = await AgentTypeService().allFuture();
      if (!mounted) return;
      setState(() {
        _agentTypes = agentTypes;
        _isLoadingAgentTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAgentTypes = false;
      });
    }
  }

  void hideStats() {
    setState(() {
      isStatsHiden = !isStatsHiden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return PageModel(
          title: 'SPAS GROUPE SABA',
          pageIndex: 0,
          child: RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: _buildContent(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeProvider provider) {
    if (provider.hasError) {
      return _buildErrorState(provider);
    }

    if (provider.isLoading && provider.sites.isEmpty) {
      return _buildLoadingState();
    }

    return _buildDashboard(context, provider);
  }

  Widget _buildErrorState(HomeProvider provider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (manager != null && !homeProvider.greeting)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Bienvenue ${manager!.lastName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Chargement du tableau de bord...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, HomeProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final pagePadding = isDesktop ? 24.0 : 16.0;

    return ListView(
      padding: EdgeInsets.all(pagePadding),
      children: [
        _buildDashboardHeader(context, provider),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isStatsHiden
              ? _buildHiddenStatsNotice()
              : _buildStatsCards(context, provider, isDesktop, isTablet),
        ),
        const SizedBox(height: 22),
        _buildSectionHeader(
          title: 'Suivi opérationnel',
          subtitle: 'Sites, superviseurs et chefs de zone',
          icon: Icons.monitor_heart_outlined,
          onDark: true,
        ),
        const SizedBox(height: 12),
        _buildDataGrids(context, provider, isDesktop, isTablet),
      ],
    );
  }

  Widget _buildDashboardHeader(BuildContext context, HomeProvider provider) {
    final managerName = manager == null
        ? 'Tableau de bord'
        : 'Bonjour ${manager!.lastName}'.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppConstants.primaryColor,
            Color(0xFF303236),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  managerName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SPAS GROUPE SABA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DashboardMetricChip(
                icon: Icons.location_city_rounded,
                label: 'Sites actifs',
                value: provider.nbSite.toString(),
                color: const Color(0xFFB8C7FF),
              ),
              _DashboardMetricChip(
                icon: Icons.supervisor_account_rounded,
                label: 'Superviseurs',
                value: provider.supervisors.length.toString(),
                color: const Color(0xFF9FE7DD),
              ),
              _buildHideButton(),
              _buildRefreshButton(provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    HomeProvider provider,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      key: const ValueKey('stats-visible'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Indicateurs clés',
            subtitle: 'Activité et alertes',
            icon: Icons.dashboard_customize_outlined,
            onDark: false,
            compact: true,
          ),
          const SizedBox(height: 14),
          _buildStatsGrid(context, provider, isDesktop, isTablet),
        ],
      ),
    );
  }

  Widget _buildHiddenStatsNotice() {
    return Container(
      key: const ValueKey('stats-hidden'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Indicateurs masqués',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: hideStats,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Afficher'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHideButton() {
    return Tooltip(
      message:
          isStatsHiden ? 'Afficher les indicateurs' : 'Masquer les indicateurs',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hideStats,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(
              isStatsHiden ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(HomeProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: provider.isLoading ? null : () => provider.refresh(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              const SizedBox(width: 8),
              Text(
                provider.isLoading ? 'Actualisation...' : 'Actualiser',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    HomeProvider provider,
    bool isDesktop,
    bool isTablet,
  ) {
    final statsWidgets = _buildStatsWidgets(provider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = isDesktop
            ? 4
            : isTablet
                ? 3
                : 1;
        final rawWidth = (availableWidth - (columns - 1) * 12) / columns;
        final cardWidth = availableWidth < 210
            ? availableWidth
            : rawWidth.clamp(210.0, 260.0).toDouble();

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statsWidgets
              .map(
                (widget) => SizedBox(
                  width: cardWidth,
                  child: widget,
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<Widget> _buildStatsWidgets(HomeProvider provider) {
    return [
      PointageSiteCard(nombreSite: provider.nbSite),
      SiteCard(nombreSites: provider.nbSite),
      Skeletonizer(
        enabled: provider.supervisors.isEmpty && provider.isLoading,
        child: SupervisorCard(superviseur: provider.supervisors),
      ),
      ..._buildAgentCards(),
      NoteCard(),
      const ToolStatusCard(),
      Consumer<ErrorLogProvider>(
        builder: (context, errorProvider, _) => ErrorStatsCard(
          stats: errorProvider.stats,
          isLoading: errorProvider.isLoading,
        ),
      ),
    ];
  }

  List<Widget> _buildAgentCards() {
    if (_isLoadingAgentTypes) {
      return [
        const Skeletonizer(
          enabled: true,
          child: SupervisorCard(superviseur: []),
        ),
      ];
    }

    if (_agentTypes.isEmpty) {
      return const [
        _DashboardPlaceholderTile(label: "Aucun type d'agent"),
      ];
    }

    return _agentTypes
        .map(
          (type) => AgentCard(domaine: type.label),
        )
        .toList();
  }

  Widget _buildDataGrids(
    BuildContext context,
    HomeProvider provider,
    bool isDesktop,
    bool isTablet,
  ) {
    final dataWidgets = [
      SiteListWithStatus(sites: provider.sites),
      SitePointingListWithStatus(supList: provider.supervisors),
      const ZonePointageProgressionList(),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: dataWidgets[0]),
          const SizedBox(width: 16),
          Expanded(child: dataWidgets[1]),
          const SizedBox(width: 16),
          Expanded(child: dataWidgets[2]),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dataWidgets[0]),
              const SizedBox(width: 16),
              Expanded(child: dataWidgets[1]),
            ],
          ),
          const SizedBox(height: 16),
          dataWidgets[2],
        ],
      );
    }

    return Column(
      children: [
        dataWidgets[0],
        const SizedBox(height: 16),
        dataWidgets[1],
        const SizedBox(height: 16),
        dataWidgets[2],
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool onDark,
    bool compact = false,
  }) {
    final foreground = onDark ? Colors.white : const Color(0xFF152033);
    final muted =
        onDark ? Colors.white.withValues(alpha: 0.68) : const Color(0xFF697586);
    final iconBackground = onDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppConstants.primaryColor.withValues(alpha: 0.1);
    final iconColor = onDark ? Colors.white : AppConstants.primaryColor;

    return Row(
      children: [
        Container(
          width: compact ? 32 : 38,
          height: compact ? 32 : 38,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE7ECF3),
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: compact ? 18 : 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricChip extends StatelessWidget {
  const _DashboardMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardPlaceholderTile extends StatelessWidget {
  const _DashboardPlaceholderTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
