import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spas_web/supervisor/site_pointage_map.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../search_textField.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerSite.dart';

class PointageSiteList extends StatefulWidget {
  const PointageSiteList({super.key, required Manager manager});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<PointageSiteList> {
  final PointingSiteService _service = PointingSiteService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  DateTime _datePointage = DateTime.now();
  DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
  DateTime _fin = DateTime.now().add(const Duration(days: 1));
  int rowParPage = 0;
  int defauldRowParPage = 10;
  int _sortIndex = 0;
  bool _sortAscending = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rowParPage = defauldRowParPage;
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
                  //var lst = jsonDecode(jsonEncode(docs));
                  //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

                  var data =
                      docs?.map((e) => PointingSite.fromJson(e)).toList();
                  //tri sur la date et le supervieur
                  data?.sort((p1, p2) {
                    var a =
                        "${p1.supervisor!.UID}${p1.date.year}${p1.date.month}${p1.date.day}";
                    var b =
                        "${p2.supervisor!.UID}${p2.date.year}${p2.date.month}${p2.date.day}";
                    return a.compareTo(b);
                  });

                  /* List<Map<String, dynamic>> pointages = [];
                  var sitesList = data?.map((e) => e.site).toSet().toList();
                  //elimination des doublons

                  for (Site site in sitesList ?? []) {
                    var Listpointage = data
                        ?.where((element) => element.site.UID == site.UID)
                        .toList();

                    pointages
                        .add({"site": site, "pointages": Listpointage ?? []});
                  }
*/
                  return PaginatedDataTable(
                    rowsPerPage: rowParPage,
                    sortAscending: _sortAscending,
                    sortColumnIndex: _sortIndex,
                    header: Row(
                      children: [
                        const Text("Pointages Site"),
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
                        IconButton(
                            onPressed: () async {
                              var document = await PointageSiteListToPDF.export(
                                  _DataSource.dataForprint);
                              PdfApi.openFile(document);
                            },
                            icon: const Icon(Icons.print)),
                        const SizedBox(
                          width: 10,
                        ),
                        //button de la page pointage par superviseur
                        IconButton(
                            tooltip: "Télecharger le tableau de pointage",
                            onPressed: () async {
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
                                                  "Sélctionner une date",
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
                                                              hintText: "Date"),
                                                      format: DateFormat.yMd(),
                                                      onChanged: (value) {
                                                        _datePointage = value ??
                                                            DateTime.now();
                                                        setState(() {});
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
                                                  const SizedBox(height: 20),
                                                  SitePointageMap(
                                                    date: _datePointage,
                                                  )
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 30),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            },
                            icon: const Icon(Icons.calendar_today)),
                      ],
                    ),
                    actions: [
                      /* ElevatedButton(
                        onPressed: () {
                          ExportData.pointageSiteToExcel(
                              pointages, _debut.toString(), _fin.toString());
                        },
                        child: const Icon(Icons.download),
                      ),
                      const SizedBox(
                        height: 20,
                      ),*/
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
                                                    ;
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
                    columns: [
                      DataColumn(
                          label: const Text("Date"),
                          onSort: (index, _) {
                            setState(() {
                              _sortIndex = index;
                              if (_sortAscending == true) {
                                _sortAscending = false;
                                data?.sort((p1, p2) {
                                  return p1.date.compareTo(p2.date);
                                });
                              } else {
                                _sortAscending = true;
                                data?.sort((p1, p2) {
                                  return p2.date.compareTo(p1.date);
                                });
                              }
                            });
                          }),
                      const DataColumn(label: Text("Heure")),
                      DataColumn(
                          label: const Text("Site"),
                          onSort: (index, _) {
                            setState(() {
                              _sortIndex = index;
                              if (_sortAscending == true) {
                                _sortAscending = false;
                                data?.sort((p1, p2) {
                                  return p1.site.UID.compareTo(p2.site.UID);
                                });
                              } else {
                                _sortAscending = true;
                                data?.sort((p1, p2) {
                                  return p2.site.UID.compareTo(p1.site.UID);
                                });
                              }
                            });
                          }),
                      DataColumn(
                          label: const Text("Superviseur"),
                          onSort: (index, _) {
                            setState(() {
                              _sortIndex = index;
                              if (_sortAscending == true) {
                                _sortAscending = false;
                                data?.sort((p1, p2) {
                                  return p1.supervisor!.UID
                                      .compareTo(p2.supervisor!.UID);
                                });
                              } else {
                                _sortAscending = true;
                                data?.sort((p1, p2) {
                                  return p2.supervisor!.UID
                                      .compareTo(p1.supervisor!.UID);
                                });
                              }
                            });
                          }),
                      const DataColumn(label: Text("Contact")),
                    ],
                    source: _DataSource(
                        context: context,
                        data: data!,
                        debut: _debut,
                        fin: _fin,
                        keyword: _keyword),
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
  static List<PointingSite> dataForprint = [];
  List<PointingSite> data;
  DateTime debut;
  DateTime fin;
  String keyword;
  BuildContext context;

  _DataSource(
      {required this.context,
      required this.data,
      required this.debut,
      required this.fin,
      required this.keyword});
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data
        .where((element) =>
            (element.site.name.toLowerCase().contains(keyword.toLowerCase()) ||
                element.supervisor!.firstName
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                element.supervisor!.lastName
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                element.supervisor!.phone
                    .toLowerCase()
                    .contains(keyword.toLowerCase())) &&
            (element.date.isAfter(debut) &&
                element.date.isBefore(fin.add(const Duration(days: 1)))))
        .toList();
    //sort the data
    /*data.sort((p1, p2) {
      return p1.site.name.compareTo(p2.site.name);
    });*/
    dataForprint = data;
    if (index >= data.length) {
      return const DataRow(cells: [
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    PointingSite pointage = data[index];
    //Site site = data[index]["site"];
    // List<PointingSite> pointages = data[index]["pointages"];
    return DataRow(cells: [
      DataCell(Chip(
        label: Text(pointage.date.toString().split(" ")[0]),
        side: BorderSide.none,
      )),
      DataCell(Chip(
        label: Text(
            "${pointage.date.hour}:${pointage.date.minute}:${pointage.date.second}"),
        backgroundColor: Colors.orangeAccent,
      )),
      DataCell(Text(pointage.site.name)),
      DataCell(Text(
          "${pointage.supervisor?.firstName} ${pointage.supervisor?.lastName}")),
      DataCell(Text(pointage.supervisor!.phone)),
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
