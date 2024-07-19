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

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIdex: 2,
      titile: "Gestion des sites",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data = docs
                      ?.map((e) => Site.fromJson(e))
                      .toList()
                      .where((element) => element.actif == _actif)
                      .toList();
                  data!.sort((site1, site2) {
                    return site1.name.compareTo(site2.name);
                  });

                  //copy to _dataToexport
                  //_dataToexport = data!;
                  return PaginatedDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    header: Row(
                      children: [
                        const Text("Liste des  sites"),
                        const SizedBox(
                          width: 10,
                        ),
                        SearchTextField(
                            onSearch: (value) {
                              setState(() {
                                _keyword = value;
                              });
                            },
                            onPress: () {}),
                        const SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _actif = _actif ? false : true;
                            });
                          },
                          child: Chip(
                              backgroundColor:
                                  _actif ? Colors.green : Colors.redAccent,
                              label: Row(
                                children: [
                                  Checkbox(
                                      value: _actif,
                                      onChanged: ((value) {
                                        setState(() {
                                          _actif = _actif ? false : true;
                                        });
                                      })),
                                  _actif
                                      ? const Text(
                                          "Actif",
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : const Text("Inactif",
                                          style:
                                              TextStyle(color: Colors.white)),
                                ],
                              )),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        AuthService.currentManager!.profil!
                                .getModule(ModuleName.SITE)!
                                .add
                            ? Tooltip(
                                message: "Ajouter un site",
                                child: ElevatedButton(
                                  onPressed: () {
                                    Site site = Site(
                                        UID: "",
                                        codeSite: "",
                                        name: "",
                                        adresse: "",
                                        email: "",
                                        phone: "",
                                        latLng: LatLngModel(lat: 0, lng: 0),
                                        token: "",
                                        nbAgent: 0,
                                        supervisor_2: null,
                                        supervisor: null,
                                        actif: false,
                                        zone: null,
                                        dateContrat: null,
                                        nbRonde: null);
                                    context.go('/sites/add', extra: site);
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )
                            : const SizedBox(),
                        const SizedBox(
                          width: 10,
                        ),
                        AuthService.currentManager!.profil!
                                .getModule(ModuleName.SITE)!
                                .generBadge
                            ? Tooltip(
                                message: "Générer les QR CODES",
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100))),
                                  onPressed: () {
                                    CarteGenerator.generateMiltiQrSite(
                                        _DataSource.dataToprint);
                                  },
                                  child: const Icon(
                                    Icons.badge,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        const SizedBox(
                          width: 10,
                        ),
                        AuthService.currentManager!.profil!
                                .getModule(ModuleName.SITE)!
                                .print
                            ? IconButton(
                                onPressed: () async {
                                  var document = await SiteListToPDF.export(
                                      _DataSource.dataToprint);
                                  PdfApi.openFile(document);
                                },
                                icon: const Icon(Icons.print))
                            : const SizedBox(),
                        const SizedBox(
                          width: 5,
                        ),
                        AuthService.currentManager!.profil!
                                .getModule(ModuleName.SITE)!
                                .print
                            ? IconButton(
                                onPressed: () async {
                                  ExportData.SitesToExcel(
                                      _DataSource.dataToprint);
                                },
                                icon: const Icon(Icons.import_export))
                            : const SizedBox(),
                      ],
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
                      const DataColumn(label: Text("Code")),
                      DataColumn(
                          onSort: (columnIndex, _) {
                            setState(() {
                              sortSite(columnIndex, data);
                            });
                          },
                          label: const Text("Nom")),
                      const DataColumn(label: Text("Zone")),
                      const DataColumn(label: Text("Contact")),
                      // const DataColumn(label: Text("Adresse")),
                      const DataColumn(label: Text("NB Agent"), numeric: true),
                      const DataColumn(label: Text("Position GPS")),
                      const DataColumn(label: Text("Superviseur 1")),
                      const DataColumn(label: Text("Superviseur 2")),
                      const DataColumn(label: Text("Statut")),
                      const DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                      context: context,
                      keyword: _keyword,
                      data: data,
                    ),
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
}

class _DataSource extends DataTableSource {
  static List<Site> dataToprint = [];
  List<Site> data;

  String keyword;
  BuildContext context;

  _DataSource({
    required this.context,
    required this.data,
    required this.keyword,
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
      DataCell(Text(site.zone?.name??'')),
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
        children: [
          site.actif!
              ? IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    // ignore: use_build_context_synchronously
                    context.go('/sites/add', extra: site);
                  },
                )
              : const SizedBox.shrink(),
          site.actif!
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100))),
                  onPressed: () {
                    CarteGenerator.generateQrSite(site);
                  },
                  child: const Icon(
                    Icons.badge,
                  ),
                )
              : const SizedBox.shrink(),
          site.actif!
              ? const SizedBox.shrink()
              : AuthService.currentManager!.profil!
                      .getModule(ModuleName.SITE)!
                      .delete
                  ? DeleteSite(site: site)
                  : const SizedBox.shrink()
        ],
      )),
    ]);
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
  SiteStatut({super.key, required this.site, r});
  Site site;

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
            child: Chip(
                backgroundColor:
                    widget.site.actif! ? Colors.green : Colors.redAccent,
                label: Row(
                  children: [
                    AuthService.currentManager!.profil!
                            .getModule(ModuleName.SITE)!
                            .validation
                        ? Checkbox(
                            value: widget.site.actif!,
                            onChanged: ((value) {
                              actifInactifSite();
                            }))
                        : const SizedBox.shrink(),
                    widget.site.actif!
                        ? const Text(
                            "Actif",
                            style: TextStyle(color: Colors.white),
                          )
                        : const Text("Inactif",
                            style: TextStyle(color: Colors.white)),
                  ],
                )),
          );
  }

  void actifInactifSite() {
    setState(() {
      _updating = true;
    });
    widget.site.actif = widget.site.actif! ? false : true;
    SiteService().update(widget.site).then((value) {
      setState(() {
        _updating = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _updating = false;
      });
    });
  }
}

//widget btn delete du site

class DeleteSite extends StatefulWidget {
  DeleteSite({super.key, required this.site});
  Site site;
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
