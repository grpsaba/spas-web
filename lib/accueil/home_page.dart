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
import 'absenceAgent.dart';
import 'agent_card.dart';
import 'note_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeProvider homeProvider;
  
  @override
  void initState() {
    super.initState();
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
   WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  bool isStatsHiden = false;
  List<AgentType> _agentTypes = []; // Store fetched AgentType data
  bool _isLoadingAgentTypes = true; // Track loading state
  Future<void> _initializeData() async {
    if (homeProvider.needsRefresh) {
      await homeProvider.loadData();
    }
    _fetchAgentTypes();
    // Load error logs stats
    if(mounted){
      context.read<ErrorLogProvider>().loadStats();
    }
  }
  Future<void> _fetchAgentTypes() async {
    try {
      final agentTypes = await AgentTypeService().allFuture();
      setState(() {
        _agentTypes = agentTypes;
        _isLoadingAgentTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAgentTypes = false;
      });
    }
  }
  final manager = AuthService.currentManager;
void hideStats(){
  setState(() {
    isStatsHiden = !isStatsHiden;
  });
}
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return PageModel(
          title: "SPAS GROUPE SABA",
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                "Bienvenue ${manager!.lastName}",
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
                  "Chargement du tableau de bord...",
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
    final isMobile = screenWidth <= 768;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
           Row(

          children: [const Spacer(),
             _buildHideButton(),
             SizedBox(width: 10,),
          _buildRefreshButton(provider),
          ],
         ),
      isStatsHiden? const SizedBox.shrink() :  _buildStatsCards(context, provider, isDesktop, isTablet, isMobile),
        const SizedBox(height: 24),
        _buildDataGrids(context, provider, isDesktop, isTablet, isMobile),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context, HomeProvider provider, bool isDesktop, bool isTablet, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.bgColor,
            AppConstants.bgColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
      
          _buildStatsRow(context, provider, isDesktop, isTablet, isMobile),
        ],
      ),
    );
  }
  Widget _buildHideButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        radius: 0,
        splashColor: Colors.transparent,
        onTap: ()=> hideStats(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child:    Icon(isStatsHiden? Icons.visibility:Icons.visibility_off,color: Colors.white,size: 20,)
           
        ),
      ),
    );
  }
  Widget _buildRefreshButton(HomeProvider provider,{bool stats = false}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: provider.isLoading ? null : () => provider.refresh(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: stats? GestureDetector(onTap: ()=>hideStats(),child:  Icon(isStatsHiden? Icons.visibility:Icons.visibility_off,color: Colors.white,size: 20,),)
             :   Row(
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
                  provider.isLoading ? "Actualisation..." : "Actualiser",
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
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, HomeProvider provider, bool isDesktop, bool isTablet, bool isMobile) {
    final statsWidgets = _buildStatsWidgets(provider);
    
    if (isDesktop) {
      // Desktop: Tous les éléments sur une ligne avec scroll horizontal si nécessaire
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statsWidgets,
        ),
      );
    } else if (isTablet) {
      // Tablette: 2 éléments par ligne
      return _buildGridLayout(statsWidgets, 2);
    } else {
      // Mobile: 1 élément par ligne (vertical)
      return Column(
        children: statsWidgets.where((widget) => widget is! SizedBox).map((widget) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget,
          );
        }).toList(),
      );
    }
  }

  Widget _buildGridLayout(List<Widget> widgets, int itemsPerRow) {
    final rows = <Widget>[];
    final filteredWidgets = widgets.where((widget) => widget is! SizedBox).toList();
    
    for (int i = 0; i < filteredWidgets.length; i += itemsPerRow) {
      final rowWidgets = <Widget>[];
      
      for (int j = 0; j < itemsPerRow && i + j < filteredWidgets.length; j++) {
        rowWidgets.add(Expanded(child: filteredWidgets[i + j]));
        if (j < itemsPerRow - 1 && i + j + 1 < filteredWidgets.length) {
          rowWidgets.add(const SizedBox(width: 12));
        }
      }
      
      // Remplir les espaces vides si nécessaire
      while (rowWidgets.length < itemsPerRow * 2 - 1) {
        rowWidgets.add(const Expanded(child: SizedBox()));
        if (rowWidgets.length < itemsPerRow * 2 - 1) {
          rowWidgets.add(const SizedBox(width: 12));
        }
      }
      
      rows.add(Row(children: rowWidgets));
      if (i + itemsPerRow < filteredWidgets.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    return Column(children: rows);
  }

  List<Widget> _buildStatsWidgets(HomeProvider provider) {
    return [
      PointageSiteCard(nombreSite: provider.nbSite),
      const SizedBox(width: 12),
      SiteCard(nombreSites: provider.nbSite),
      const SizedBox(width: 12),
      Skeletonizer(
        enabled: provider.supervisors.isEmpty && provider.isLoading,
        child: SupervisorCard(superviseur: provider.supervisors),
      ),
      const SizedBox(width: 12),
      ..._buildAgentCards(),
      const SizedBox(width: 12),
      NoteCard(),
      const SizedBox(width: 12),
      const ToolStatusCard(),
      const SizedBox(width: 12),
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
        Skeletonizer(
          enabled: true,
          child: SupervisorCard(superviseur: []), // Use empty list for fallback
        ),
      ];
    }

    if (_agentTypes.isEmpty) {
      return [
        const Text(
          "Aucun type d'agent disponible",
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }

    return _agentTypes
        .asMap()
        .entries
        .expand((entry) {
          final type = entry.value;
          final isLast = entry.key == _agentTypes.length - 1;
          return [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AgentCard(domaine: type.label),
            ),
            if (!isLast) const SizedBox(width: 8), // Add spacing between cards
          ];
        })
        .toList();
  }

  Widget _buildDataGrids(BuildContext context, HomeProvider provider, bool isDesktop, bool isTablet, bool isMobile) {
    final dataWidgets = [
      SiteListWithStatus(sites: provider.sites),
      SitePointingListWithStatus(supList: provider.supervisors),
      const ZonePointageProgressionList(),
      const ListAbsenceAgent(),
    ];

    if (isDesktop) {
      // Desktop: 4 colonnes
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: dataWidgets[0]),
          const SizedBox(width: 16),
          Expanded(child: dataWidgets[1]),
          const SizedBox(width: 16),
          Expanded(child: dataWidgets[2]),
          const SizedBox(width: 16),
          Expanded(child: dataWidgets[3]),
        ],
      );
    } else if (isTablet) {
      // Tablette: 2 colonnes, 2 lignes
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dataWidgets[2]),
              const SizedBox(width: 16),
              Expanded(child: dataWidgets[3]),
            ],
          ),
        ],
      );
    } else {
      // Mobile: 1 colonne
      return Column(
        children: [
          dataWidgets[0],
          const SizedBox(height: 16),
          dataWidgets[1],
          const SizedBox(height: 16),
          dataWidgets[2],
          const SizedBox(height: 16),
          dataWidgets[3],
        ],
      );
    }
  }
}
