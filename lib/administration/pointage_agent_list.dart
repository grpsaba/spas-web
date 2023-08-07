import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spas_web/search_textField.dart';

import '../model.dart';
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rowParPage = defauldRowParPage;
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
                  var data =
                      docs?.map((e) => PointingAgent.fromJson(e)).toList();

                  data = data?.where((element) {
                    return (element.agent.firstName
                                .toLowerCase()
                                .contains(_keyword.toLowerCase()) ||
                            element.agent.code
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
                  return PaginatedDataTable(
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
                            onPress: () {})
                      ],
                    ),
                    actions: [
                      Row(
                        children: [
                          Checkbox(
                              value: _isBefore30,
                              onChanged: (newValue) {
                                setState(() {
                                  _isBefore30 = _isBefore30 ? false : true;
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
                          ExportData.pointageAgentToExcel(_dataToexport,
                              _debut.toString(), _fin.toString(), _isBefore30);
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
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              DateTimeField(
                                                  decoration:
                                                      const InputDecoration(
                                                          hintText:
                                                              "Date début"),
                                                  format: DateFormat.yMd(),
                                                  onChanged: (value) {
                                                    _debut =
                                                        value ?? DateTime.now();
                                                  },
                                                  onShowPicker:
                                                      (context, date) {
                                                    return showDatePicker(
                                                        context: context,
                                                        initialDate:
                                                            DateTime.now(),
                                                        firstDate:
                                                            DateTime(1900),
                                                        lastDate:
                                                            DateTime(3000));
                                                  }),
                                              const SizedBox(height: 10),
                                              DateTimeField(
                                                  decoration:
                                                      const InputDecoration(
                                                          hintText: "Date Fin"),
                                                  format: DateFormat.yMd(),
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
                                                            DateTime.now(),
                                                        firstDate:
                                                            DateTime(1900),
                                                        lastDate:
                                                            DateTime(3000));
                                                  }),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                Navigator.of(context).pop();
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
                    columns: const [
                      DataColumn(label: Text("Période")),
                      DataColumn(label: Text("code")),
                      DataColumn(label: Text("Prénom")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("contact")),
                      DataColumn(label: Text("Présence"), numeric: true),
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
      DataCell(Text(pointages.length.toString())),
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
