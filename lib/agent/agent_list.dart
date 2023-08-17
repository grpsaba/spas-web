import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/agent/agent_form.dart';
import 'package:spas_web/search_textField.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../services/agent.dart';
import '../services/export.dart';
import '../services/loading.dart';

class AgentList extends StatefulWidget {
  AgentList({super.key, required Manager this.manager});
  Manager manager;
  @override
  _AgentListState createState() => _AgentListState();
}

class _AgentListState extends State<AgentList> {
  final AgentService _service = AgentService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
//filtre
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
                      ?.map((e) => Agent.fromJson(e))
                      .toList()
                      .where((element) => element.actif == _actif)
                      .toList();

                  return PaginatedDataTable(
                    header: Row(
                      children: [
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
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _keyword = "FIXE";
                            });
                          },
                          child: const Chip(
                              backgroundColor: Colors.green,
                              label: Text(
                                "Fixe",
                                style: TextStyle(color: Colors.white),
                              )),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _keyword = "POINT ZERO";
                            });
                          },
                          child: const Chip(
                              backgroundColor: Colors.redAccent,
                              label: Text(
                                "Point Zéro",
                                style: TextStyle(color: Colors.white),
                              )),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _keyword = "RONDIER";
                            });
                          },
                          child: const Chip(
                              backgroundColor: Colors.deepOrange,
                              label: Text(
                                "Rondier",
                                style: TextStyle(color: Colors.white),
                              )),
                        ),
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
                        widget.manager.profil!.getModule(ModuleName.AGENT)!.add
                            ? Tooltip(
                                message: "Ajouter un Agent",
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => AddAgent(
                                                  agent: Agent(
                                                    type: "SECURITÉ",
                                                    code: '',
                                                    firstName: '',
                                                    lastName: '',
                                                    phone: '',
                                                    email: '',
                                                    tracking: false,
                                                    site: null,
                                                    actif: false,
                                                    categorie: "FIXE",
                                                  ),
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
                        widget.manager.profil!
                                .getModule(ModuleName.AGENT)!
                                .generBadge
                            ? Tooltip(
                                message: "Générer les QR CODES",
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100))),
                                  onPressed: () {
                                    CarteGenerator.generateMiltiCarteAgent(
                                        _DataSource.dataForPrint);
                                  },
                                  child: const Icon(
                                    Icons.badge,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(
                          width: 10,
                        ),
                        widget.manager.profil!
                                .getModule(ModuleName.AGENT)!
                                .print
                            ? IconButton(
                                onPressed: () async {
                                  var document = await AgentListToPDF.export(
                                      _DataSource.dataForPrint);
                                  PdfApi.openFile(document);
                                },
                                icon: const Icon(Icons.print))
                            : const SizedBox.shrink(),
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
                      DataColumn(label: Text("Domaine")),
                      DataColumn(label: Text("Code")),
                      DataColumn(label: Text("Prénom")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Contact")),
                      DataColumn(label: Text("Site")),
                      DataColumn(label: Text("Type")),
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
  static List<Agent> dataForPrint = [];
  List<Agent> data = [];
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
    data = data.where((agent) {
      if (agent.site != null) {
        return (agent.firstName.toLowerCase().contains(keyword.toLowerCase()) ||
            agent.site!.name.toLowerCase().contains(keyword.toLowerCase()) ||
            agent.code.toLowerCase().contains(keyword.toLowerCase()) ||
            agent.phone.toLowerCase().contains(keyword.toLowerCase()));
      } else {
        return agent.firstName.toLowerCase().contains(keyword.toLowerCase()) ||
            agent.code.toLowerCase().contains(keyword.toLowerCase()) ||
            agent.phone.toLowerCase().contains(keyword.toLowerCase()) ||
            agent.categorie!.toLowerCase().contains(keyword.toLowerCase());
      }
    }).toList();
    dataForPrint = data;
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
      ]);
    }
    Agent agent = data[index];

    return DataRow(cells: [
      DataCell(Chip(
        label: Text(
          agent.type,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor:
            agent.type == "SECURITÉ" ? Colors.redAccent : Colors.blue,
      )),
      DataCell(Text(agent.code)),
      DataCell(Text(agent.firstName)),
      DataCell(Text(agent.lastName)),
      DataCell(Text(agent.phone)),
      DataCell(agent.site == null
          ? const SizedBox.shrink()
          : Text(agent.site!.name)),
      DataCell(Chip(
        label: Text(
          agent.categorie == "RONDIER"
              ? "Rondier"
              : agent.categorie == "POINT ZERO"
                  ? "Point 0"
                  : "Fixe",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: agent.categorie == "POINT ZERO"
            ? Colors.redAccent
            : agent.categorie == "RONDIER"
                ? Colors.deepOrange
                : Colors.green,
      )),
      DataCell(AgentStatut(
        agent: agent,
        manager: manager,
      )),
      DataCell(agent.actif!
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
                            builder: (_) => AddAgent(
                                  agent: agent,
                                  update: true,
                                  manager: manager,
                                )));
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100))),
                  onPressed: () {
                    CarteGenerator.generateCarteAgent(agent);
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

//widget d'état de l'agent

class AgentStatut extends StatefulWidget {
  AgentStatut({super.key, required this.agent, required this.manager});
  Agent agent;
  Manager manager;
  @override
  _AgentStatutState createState() => _AgentStatutState();
}

class _AgentStatutState extends State<AgentStatut> {
  bool _updating = false;
  @override
  Widget build(BuildContext context) {
    return _updating
        ? Loading(size: 28, inline: false)
        : GestureDetector(
            onTap: () {
              if (widget.manager.profil!
                  .getModule(ModuleName.AGENT)!
                  .validation) {
                actifInactifAgent();
              }
            },
            child: Chip(
                backgroundColor:
                    widget.agent.actif! ? Colors.green : Colors.redAccent,
                label: Row(
                  children: [
                    widget.manager.profil!
                            .getModule(ModuleName.AGENT)!
                            .validation
                        ? Checkbox(
                            value: widget.agent.actif!,
                            onChanged: ((value) {
                              actifInactifAgent();
                            }))
                        : const SizedBox.shrink(),
                    widget.agent.actif!
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
    widget.agent.actif = widget.agent.actif! ? false : true;
    AgentService().update(widget.agent).then((value) {
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
