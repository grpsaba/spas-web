import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/agent.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerRondier.dart';

class PointageRondierList extends StatefulWidget {
  const PointageRondierList({super.key});

  @override
  _State createState() => _State();
}

class _State extends State<PointageRondierList> {
  final PointingRondierService _service = PointingRondierService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
  DateTime _fin = DateTime.now().add(const Duration(days: 1));


  int rowParPage = 0;
  int defauldRowParPage = 10;
  bool _sortAscending = true;
  int _sortIndex = 0;

  //compter le nombre de jours ou l'agent à été pointé
  Future<List<Map<String, dynamic>>> compteNbjour(List<PointingRondier> pointages) async{
    List<Agent> listAgent = await AgentService().allFuture();
    List<Map<String, dynamic>> _dataToexport = [];
    List<Agent>? agents =
    pointages.map((e) => e.agent).toSet().toList();

    for (Agent agent in agents ?? []) {
      int index = listAgent.indexWhere((el)=>el==agent);
      agent = index!=-1?listAgent[index]:agent;
      var listpointage = pointages
          .where((element) => element.agent.code == agent.code)
          .toSet()
          .toList();
      _dataToexport.add({"agent": agent, "pointages": listpointage ?? []});
    }
   return _dataToexport;
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rowParPage = defauldRowParPage;
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 17,
      title: "Pointages Rondier",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data =
                      docs?.map((e) => PointingRondier.fromJson(e)).toList()??[];
                  //données de présence avec l'heure
                   data = data
                      .where((element) => (element.date.isAfter(_debut) &&
                          element.date
                              .isBefore(_fin.add(const Duration(days: 1)))))
                      .toList();

                  //filtrage des données de comptage de présence
                  data = data.where((element) {
                    return ("${element.agent.firstName} ${element.agent.lastName}"
                                .toLowerCase()
                                .contains(_keyword.toLowerCase()) ||
                            element.agent.code
                                .toLowerCase()
                                .contains(_keyword.toLowerCase())||(element.site.zone?.codeZone??'')
                        .toLowerCase()
                        .contains(_keyword.toLowerCase()));
                  }).toList();


                  return PaginatedDataTable(
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

                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () async {

                                var document =
                                    await PointageRondierListToPDF.export(
                                        data);
                                PdfApi.openFile(document);
                              },
                              child: const Icon(Icons.print),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                List<Map<String, dynamic>> dataToexport = await compteNbjour(data);
                                var document =
                                await JoursPointageRondierToPDF.export(
                                    dataToexport,sart: _debut,end: _fin);
                                PdfApi.downLoad(document);
                              },
                              child: const Row(children: [
                                 Icon(Icons.download),
                                 SizedBox(
                                  width: 5,
                                ),
                                Text("Nombre jours de pointage")
                              ],),
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
                                      data.sort((P1, P2) {
                                        return P1.date.compareTo(P2.date);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      data.sort((P1, P2) {
                                        return P2.date.compareTo(P1.date);
                                      });
                                    }
                                  });
                                }),
                            const DataColumn(label: Text("Heure")),
                            const DataColumn(label: Text("Site")),
                            const DataColumn(label: Text("code")),
                            DataColumn(
                                label: const Text("Prénom"),
                                onSort: (index, ascending) {
                                  setState(() {
                                    _sortIndex = index;
                                    if (_sortAscending == true) {
                                      _sortAscending = false;
                                      data.sort((P1, P2) {
                                        return P1.agent.firstName
                                            .compareTo(P2.agent.firstName);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      data.sort((P1, P2) {
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
                                      data.sort((P1, P2) {
                                        return P1.agent.lastName
                                            .compareTo(P2.agent.lastName);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      data.sort((P1, P2) {
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
                                      data.sort((P1, P2) {
                                        return P1.agent.phone
                                            .compareTo(P2.agent.phone);
                                      });
                                    } else {
                                      _sortAscending = true;
                                      data.sort((P1, P2) {
                                        return P2.agent.phone
                                            .compareTo(P1.agent.phone);
                                      });
                                    }
                                  });
                                }),
                            //const DataColumn(label: Text("Domaine")),
                          ],
                          source: _DataPresence(
                            context: context,
                            data: data,
                            keyword: _keyword,
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
}



class _DataPresence extends DataTableSource {
  List<PointingRondier> data;

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
            element.agent.phone.toLowerCase().contains(keyword.toLowerCase()))
        .toList();

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

    PointingRondier pointage = data[index];
    return DataRow(cells: [
      DataCell(Chip(
          side: BorderSide.none,
          label: Text(pointage.date.toString().split(" ")[0]))),
      DataCell(Chip(
        label: Text(
            "${pointage.date.hour}:${pointage.date.minute}:${pointage.date.second}"),
      )),
      DataCell(Text(pointage.site.name)),
      DataCell(Text(pointage.agent.code)),
      DataCell(Text(pointage.agent.firstName)),
      DataCell(Text(pointage.agent.lastName)),
      DataCell(Text(pointage.agent.phone)),

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
