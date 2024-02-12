import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spas_web/services/pointerZone.dart';
import 'package:spas_web/zone/zone_site_monthly_pointage.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../search_textField.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../zone_member/zone_pointage_map.dart';

class PointageZone extends StatefulWidget {
  const PointageZone({super.key, required Manager manager});

  @override
  _PointageZoneState createState() => _PointageZoneState();
}

class _PointageZoneState extends State<PointageZone> {
  final PointingZoneService _service = PointingZoneService();
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
                      docs?.map((e) => PointingZone.fromJson(e)).toList();
                  //tri sur la date et le supervieur
                  data?.sort((p1, p2) {
                    var a =
                        "${p1.zoneMember!.UID}${p1.date.year}${p1.date.month}${p1.date.day}";
                    var b =
                        "${p2.zoneMember!.UID}${p2.date.year}${p2.date.month}${p2.date.day}";
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
                        const Text("Pointages Zone"),
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
                              var document = await PointageZoneListToPDF.export(
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
                                                    },
                                                    onSaved: (value) {
                                                      _datePointage = value ??
                                                          DateTime.now();
                                                      setState(() {});
                                                    },
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Tooltip(
                                                    message:
                                                        "Nombre de pointage par chef Zone",
                                                    child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (_) =>
                                                                      SitePointageZoneMap(
                                                                        date:
                                                                            _datePointage,
                                                                      )));
                                                        },
                                                        child: const Text(
                                                            'Nombre de pointage par chef Zone')),
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Tooltip(
                                                    message:
                                                        "Nombre de visite par site",
                                                    child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (_) =>
                                                                      ZoneSiteMonthlyPointage(
                                                                        date:
                                                                            _datePointage,
                                                                      )));
                                                        },
                                                        child: const Text(
                                                            'Nombre de visite par site')),
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
                          label: const Text("Source"),
                          onSort: (index, _) {
                            setState(() {
                              _sortIndex = index;
                              if (_sortAscending == true) {
                                _sortAscending = false;
                                data?.sort((p1, p2) {
                                  return p1.zoneMember!.UID
                                      .compareTo(p2.zoneMember!.UID);
                                });
                              } else {
                                _sortAscending = true;
                                data?.sort((p1, p2) {
                                  return p2.zoneMember!.UID
                                      .compareTo(p1.zoneMember!.UID);
                                });
                              }
                            });
                          }),
                      DataColumn(
                          label: const Text("Zone"),
                          onSort: (index, _) {
                            setState(() {
                              _sortIndex = index;
                              if (_sortAscending == true) {
                                _sortAscending = false;
                                data?.sort((p1, p2) {
                                  return p1.zoneMember!.zone!.codeZone
                                      .compareTo(p2.zoneMember!.zone!.codeZone);
                                });
                              } else {
                                _sortAscending = true;
                                data?.sort((p1, p2) {
                                  return p2.zoneMember!.zone!.codeZone!
                                      .compareTo(p1.zoneMember!.zone!.codeZone);
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
  static List<PointingZone> dataForprint = [];
  List<PointingZone> data;
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
                element.zoneMember!.zone!.name
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                "${element.zoneMember!.firstName} ${element.zoneMember!.lastName}"
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
        DataCell(Text("")),
      ]);
    }
    PointingZone pointage = data[index];
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
          "${pointage.zoneMember!.firstName} ${pointage.zoneMember!.lastName}")),
      DataCell(Text(pointage.zoneMember!.zone?.name ?? "")),
      DataCell(Text(pointage.zoneMember!.phone)),
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
