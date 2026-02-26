import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/accueil/widgets/site_status_dialog.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/zone/providers/zone_pointage_provider.dart';

import '../model.dart';
import '../notes/imprime_rapport.dart';

class ZonePointageProgressionList extends StatefulWidget {
  const ZonePointageProgressionList({super.key});

  @override
  State<ZonePointageProgressionList> createState() => _ZonePointageProgressionListState();
}

class _ZonePointageProgressionListState extends State<ZonePointageProgressionList> {
  late ZonePointageListProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ZonePointageListProvider();
    _loadData();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _loadData() {
    if (_provider.needsRefresh) {
      _provider.loadData();
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _provider.selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Choisir un mois",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _provider.setMonth(picked);
    }
  }

  void _showSiteStatusDialog(ZoneMember zoneMember) {
    showDialog(
      context: context,
      builder: (_) => SiteStatusDialog.forZoneMember(
        zoneMember: zoneMember,
        month: _provider.selectedMonth,
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        height: MediaQuery.of(context).size.height - 192,
        decoration: BoxDecoration(
          color: AppConstants.secondaryColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(color: Colors.white24),
            _buildFilters(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          "Pointages site par zone",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Consumer<ZonePointageListProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: () => _provider.refresh(),
              tooltip: 'Actualiser',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Consumer<ZonePointageListProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            // Sélecteur de mois
            InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.bgColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatMonth(provider.selectedMonth),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Recherche
            Expanded(
              child: SearchTextField(
                fillColor: AppConstants.bgColor,
                hintColor: AppConstants.secondaryColor,
                textColor: Colors.white,
                onSearch: (value) => provider.setSearchKeyword(value),
                onPress: () {},
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList() {
    return Consumer<ZonePointageListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.filteredStats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Chargement des données...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        if (provider.error != null && provider.filteredStats.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final stats = provider.filteredStats;

        if (stats.isEmpty) {
          return const Center(
            child: Text(
              'Aucun membre de zone trouvé',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildZoneMemberCard(stat);
          },
        );
      },
    );
  }

  Widget _buildZoneMemberCard(ZoneMemberPointageStats stat) {
    final zoneMember = stat.zoneMember;
    final percent = stat.progressPercent;

    return Card(
      elevation: 0.2,
      color: AppConstants.secondaryColor.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          "${zoneMember.firstName} ${zoneMember.lastName} - ${zoneMember.zone?.codeZone ?? ""}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            FAProgressBar(
              displayText: "%",
              size: 12,
              maxValue: 100.0,
              currentValue: percent.clamp(0, 100),
              progressColor: percent <= 30
                  ? Colors.red
                  : percent <= 60
                      ? Colors.orange
                      : Colors.green,
              backgroundColor: AppConstants.bgColor,
            ),
            const SizedBox(height: 4),
            Text(
              "Poids: ${stat.realizedWeight.toStringAsFixed(1)}/${stat.expectedWeight.toStringAsFixed(1)}",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            Text(
              "Sites: ${stat.visitedSites}/${stat.totalSites}",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: "Rapport",
          icon: const Icon(Icons.description, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImprimeRapport(
                  source: "${zoneMember.firstName} ${zoneMember.lastName}",
                ),
              ),
            );
          },
        ),
        onTap: () => _showSiteStatusDialog(zoneMember),
      ),
    );
  }
}
