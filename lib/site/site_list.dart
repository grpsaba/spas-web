import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pdf/api/pdf_api.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/authentication.dart';
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

  stopSos(Site site) async {
    _service.stopSos(site);
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 2,
      title: "Gestion des sites",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => e.data())
                      .toList();
                  var data = docs
                      ?.map((e) => Site.fromJson(e as Map<String, dynamic>))
                      .toList()
                      .where((element) => element.actif == _actif)
                      .toList();
                  data!.sort((site1, site2) {
                    return site1.name.compareTo(site2.name);
                  });

                  // Statistiques pour le header
                  final totalSites = data.length;
                  final activeSites =
                      data.where((site) => site.actif == true).length;
                  final inactiveSites =
                      data.where((site) => site.actif == false).length;
                  final totalAgents =
                      data.fold<int>(0, (sum, site) => sum + site.nbAgent);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec statistiques
                      _buildHeaderSection(context, totalSites, activeSites,
                          inactiveSites, totalAgents),
                      const SizedBox(height: 20),

                      // Tableau des sites
                      Container(
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
                        child: PaginatedDataTable(
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
                                                  nbRonde: null);
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
                                    AuthService.currentManager!.profil!
                                            .getModule(ModuleName.SITE)!
                                            .add
                                        ? _buildActionButton(
                                      context,
                                      "Pointage en lot",
                                      Icons.checklist,
                                      Colors.purple,
                                      () {
                                        _showBulkPointingDialog(
                                            context, _DataSource.dataToprint);
                                      },
                                    ) : const SizedBox(),
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
                              label: Text(
                                "Code",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              onSort: (columnIndex, _) {
                                setState(() {
                                  sortSite(columnIndex, data);
                                });
                              },
                              label: Text(
                                "Nom",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Zone",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Contact",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "NB Agent",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                "Position GPS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Superviseur 1",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Superviseur 2",
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
                                "Action",
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
                            data: data,
                            onManualPointing: _showManualPointingDialog,
                            onDeactivateSos: (site) {
                              stopSos(site);
                            },
                          ),
                        ),
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
  List<Site> data;

  String keyword;
  BuildContext context;
  final Function(BuildContext, Site) onManualPointing;
  void Function(Site site) onDeactivateSos;

  _DataSource({
    required this.context,
    required this.data,
    required this.keyword,
    required this.onManualPointing,
    required this.onDeactivateSos,
  });
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data.where((element) {
      if (element.supervisor_2 != null) {
        return element.name.toLowerCase().startsWith(keyword.toLowerCase()) ||
            element.codeSite.toLowerCase() == (keyword.toLowerCase()) ||
            "${element.supervisor!.firstName} ${element.supervisor!.lastName}"
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.supervisor!.phone
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            "${element.supervisor_2!.firstName} ${element.supervisor_2!.lastName}"
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.supervisor_2!.phone
                .toLowerCase()
                .contains(keyword.toLowerCase());
      } else {
        return element.name.toLowerCase().contains(keyword.toLowerCase()) ||
            element.codeSite.toLowerCase() == (keyword.toLowerCase()) ||
            "${element.supervisor!.firstName} ${element.supervisor!.lastName}"
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.supervisor!.phone
                .toLowerCase()
                .contains(keyword.toLowerCase());
      }
    }).toList();
    dataToprint = data;
    if (index >= data.length) {
      return const DataRow(cells: [
        //DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    Site site = data[index];

    return DataRow(cells: [
      DataCell(Text(site.codeSite)),
      DataCell(Text(site.name)),
      DataCell(Text(site.zone?.name ?? '')),
      DataCell(Text(site.phone)),
      // DataCell(Text(site.adresse)),
      DataCell(Text(site.nbAgent.toString())),
      DataCell(Text("${site.latLng.lat} , ${site.latLng.lng}")),
      DataCell(
          Text("${site.supervisor?.firstName} ${site.supervisor?.lastName}")),
      DataCell(site.supervisor_2 == null
          ? const Text("")
          : Text(
              "${site.supervisor_2?.firstName} ${site.supervisor_2?.lastName}")),
      DataCell(SiteStatut(
        site: site,
      )),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          site.actif!
              ? _buildRowActionButton(
                  context,
                  Icons.edit,
                  Colors.blue,
                  "Modifier",
                  () {
                    context.go('/sites/add', extra: site);
                  },
                )
              : const SizedBox.shrink(),
          site.actif!
              ? _buildRowActionButton(
                  context,
                  Icons.qr_code,
                  Colors.green,
                  "QR Code",
                  () {
                    CarteGenerator.generateQrSite(site);
                  },
                )
              : const SizedBox.shrink(),
          site.actif!
              ? _buildRowActionButton(
                  context,
                  Icons.location_on,
                  Colors.purple,
                  "Pointage manuel",
                  () {
                    onManualPointing(context, site);
                  },
                )
              : const SizedBox.shrink(),
          site.actif!
              ? const SizedBox.shrink()
              : AuthService.currentManager!.profil!
                      .getModule(ModuleName.SITE)!
                      .delete
                  ? DeleteSite(site: site)
                  : const SizedBox.shrink(),
          site.sos
              ? _buildRowActionButton(
                  context, Icons.sos, Colors.red, "Sos en cours", () {
                  onDeactivateSos(site);
                })
              : const SizedBox.shrink(),
        ],
      )),
    ]);
  }

  Widget _buildRowActionButton(BuildContext context, IconData icon, Color color,
      String tooltip, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => data.length;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;
}

//widget d'état du site

class SiteStatut extends StatefulWidget {
  const SiteStatut({super.key, required this.site});
  final Site site;

  @override
  _SiteStatutState createState() => _SiteStatutState();
}

class _SiteStatutState extends State<SiteStatut> {
  bool _updating = false;
  @override
  Widget build(BuildContext context) {
    return _updating
        ? Loading(size: 28, inline: false)
        : GestureDetector(
            onTap: () {
              if (AuthService.currentManager!.profil!
                  .getModule(ModuleName.SITE)!
                  .validation) {
                actifInactifSite();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.site.actif! ? Colors.green : Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.site.actif! ? Colors.green : Colors.redAccent)
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
                  Icon(
                    widget.site.actif! ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.site.actif! ? "Actif" : "Inactif",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  void actifInactifSite() {
    setState(() {
      _updating = true;
    });

    final bool wasInactive = !widget.site.actif!;
    widget.site.actif = widget.site.actif! ? false : true;

    SiteService().update(widget.site).then((value) {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
      print("Site ${widget.site.name} activé : ${widget.site.actif}");
      // Si le site vient d'être activé (était inactif), générer les pointages
      if (wasInactive && widget.site.actif!) {
        _generateMonthlyPointingsForSite(widget.site);
      }
    }).onError((error, stackTrace) {
      setState(() {
        _updating = false;
      });
    });
  }

  /// Génère les pointages mensuels pour un site spécifique
  /// Cette méthode est appelée en arrière-plan après l'activation
  Future<void> _generateMonthlyPointingsForSite(Site site) async {
    try {
      // Obtenir le début du mois et aujourd'hui
      print("Génération des pointages pour le site ${site.name}");
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final today = DateTime(now.year, now.month, now.day);

      // Obtenir les superviseurs du site
      final List<Supervisor> supervisors = [];
      if (site.supervisor != null) {
        supervisors.add(site.supervisor!);
      }
      if (site.supervisor_2 != null) {
        supervisors.add(site.supervisor_2!);
      }

      if (supervisors.isEmpty) {
        print('Aucun superviseur assigné au site ${site.name}');
        return;
      }

      for (final sup in supervisors) {
        // Générer les pointages pour chaque jour du mois jusqu'à aujourd'hui
        for (DateTime date = startOfMonth;
            date.isBefore(today.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          // Créer le pointage avec la position du site (pas de validation GPS nécessaire)
          final pointingSite = PointingSite(
            site: site,
            supervisor: sup,
            latlng: LatLngModel(
                lat: site.latLng.lat,
                lng: site.latLng.lng), // Position exacte du site
            date: DateTime(
              date.year,
              date.month,
              date.day,
              8, // 8h du matin par défaut
              0, // 0 minutes
            ),
            distance: 0, // Distance 0 car c'est la position exacte du site
          );

          // Enregistrer le pointage (Firebase gérera les doublons avec l'ID unique)
          await PointingSiteService().add(pointingSite);
        }
      }

      print(
          'Pointages générés pour le site ${site.name} du ${startOfMonth.day}/${startOfMonth.month} au ${today.day}/${today.month}');
    } catch (e) {
      print('Erreur lors de la génération des pointages pour ${site.name}: $e');
    }
  }
}

//widget btn delete du site

class DeleteSite extends StatefulWidget {
  const DeleteSite({super.key, required this.site});
  final Site site;
  @override
  _DeleteSiteState createState() => _DeleteSiteState();
}

class _DeleteSiteState extends State<DeleteSite> {
  bool _deleting = false;
  @override
  Widget build(BuildContext context) {
    return _deleting
        ? Loading(size: 28, inline: false)
        : IconButton(
            onPressed: () {
              deleteSite();
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ));
  }

  void deleteSite() {
    setState(() {
      _deleting = true;
    });
    SiteService().delete(widget.site).then((value) {
      setState(() {
        _deleting = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _deleting = false;
      });
    });
  }
}
