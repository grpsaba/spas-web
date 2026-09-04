import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/accueil/widgets/dashboard_progress_bar.dart';
import 'package:spas_web/accueil/widgets/site_status_dialog.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/notes/imprime_rapport.dart';
import 'package:spas_web/zone/providers/zone_pointage_provider.dart';

class ZonePointageProgressionList extends StatefulWidget {
  const ZonePointageProgressionList({
    super.key,
    this.height = 540,
  });

  final double height;

  @override
  State<ZonePointageProgressionList> createState() =>
      _ZonePointageProgressionListState();
}

class _ZonePointageProgressionListState
    extends State<ZonePointageProgressionList> {
  static const _primary = Color(0xFFB76E00);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE5EAF2);
  static const _surface = Color(0xFFFBFCFE);

  late final ZonePointageListProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ZonePointageListProvider();
    if (_provider.needsRefresh) _provider.loadData();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 14),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ZonePointageListProvider>(
      builder: (context, provider, _) {
        final count = provider.filteredStats.length;
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
                color: _primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chefs de zone',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Progression mensuelle des sites visités',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (provider.isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: provider.refresh,
                icon: const Icon(Icons.refresh, color: _muted, size: 19),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Consumer<ZonePointageListProvider>(
      builder: (context, provider, _) {
        final monthButton = OutlinedButton.icon(
          onPressed: _pickMonth,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(_formatMonth(provider.selectedMonth)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            backgroundColor: _surface,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        final search = TextField(
          onChanged: provider.setSearchKeyword,
          style: const TextStyle(color: _ink, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Rechercher un chef ou une zone',
            hintStyle: const TextStyle(color: _muted, fontSize: 12),
            prefixIcon: const Icon(Icons.search, size: 19, color: _muted),
            filled: true,
            fillColor: _surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.4),
            ),
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 430) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [monthButton, const SizedBox(height: 8), search],
              );
            }
            return Row(
              children: [
                monthButton,
                const SizedBox(width: 10),
                Expanded(child: search),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildList() {
    return Consumer<ZonePointageListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.filteredStats.isEmpty) {
          return const _ProgressLoadingState();
        }

        if (provider.error != null && provider.filteredStats.isEmpty) {
          return _ProgressErrorState(
            message: provider.error!,
            onRetry: provider.refresh,
          );
        }

        final stats = provider.filteredStats;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: stats.isEmpty
              ? const _EmptyZoneList(
                  key: ValueKey('empty-zones'),
                )
              : ListView.separated(
                  key: ValueKey(
                    'zones-${provider.selectedMonth.year}-${provider.selectedMonth.month}-${provider.searchKeyword}',
                  ),
                  itemCount: stats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildZoneMemberRow(stats[index]),
                ),
        );
      },
    );
  }

  Widget _buildZoneMemberRow(ZoneMemberPointageStats stat) {
    final zoneMember = stat.zoneMember;
    final name = '${zoneMember.firstName} ${zoneMember.lastName}'.trim();
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final percent = stat.progressPercent.clamp(0, 100).toDouble();
    final color = percent <= 30
        ? const Color(0xFFD14343)
        : percent <= 60
            ? _primary
            : const Color(0xFF198754);

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showSiteStatusDialog(zoneMember),
        hoverColor: _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primary.withValues(alpha: 0.11),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? 'Chef de zone sans nom' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${percent.round()}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      zoneMember.zone?.name ??
                          zoneMember.zone?.codeZone ??
                          'Zone non renseignée',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 7),
                    DashboardProgressBar(value: percent, color: color),
                    const SizedBox(height: 4),
                    Text(
                      'Sites: ${stat.visitedSites}/${stat.totalSites}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Ouvrir le rapport',
                onPressed: () => _openReport(zoneMember),
                icon: const Icon(
                  Icons.description_outlined,
                  color: _muted,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _provider.selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Choisir un mois',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) await _provider.setMonth(picked);
  }

  void _showSiteStatusDialog(ZoneMember zoneMember) {
    showDialog<void>(
      context: context,
      builder: (_) => SiteStatusDialog.forZoneMember(
        zoneMember: zoneMember,
        month: _provider.selectedMonth,
      ),
    );
  }

  void _openReport(ZoneMember zoneMember) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImprimeRapport(
          source: '${zoneMember.firstName} ${zoneMember.lastName}',
        ),
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[date.month]} ${date.year}';
  }
}

class _ProgressLoadingState extends StatelessWidget {
  const _ProgressLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(height: 12),
          Text(
            'Chargement des progressions...',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProgressErrorState extends StatelessWidget {
  const _ProgressErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD14343), size: 34),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyZoneList extends StatelessWidget {
  const _EmptyZoneList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, color: Color(0xFF98A2B3), size: 36),
          SizedBox(height: 10),
          Text(
            'Aucun chef de zone trouvé',
            style: TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
