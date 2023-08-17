import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/pdf/api/pdf_api.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/site/site_form.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/export.dart';
import '../services/loading.dart';

class SiteList extends StatefulWidget {
  SiteList({super.key, required this.manager});
  Manager manager;
  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SiteList> {
  final SiteService _service = SiteService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
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
    return Scaffold(
      body: SingleChildScrollView(
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

                  //copy to _dataToexport
                  //_dataToexport = data!;
                  return PaginatedDataTable(
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
                        widget.manager.profil!.getModule(ModuleName.SITE)!.add
                            ? Tooltip(
                                message: "Ajouter un site",
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => AddSite(
                                                  site: Site(
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
                                                      actif: false),
                                                  manager: widget.manager,
                                                )));
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )
                            : const SizedBox(),
                        const SizedBox(
                          width: 10,
                        ),
                        widget.manager.profil!
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
                        widget.manager.profil!.getModule(ModuleName.SITE)!.print
                            ? IconButton(
                                onPressed: () async {
                                  var document = await SiteListToPDF.export(
                                      _DataSource.dataToprint);
                                  PdfApi.openFile(document);
                                },
                                icon: const Icon(Icons.print))
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
                    columns: const [
                      DataColumn(label: Text("Code")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Contact")),
                      DataColumn(label: Text("Adresse")),
                      DataColumn(label: Text("NB Agent"), numeric: true),
                      DataColumn(label: Text("Position GPS")),
                      DataColumn(label: Text("Superviseur 1")),
                      DataColumn(label: Text("Superviseur 2")),
                      DataColumn(label: Text("Statut")),
                      DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                        context: context,
                        keyword: _keyword,
                        data: data!,
                        manager: widget.manager),
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
}

class _DataSource extends DataTableSource {
  static List<Site> dataToprint = [];
  List<Site> data;
  String keyword;
  BuildContext context;
  Manager manager;

  _DataSource(
      {required this.context,
      required this.data,
      required this.keyword,
      required this.manager});
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data.where((element) {
      if (element.supervisor_2 != null) {
        return element.name.toLowerCase().contains(keyword.toLowerCase()) ||
            element.supervisor!.firstName
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.supervisor!.phone
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.supervisor_2!.firstName
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.supervisor_2!.phone
                .toLowerCase()
                .contains(keyword.toLowerCase());
      } else {
        return element.name.toLowerCase().contains(keyword.toLowerCase()) ||
            element.supervisor!.firstName
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
        DataCell(Text("")),
      ]);
    }
    Site site = data[index];

    return DataRow(cells: [
      DataCell(Text(site.codeSite)),
      DataCell(Text(site.name)),
      DataCell(Text(site.email)),
      DataCell(Text(site.phone)),
      DataCell(Text(site.adresse)),
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
        manager: manager,
      )),
      DataCell(site.actif!
          ? Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddSite(
                                  site: site,
                                  manager: manager,
                                )));
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100))),
                  onPressed: () {
                    CarteGenerator.generateQrSite(site);
                  },
                  child: const Icon(
                    Icons.badge,
                  ),
                ),
              ],
            )
          : const SizedBox.shrink()),
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

//widget d'état du superviseur

class SiteStatut extends StatefulWidget {
  SiteStatut({super.key, required this.site, required this.manager});
  Site site;
  Manager manager;
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
              if (widget.manager.profil!
                  .getModule(ModuleName.SITE)!
                  .validation) {
                actifInactifAgent();
              }
            },
            child: Chip(
                backgroundColor:
                    widget.site.actif! ? Colors.green : Colors.redAccent,
                label: Row(
                  children: [
                    widget.manager.profil!
                            .getModule(ModuleName.SITE)!
                            .validation
                        ? Checkbox(
                            value: widget.site.actif!,
                            onChanged: ((value) {
                              actifInactifAgent();
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

  void actifInactifAgent() {
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
