import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerAgent.dart';

class PointageAgentList extends StatefulWidget {
  const PointageAgentList({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<PointageAgentList> {
  final PointingAgentService _service = PointingAgentService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
  DateTime _fin = DateTime.now().add(const Duration(days: 1));
  bool _isBefore30 = true;
  List<Map<String, dynamic>> _dataToexport = [];
  int rowParPage = 0;
  int defauldRowParPage = 10;
  bool _sortAscending = true;
  int _sortIndex = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rowParPage = defauldRowParPage;
  }

  //basculer entre les tables comptage de presence et liste de presence
  bool _isPresenceList = false;
  void toogleTable() {
    _isPresenceList = _isPresenceList ? false : true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIdex: 7,
      titile: "Pointages Agent",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data =
                      docs?.map((e) => PointingAgent.fromJson(e)).toList();
                  //données de présence avec l'heure
                  var pointagesPresence = data
                      ?.where((element) => (element.date.isAfter(_debut) &&
                          element.date
                              .isBefore(_fin.add(const Duration(days: 1)))))
                      .toList();

                  //filtrage des données de comptage de présence
                  data = data?.where((element) {
                    return (element.agent.firstName
                                .toLowerCase()
                                .contains(_keyword.toLowerCase()) ||
                            element.agent.code
                                .toLowerCase()
                                .contains(_keyword.toLowerCase()) ||
                            element.agent.typeAgent!.label
                                .toLowerCase()
                                .contains(_keyword.toLowerCase()) ||
                            element.agent.department!.label
                                .toLowerCase()
                                .contains(_keyword.toLowerCase())) &&
                        (element.date.isAfter(_debut) &&
                            element.date
                                .isBefore(_fin.add(const Duration(days: 1))));
                  }).toList();

                  List<Map<String, dynamic>> pointages = [];
                  List<Agent>? agents =
                      data?.map((e) => e.agent).toSet().toList();

                  for (Agent agent in agents ?? []) {
                    var Listpointage = data
                        ?.where((element) => element.agent.code == agent.code)
                        .toSet()
                        .toList();
                    pointages
                        .add({"agent": agent, "pointages": Listpointage ?? []});
                  }
                  if (_isBefore30) {
                    pointages = pointages.where((element) {
                      List<PointingAgent> pointages = element["pointages"];
                      return pointages.length < 30;
                    }).toList();
                  } else {
                    pointages = pointages.where((element) {
                      List<PointingAgent> pointages = element["pointages"];
                      return pointages.length > 30;
                    }).toList();
                  }
                  //copy to _dataToexport
                  _dataToexport = pointages;
                  return _isPresenceList
                      ? PaginatedDataTable(
                          sortAscending: _sortAscending,
                          sortColumnIndex: _sortIndex,
                          rowsPerPage: rowParPage,
                          header: Row(
                            children: [
                              const Text("Pointages Agent"),
                              const SizedBox(
                                width: 10,
                              ),
                              SearchTextField(
                                  onSearch: (value) {
                                    _keyword = value;
                                    setState(() {});
                                  },
                                  onPress: () {}),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    toogleTable();
                                  },
                                  child: Text(_isPresenceList
                                      ? "Comptage de présence"
                                      : "Liste de présence"))
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () async {
                                var document =
                                    await PointageAgentListToPDF.export(
                                        _DataPresence.dataToExport);
                                PdfApi.openFile(document);
                              },
                              child: const Icon(Icons.print),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        content: Container(
                                          height: 300,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.0)),
                                          child: Column(
                                            children: [
                                              Container(
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "Sélctionner une période",
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .primaryColor),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    DateTimeField(
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    "Date début"),
                                                        format:
                                                            DateFormat.yMd(),
                                                        onChanged: (value) {
                                                          _debut = value ??
                                                              DateTime.now();
                                                        },
                                                        onShowPicker:
                                                            (context, date) {
                                                          return showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  DateTime
                                                                      .now(),
                                                              firstDate:
                                                                  DateTime(
                                                                      1900),
                                                              lastDate:
                                                                  DateTime(
                                                                      3000));
                                                        }),
                                                    const SizedBox(height: 10),
                                                    DateTimeField(
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    "Date Fin"),
                                                        format:
                                                            DateFormat.yMd(),
                                                        onChanged: (value) {
                                                          _fin = value ??
                                                              DateTime.now().add(
                                                                  const Duration(
                                                                      days: 1));
                                                        },
                                                        onShowPicker:
                                                            (context, date) {
                                                          return showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  DateTime
                                                                      .now(),
                                                              firstDate:
                                                                  DateTime(
                                                                      1900),
                                                              lastDate:
                                                                  DateTime(
                                                                      3000));
                                                        }),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 30),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      Navigator.of(context)
                                                          .pop();
                                                    });
                                                  },
                                                  child: const Text("Valider"))
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              child: const Icon(Icons.calendar_month),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
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
                          showFirstLastButtons: true,
                          columns: [
                            DataColumn(
                                label: const Text("Date"),
                                onSort: (index, _) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P1.date.compareTo(P2.date);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P2.date.compareTo(P1.date);
                                      });
                                    }
                                  });
                                }),
                            const DataColumn(label: Text("Heure")),
                            const DataColumn(label: Text("code")),
                            DataColumn(
                                label: const Text("Prénom"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P1.agent.firstName
                                            .compareTo(P2.agent.firstName);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P2.agent.firstName
                                            .compareTo(P1.agent.firstName);
                                      });
                                    }
                                  });
                                }),
                            DataColumn(
                                label: const Text("Nom"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P1.agent.lastName
                                            .compareTo(P2.agent.lastName);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P2.agent.lastName
                                            .compareTo(P1.agent.lastName);
                                      });
                                    }
                                  });
                                }),
                            DataColumn(
                                label: const Text("contact"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P1.agent.phone
                                            .compareTo(P2.agent.phone);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointagesPresence?.sort((P1, P2) {
                                        return P2.agent.phone
                                            .compareTo(P1.agent.phone);
                                      });
                                    }
                                  });
                                }),
                            const DataColumn(label: Text("Domaine")),
                          ],
                          source: _DataPresence(
                            context: context,
                            data: pointagesPresence ?? [],
                            keyword: _keyword,
                          ),
                        )
                      : PaginatedDataTable(
                          sortColumnIndex: _sortIndex,
                          sortAscending: _sortAscending,
                          rowsPerPage: rowParPage,
                          header: Row(
                            children: [
                              const Text("Pointages Agent"),
                              const SizedBox(
                                width: 10,
                              ),
                              SearchTextField(
                                  onSearch: (value) {
                                    _keyword = value;
                                    setState(() {});
                                  },
                                  onPress: () {}),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    toogleTable();
                                  },
                                  child: Text(_isPresenceList
                                      ? "Comptage de présence"
                                      : "Liste de présence"))
                            ],
                          ),
                          actions: [
                            Row(
                              children: [
                                Checkbox(
                                    value: _isBefore30,
                                    onChanged: (newValue) {
                                      setState(() {
                                        _isBefore30 =
                                            _isBefore30 ? false : true;
                                      });
                                    }),
                                const Text(
                                  "Nombre de jours inferieur à 30",
                                  style: TextStyle(fontSize: 12),
                                )
                              ],
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ExportData.pointageAgentToExcel(
                                    _dataToexport,
                                    _debut.toString(),
                                    _fin.toString(),
                                    _isBefore30);
                              },
                              child: const Icon(Icons.download),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        content: Container(
                                          height: 300,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.0)),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  "Sélctionner une période",
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    DateTimeField(
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    "Date début"),
                                                        format:
                                                            DateFormat.yMd(),
                                                        onChanged: (value) {
                                                          _debut = value ??
                                                              DateTime.now();
                                                        },
                                                        onShowPicker:
                                                            (context, date) {
                                                          return showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  DateTime
                                                                      .now(),
                                                              firstDate:
                                                                  DateTime(
                                                                      1900),
                                                              lastDate:
                                                                  DateTime(
                                                                      3000));
                                                        }),
                                                    const SizedBox(height: 10),
                                                    DateTimeField(
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    "Date Fin"),
                                                        format:
                                                            DateFormat.yMd(),
                                                        onChanged: (value) {
                                                          _fin = value ??
                                                              DateTime.now().add(
                                                                  const Duration(
                                                                      days: 1));
                                                        },
                                                        onShowPicker:
                                                            (context, date) {
                                                          return showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  DateTime
                                                                      .now(),
                                                              firstDate:
                                                                  DateTime(
                                                                      1900),
                                                              lastDate:
                                                                  DateTime(
                                                                      3000));
                                                        }),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 30),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      Navigator.of(context)
                                                          .pop();
                                                    });
                                                  },
                                                  child: const Text("Valider"))
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              child: const Icon(Icons.calendar_month),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
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
                          showFirstLastButtons: true,
                          columns: [
                            const DataColumn(label: Text("Période")),
                            const DataColumn(label: Text("code")),
                            DataColumn(
                                label: const Text("Prénom"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointages.sort((P1, P2) {
                                        Agent agent1 = P1["agent"];
                                        Agent agent2 = P2["agent"];
                                        return agent1.firstName
                                            .compareTo(agent2.firstName);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointages.sort((P1, P2) {
                                        Agent agent1 = P1["agent"];
                                        Agent agent2 = P2["agent"];
                                        return agent2.firstName
                                            .compareTo(agent1.firstName);
                                      });
                                    }
                                  });
                                }),
                            DataColumn(
                                label: const Text("Nom"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointages.sort((P1, P2) {
                                        Agent agent1 = P1["agent"];
                                        Agent agent2 = P2["agent"];
                                        return agent1.lastName
                                            .compareTo(agent2.lastName);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointages.sort((P1, P2) {
                                        Agent agent1 = P1["agent"];
                                        Agent agent2 = P2["agent"];
                                        return agent2.lastName
                                            .compareTo(agent1.lastName);
                                      });
                                    }
                                  });
                                }),
                            DataColumn(
                                label: const Text("contact"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      pointages.sort((P1, P2) {
                                        Agent agent1 = P1["agent"];
                                        Agent agent2 = P2["agent"];
                                        return agent1.phone
                                            .compareTo(agent2.phone);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      pointages.sort((P1, P2) {
                                        Agent agent1 = P1["agent"];
                                        Agent agent2 = P2["agent"];
                                        return agent2.phone
                                            .compareTo(agent1.phone);
                                      });
                                    }
                                  });
                                }),
                            const DataColumn(label: Text("Domaine")),
                            const DataColumn(
                                label: Text("Présence"), numeric: true),
                          ],
                          source: _DataSource(
                              context: context,
                              data: pointages,
                              debut: _debut,
                              fin: _fin),
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
  List<Map<String, dynamic>> data;
  DateTime debut;
  DateTime fin;
  BuildContext context;

  _DataSource(
      {required this.context,
      required this.data,
      required this.debut,
      required this.fin});
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow

    if (index >= data.length) {
      return const DataRow(cells: [
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    Agent agent = data[index]["agent"];
    List<PointingAgent> pointages = data[index]["pointages"];
    return DataRow(cells: [
      DataCell(Text(
          "${debut.toString().split(" ")[0]} - ${fin.toString().split(" ")[0]}")),
      DataCell(Text(agent.code)),
      DataCell(Text(agent.firstName)),
      DataCell(Text(agent.lastName)),
      DataCell(Text(agent.phone)),
      DataCell(Chip(label: Text(agent.department?.label ?? "Unconnu"))),
      DataCell(Chip(
        label: Text(pointages.length.toString()),
        backgroundColor: Colors.orangeAccent,
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

class _DataPresence extends DataTableSource {
  List<PointingAgent> data;
  static List<PointingAgent> dataToExport = [];
  String keyword;

  BuildContext context;

  _DataPresence({
    required this.context,
    required this.data,
    required this.keyword,
  });
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data.sort((p1, p2) {
      return p1.date.compareTo(p2.date);
    });
    data = data
        .where((element) =>
            element.agent.firstName
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.agent.code.toLowerCase().contains(keyword.toLowerCase()) ||
            element.agent.phone.toLowerCase().contains(keyword.toLowerCase()) ||
            element.agent.typeAgent!.label
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
            element.agent.department!.label
                .toLowerCase()
                .contains(keyword.toLowerCase()))
        .toList();
    dataToExport = data;
    if (index >= data.length) {
      return const DataRow(cells: [
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }

    PointingAgent pointage = data[index];
    return DataRow(cells: [
      DataCell(Chip(
          side: BorderSide.none,
          label: Text(pointage.date.toString().split(" ")[0]))),
      DataCell(Chip(
        label: Text(
            "${pointage.date.hour}:${pointage.date.minute}:${pointage.date.second}"),
      )),
      DataCell(Text(pointage.agent.code)),
      DataCell(Text(pointage.agent.firstName)),
      DataCell(Text(pointage.agent.lastName)),
      DataCell(Text(pointage.agent.phone)),
      DataCell(Chip(
        label: Text(pointage.agent.department?.label ?? "Unconnu"),
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
