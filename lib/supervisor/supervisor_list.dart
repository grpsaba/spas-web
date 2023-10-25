import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/accueil/supervisor_maps.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/supervisor/supervisor_form.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/agent.dart';
import '../services/loading.dart';
import '../services/site.dart';
import '../services/supervisor.dart';

class SupervisorList extends StatefulWidget {
  SupervisorList({super.key, required this.manager});
  Manager manager;
  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SupervisorList> {
  final SupervisorService _service = SupervisorService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<Supervisor> _dataToexport = [];
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
                  var data = docs?.map((e) => Supervisor.fromJson(e)).toList();

                  //copy to _dataToexport
                  _dataToexport = data!;
                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Superviseurs"),
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
                          width: 10,
                        ),
                        widget.manager.profil!
                                .getModule(ModuleName.SUPERVISEUR)!
                                .add
                            ? Tooltip(
                                message: "Ajouter un superviseur",
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => AddSupervisor(
                                                  supervisor: Supervisor(
                                                      code: '',
                                                      firstName: '',
                                                      lastName: '',
                                                      phone: '',
                                                      email: '',
                                                      tracking: false,
                                                      UID: '',
                                                      token: '',
                                                      latlng: null,
                                                      actif: false,
                                                      department: null),
                                                  manager: widget.manager,
                                                )));
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(
                          width: 10,
                        ),
                        Tooltip(
                          message: "Dernières Position des superviseurs",
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SupervisorMaps()));
                            },
                            child: const Icon(Icons.location_on),
                          ),
                        )
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
                      )
                    ],
                    rowsPerPage: rowParPage,
                    showFirstLastButtons: true,
                    columns: const [
                      //DataColumn(label: Text("Code")),
                      DataColumn(label: Text("Prénom")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Contact")),
                      DataColumn(label: Text("email")),
                      DataColumn(label: Text("Sites"), numeric: true),
                      DataColumn(label: Text("Agents"), numeric: true),
                      DataColumn(label: Text("Position")),
                      DataColumn(label: Text("Statut")),
                      DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                        context: context,
                        keyword: _keyword,
                        data: data,
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
  List<Supervisor> data;
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
    data = data.where((supervisor) {
      return supervisor.firstName
              .toLowerCase()
              .contains(keyword.toLowerCase()) ||
          supervisor.lastName.toLowerCase().contains(keyword.toLowerCase()) ||
          supervisor.code.toLowerCase().contains(keyword.toLowerCase()) ||
          supervisor.phone.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
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
      ]);
    }
    Supervisor supervisor = data[index];

    return DataRow(cells: [
      //DataCell(Text(supervisor.code)),
      DataCell(Text(supervisor.firstName)),
      DataCell(Text(supervisor.lastName)),
      DataCell(Text(supervisor.phone)),
      DataCell(Text(supervisor.email)),
      DataCell(nbSite(supervisor)),
      DataCell(nbAgent(supervisor)),
      DataCell(Text(
          "${supervisor.latlng?.lat ?? ""} ; ${supervisor.latlng?.lng ?? ""}")),
      DataCell(SuperviseurStatut(
        superviseur: supervisor,
        manager: manager,
      )),
      DataCell(
        supervisor.actif!
            ? IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  // ignore: use_build_context_synchronously
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddSupervisor(
                                supervisor: supervisor,
                                manager: manager,
                              )));
                },
              )
            : const SizedBox.shrink(),
      ),
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

  Widget nbAgent(Supervisor supervisor) {
    return FutureBuilder(
        future: AgentService().allBySupervisor(supervisor.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.hasData) {
            var data = snapshot.data;
            return Text("${data?.length}");
          } else {
            return const SizedBox.shrink();
          }
        });
  }

  Widget nbSite(Supervisor supervisor) {
    return FutureBuilder(
        future: SiteService().allBySupervisor(supervisor.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.hasData) {
            var data = snapshot.data;
            return Text("${data?.length}");
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}

//widget d'état du superviseur

class SuperviseurStatut extends StatefulWidget {
  SuperviseurStatut(
      {super.key, required this.superviseur, required this.manager});
  Supervisor superviseur;
  Manager manager;
  @override
  _SuperviseurStatutState createState() => _SuperviseurStatutState();
}

class _SuperviseurStatutState extends State<SuperviseurStatut> {
  bool _updating = false;
  @override
  Widget build(BuildContext context) {
    return _updating
        ? Loading(size: 28, inline: false)
        : GestureDetector(
            onTap: () {
              if (widget.manager.profil!
                  .getModule(ModuleName.SUPERVISEUR)!
                  .validation) {
                actifInactifAgent();
              }
            },
            child: Chip(
                backgroundColor:
                    widget.superviseur.actif! ? Colors.green : Colors.redAccent,
                label: Row(
                  children: [
                    widget.manager.profil!
                            .getModule(ModuleName.SUPERVISEUR)!
                            .validation
                        ? Checkbox(
                            value: widget.superviseur.actif!,
                            onChanged: ((value) {
                              actifInactifAgent();
                            }))
                        : const SizedBox.shrink(),
                    widget.superviseur.actif!
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
    widget.superviseur.actif = widget.superviseur.actif! ? false : true;
    SupervisorService().update(widget.superviseur).then((value) {
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
