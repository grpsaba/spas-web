import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/accueil/providers/site_status_provider.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/models/date_filter.dart';

/// Dialog moderne avec tabs pour afficher les sites pointés et non pointés
class SiteStatusDialog extends StatefulWidget {
  final Supervisor? supervisor;
  final ZoneMember? zoneMember;
  final DateFilter? dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final DateTime? month;

  const SiteStatusDialog.forSupervisor({
    super.key,
    required Supervisor this.supervisor,
    required this.dateFilter,
    this.customStartDate,
    this.customEndDate,
  })  : zoneMember = null,
        month = null;

  const SiteStatusDialog.forZoneMember({
    super.key,
    required ZoneMember this.zoneMember,
    required DateTime this.month,
  })  : supervisor = null,
        dateFilter = null,
        customStartDate = null,
        customEndDate = null;

  @override
  State<SiteStatusDialog> createState() => _SiteStatusDialogState();
}

class _SiteStatusDialogState extends State<SiteStatusDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SiteStatusProvider _provider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _provider = SiteStatusProvider();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _loadData() {
    if (widget.supervisor != null) {
      final startDate = widget.dateFilter == DateFilter.custom && widget.customStartDate != null
          ? widget.customStartDate!
          : widget.dateFilter?.startDate ?? DateTime.now();
      final endDate = widget.dateFilter == DateFilter.custom && widget.customEndDate != null
          ? widget.customEndDate!
          : widget.dateFilter?.endDate ?? DateTime.now().add(const Duration(days: 1));

      _provider.loadForSupervisor(
        supervisor: widget.supervisor!,
        startDate: startDate,
        endDate: endDate,
      );
    } else if (widget.zoneMember != null) {
      _provider.loadForZoneMember(
        zoneMember: widget.zoneMember!,
        month: widget.month ?? DateTime.now(),
      );
    }
  }

  String get _title {
    if (widget.supervisor != null) {
      return '${widget.supervisor!.firstName} ${widget.supervisor!.lastName}';
    }
    if (widget.zoneMember != null) {
      return '${widget.zoneMember!.firstName} ${widget.zoneMember!.lastName}';
    }
    return 'Statut des sites';
  }

  String get _subtitle {
    if (widget.supervisor != null && widget.dateFilter != null) {
      return widget.dateFilter!.label;
    }
    if (widget.zoneMember != null && widget.month != null) {
      return '${_monthName(widget.month!.month)} ${widget.month!.year}';
    }
    return '';
  }

  String _monthName(int month) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 550.0 : width * 0.9;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: dialogWidth,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsBar(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_subtitle.isNotEmpty)
                  Text(
                    _subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<SiteStatusProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                provider.totalSites.toString(),
                Colors.blue,
              ),
              _buildStatItem(
                'Visités',
                provider.visitedCount.toString(),
                Colors.green,
              ),
              _buildStatItem(
                'Non visités',
                provider.unvisitedCount.toString(),
                Colors.red,
              ),
              _buildStatItem(
                'Progression',
                '${provider.progressPercent.toStringAsFixed(0)}%',
                _getProgressColor(provider.progressPercent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percent) {
    if (percent <= 30) return Colors.red;
    if (percent <= 60) return Colors.orange;
    return Colors.green;
  }

  Widget _buildTabBar() {
    return Consumer<SiteStatusProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppConstants.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppConstants.primaryColor,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    const SizedBox(width: 6),
                    Text('Visités (${provider.visitedCount})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cancel, size: 18),
                    const SizedBox(width: 6),
                    Text('Non visités (${provider.unvisitedCount})'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    return Consumer<SiteStatusProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des données...'),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildSiteList(provider.visitedSites, isVisited: true),
            _buildSiteList(provider.unvisitedSites, isVisited: false),
          ],
        );
      },
    );
  }

  Widget _buildSiteList(List<Site> sites, {required bool isVisited}) {
    if (sites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVisited ? Icons.check_circle_outline : Icons.info_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isVisited ? 'Aucun site visité' : 'Tous les sites ont été visités !',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sites.length,
      itemBuilder: (context, index) {
        final site = sites[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isVisited
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Icon(
                isVisited ? Icons.check : Icons.location_on,
                color: isVisited ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              site.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (site.adresse.isNotEmpty)
                  Text(
                    site.adresse,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (site.phone.isNotEmpty)
                  Text(
                    site.phone,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
            trailing: Text(
              site.codeSite,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        );
      },
    );
  }
}
