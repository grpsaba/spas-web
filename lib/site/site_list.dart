import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pdf/api/pdf_api.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/pointage_weighted_engine.dart';
import 'package:spas_web/services/site.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerSite.dart';
import 'manual_pointing_dialog.dart';
import 'bulk_pointing_dialog.dart';

class SiteList extends StatefulWidget {
  const SiteList({
    super.key,
  });

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SiteList> {
  final SiteService _service = SiteService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  bool _sortAscending = false;
  int _sortColumnIndex = 0;
  //filtre statut
  bool _actif = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rowParPage = defauldRowParPage;
    _texController.text = defauldRowParPage.toString();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _texController.dispose();
  }

  Future<void> stopSos(Site site) async {
    await _service.stopSos(site);
  }

  Future<void> _toggleSiteStatus(Site site) async {
    final bool wasInactive = !(site.actif ?? false);
    site.actif = !(site.actif ?? false);

    try {
      await SiteService().update(site);
      if (wasInactive && site.actif == true) {
        await _generateMonthlyPointingsForSite(site);
      }
    } catch (_) {
      site.actif = !(site.actif ?? false);
    }
  }

  Future<void> _deleteSite(Site site) async {
    await SiteService().delete(site);
  }

  Future<void> _generateMonthlyPointingsForSite(Site site) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);

    final supervisors = <Supervisor>[];
    if (site.supervisor != null) {
      supervisors.add(site.supervisor!);
    }
    if (site.supervisor_2 != null) {
      supervisors.add(site.supervisor_2!);
    }

    if (supervisors.isEmpty) {
      return;
    }

    for (final sup in supervisors) {
      for (DateTime date = startOfMonth;
          !date.isAfter(today);
          date = date.add(const Duration(days: 1))) {
        final pointingSite = PointingSite(
          site: site,
          supervisor: sup,
          latlng: LatLngModel(lat: site.latLng.lat, lng: site.latLng.lng),
          date: DateTime(date.year, date.month, date.day, 8, 0),
          distance: 0,
        );

        await PointingSiteService().add(pointingSite);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 2,
      title: "Gestion des sites",
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final docs =
                      snapshot.data?.docs.map((e) => e.data()).toList() ?? [];

                  final allSites = docs
                      .map((e) => Site.fromJson(e as Map<String, dynamic>))
                      .toList();

                  allSites.sort((site1, site2) {
                    return site1.name.compareTo(site2.name);
                  });

                  final filteredSites = allSites
                      .where((element) => element.actif == _actif)
                      .toList();

                  // Statistiques globales (indépendantes du filtre actif/inactif)
                  final totalSites = allSites.length;
                  final activeSites =
                      allSites.where((site) => site.actif == true).length;
                  final inactiveSites =
                      allSites.where((site) => site.actif != true).length;
                  final totalAgents =
                      allSites.fold<int>(0, (sum, site) => sum + site.nbAgent);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header avec statistiques
                      _buildHeaderSection(context, totalSites, activeSites,
                          inactiveSites, totalAgents),
                      const SizedBox(height: 20),

                      // Tableau des sites
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                cardTheme: Theme.of(context).cardTheme.copyWith(
                                      margin: EdgeInsets.zero,
                                      color: Colors.white,
                                    ),
                              ),
                              child: PaginatedDataTable(
                                headingRowHeight: 56,
                                dataRowMinHeight: 72,
                                dataRowMaxHeight: 88,
                                horizontalMargin: 16,
                                columnSpacing: constraints.maxWidth > 1400 ? 32 : 16,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          header: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.list_alt,
                                      color: Theme.of(context).primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Liste des sites",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Barre de recherche
                                Container(
                                  width: 300,
                                  //   height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: SearchTextField(
                                    onSearch: (value) {
                                      setState(() {
                                        _keyword = value;
                                      });
                                    },
                                    onPress: () {},
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Filtre statut
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _actif = _actif ? false : true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _actif
                                          ? Colors.green
                                          : Colors.redAccent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_actif
                                                  ? Colors.green
                                                  : Colors.redAccent)
                                              .withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _actif ? Icons.check : Icons.cancel,
                                            color: (_actif
                                                ? Colors.green
                                                : Colors.redAccent),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _actif ? "Actif" : "Inactif",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Boutons d'action
                                Row(
                                  children: [
                                    AuthService.currentManager!.profil!
                                            .getModule(ModuleName.SITE)!
                                            .add
                                        ? _buildActionButton(
                                            context,
                                            "Ajouter un site",
                                            Icons.add,
                                            Colors.green,
                                            () {
                                              Site site = Site(
                                                  UID: "",
                                                  codeSite: "",
                                                  name: "",
                                                  adresse: "",
                                                  email: "",
                                                  phone: "",
                                                  latLng: LatLngModel(
                                                      lat: 0, lng: 0),
                                                  token: "",
                                                  nbAgent: 0,
                                                  supervisor_2: null,
                                                  supervisor: null,
                                                  actif: false,
                                                  zone: null,
                                                  dateContrat: null,
                                                  nbRonde: null,
                                                  pointingType: 'jour');
                                              context.go('/sites/add',
                                                  extra: site);
                                            },
                                          )
                                        : const SizedBox(),
                                    AuthService.currentManager!.profil!
                                            .getModule(ModuleName.SITE)!
                                            .generBadge
                                        ? _buildActionButton(
                                            context,
                                            "Générer QR Codes",
                                            Icons.qr_code,
                                            Colors.blue,
                                            () {
                                              CarteGenerator
                                                  .generateMiltiQrSite(
                                                      _DataSource.dataToprint);
                                            },
                                          )
                                        : const SizedBox(),
                                    _buildActionButton(
                                      context,
                                      "Pointage en lot",
                                      Icons.checklist,
                                      Colors.purple,
                                      () {
                                        _showBulkPointingDialog(
                                            context, _DataSource.dataToprint);
                                      },
                                    ),
                                    AuthService.currentManager!.profil!
                                            .getModule(ModuleName.SITE)!
                                            .print
                                        ? _buildActionButton(
                                            context,
                                            "Exporter PDF",
                                            Icons.print,
                                            Colors.orange,
                                            () async {
                                              var document =
                                                  await SiteListToPDF.export(
                                                      _DataSource.dataToprint);
                                              PdfApi.openFile(document);
                                            },
                                          )
                                        : const SizedBox(),
                                    AuthService.currentManager!.profil!
                                            .getModule(ModuleName.SITE)!
                                            .print
                                        ? _buildActionButton(
                                            context,
                                            "Exporter Excel",
                                            Icons.table_chart,
                                            Colors.teal,
                                            () async {
                                              ExportData.SitesToExcel(
                                                  _DataSource.dataToprint);
                                            },
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            RowPerPageWidget(
                              controller: _texController,
                              incremente: () {
                                setState(() {
                                  rowParPage += 1;
                                  _texController.text = rowParPage.toString();
                                });
                              },
                              decremente: () {
                                setState(() {
                                  rowParPage = rowParPage <= defauldRowParPage
                                      ? defauldRowParPage
                                      : rowParPage - 1;

                                  _texController.text = rowParPage.toString();
                                });
                              },
                            ),
                          ],
                          rowsPerPage: rowParPage,
                          showFirstLastButtons: true,
                          columns: [
                            DataColumn(
                              onSort: (columnIndex, _) {
                                setState(() {
                                  sortSite(columnIndex, filteredSites);
                                });
                              },
                              label: Text(
                                "Site",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Infos",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Superviseurs",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Statut",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Actions",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                          source: _DataSource(
                            context: context,
                            keyword: _keyword,
                            data: filteredSites,
                            onManualPointing: _showManualPointingDialog,
                            onDeactivateSos: (site) async {
                              await stopSos(site);
                            },
                            onToggleStatus: (site) async {
                              await _toggleSiteStatus(site);
                            },
                            onDeleteSite: (site) async {
                              await _deleteSite(site);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                    ],
                  );
                } else {
                  return Center(
                    child: Loading(
                      size: 64,
                      inline: true,
                    ),
                  );
                }
              })),
    );
  }

  sortSite(index, List<Site> data) {
    _sortColumnIndex = index;
    if (_sortAscending == true) {
      _sortAscending = false;
      data.sort((site1, site2) {
        return site1.name.compareTo(site2.name);
      });
    } else {
      _sortAscending = true;
      data.sort((site1, site2) {
        return site2.name.compareTo(site1.name);
      });
    }
  }

  void _showManualPointingDialog(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManualPointingDialog(site: site);
      },
    );
  }

  void _showBulkPointingDialog(BuildContext context, List<Site> sites) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BulkPointingDialog(sites: sites);
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, int totalSites,
      int activeSites, int inactiveSites, int totalAgents) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gestion des Sites",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Surveillez et gérez tous vos sites de sécurité",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  "Total Sites",
                  totalSites.toString(),
                  Icons.location_on,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  "Sites Actifs",
                  activeSites.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  "Sites Inactifs",
                  inactiveSites.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  "Total Agents",
                  totalAgents.toString(),
                  Icons.people,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String tooltip, IconData icon,
      Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataSource extends DataTableSource {
  static List<Site> dataToprint = [];

  final List<Site> data;
  final String keyword;
  final BuildContext context;
  final void Function(BuildContext, Site) onManualPointing;
  final Future<void> Function(Site site) onDeactivateSos;
  final Future<void> Function(Site site) onToggleStatus;
  final Future<void> Function(Site site) onDeleteSite;

  _DataSource({
    required this.context,
    required this.data,
    required this.keyword,
    required this.onManualPointing,
    required this.onDeactivateSos,
    required this.onToggleStatus,
    required this.onDeleteSite,
  });

  List<Site> get _visibleData {
    final query = keyword.trim().toLowerCase();
    final filtered = data.where((site) {
      if (query.isEmpty) return true;

      final supervisor1Name =
          "${site.supervisor?.firstName ?? ''} ${site.supervisor?.lastName ?? ''}"
              .trim();
      final supervisor2Name =
          "${site.supervisor_2?.firstName ?? ''} ${site.supervisor_2?.lastName ?? ''}"
              .trim();

      final fields = <String>[
        site.name,
        site.codeSite,
        site.phone,
        site.zone?.name ?? '',
        supervisor1Name,
        site.supervisor?.phone ?? '',
        supervisor2Name,
        site.supervisor_2?.phone ?? '',
      ];

      return fields.any((field) => field.toLowerCase().contains(query));
    }).toList();

    dataToprint = filtered;
    return filtered;
  }

  @override
  DataRow? getRow(int index) {
    final visibleData = _visibleData;

    if (index >= visibleData.length) {
      return const DataRow(cells: [
        DataCell(SizedBox.shrink()),
        DataCell(SizedBox.shrink()),
        DataCell(SizedBox.shrink()),
        DataCell(SizedBox.shrink()),
        DataCell(SizedBox.shrink()),
      ]);
    }

    final site = visibleData[index];
    final isActive = site.actif ?? false;

    final supervisor1 =
        "${site.supervisor?.firstName ?? ''} ${site.supervisor?.lastName ?? ''}"
            .trim();
    final supervisor2 =
        "${site.supervisor_2?.firstName ?? ''} ${site.supervisor_2?.lastName ?? ''}"
            .trim();

    return DataRow(
      //white color by defaut
      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return Theme.of(context).primaryColor.withAlpha(10);
        }
        return Colors.white;
      }),
      cells: [
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            site.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Code: ${site.codeSite}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: site.pointingType == SitePointingType.jour ? Colors.blue[100] : site.pointingType == SitePointingType.nuit ? Colors.orange[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            site.pointingType == SitePointingType.jour ? 'Pointage Jour' : 
            site.pointingType == SitePointingType.nuit ? 
            'Pointage Nuit' : 'Pointage Jour/Nuit',
            style: TextStyle(
              color: site.pointingType == SitePointingType.jour ? Colors.blue[800] : 
              site.pointingType == SitePointingType.nuit ? Colors.orange[800] :
               Colors.grey[800],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
         )
        ],
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Zone: ${site.zone?.name ?? '-'}', overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('Tel: ${site.phone}', overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('Agents: ${site.nbAgent}'),
        ],
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            supervisor1.isEmpty ? 'Sup. 1: -' : 'Sup. 1: $supervisor1',
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            supervisor2.isEmpty ? 'Sup. 2: -' : 'Sup. 2: $supervisor2',
            overflow: TextOverflow.ellipsis,
          ),
        ],
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.redAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isActive ? 'Actif' : 'Inactif',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (site.sos) ...[
            const SizedBox(height: 4),
            Text(
              'SOS en cours',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      )),
      DataCell(
        PopupMenuButton<String>(
          tooltip: 'Actions',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                context.go('/sites/add', extra: site);
                break;
              case 'qr':
                CarteGenerator.generateQrSite(site);
                break;
              case 'manual':
                onManualPointing(context, site);
                break;
              case 'toggle':
                await onToggleStatus(site);
                break;
              case 'sos':
                await onDeactivateSos(site);
                break;
              case 'delete':
                await onDeleteSite(site);
                break;
            }
          },
          itemBuilder: (_) {
            final siteModule =
                AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!;
            final canEdit = siteModule.view;
            final canDelete = siteModule.delete;
            final canValidation = siteModule.validation;

            final entries = <PopupMenuEntry<String>>[];

            if (isActive && canEdit) {
              entries.add(
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              );
              entries.add(
                const PopupMenuItem(value: 'qr', child: Text('Générer QR code')),
              );
              entries.add(
                const PopupMenuItem(value: 'manual', child: Text('Pointage manuel')),
              );
            }

            if (canValidation) {
              entries.add(
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(isActive ? 'Désactiver' : 'Activer'),
                ),
              );
            }

            if (site.sos) {
              entries.add(
                const PopupMenuItem(value: 'sos', child: Text('Désactiver SOS')),
              );
            }

            if (!isActive && canDelete) {
              entries.add(
                const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              );
            }

            return entries;
          },
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _visibleData.length;

  @override
  int get selectedRowCount => 0;
}

