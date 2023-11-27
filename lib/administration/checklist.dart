import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../search_textField.dart';
import '../services/CheckList.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerTool.dart';

class CheckListView extends StatefulWidget {
  const CheckListView({super.key, required Manager manager});

  @override
  _CheckListViewState createState() => _CheckListViewState();
}

class _CheckListViewState extends State<CheckListView> {
  final CheckListService _service = CheckListService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
  DateTime _fin = DateTime.now().add(const Duration(days: 1));
  int rowParPage = 0;
  int defauldRowParPage = 10;
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
                  var lst = jsonDecode(jsonEncode(docs));
                  //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

                  var data = docs?.map((e) => CheckList.fromJson(e)).toList();

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
                    header: Row(
                      children: [
                        const Text("Checklist"),
                        const SizedBox(
                          width: 10,
                        ),
                        SearchTextField(
                            controller: _texController,
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
                              var document = await PointageToolListToPDF.export(
                                  _DataSource.dataForprint);
                              PdfApi.openFile(document);
                            },
                            icon: const Icon(Icons.print)),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _keyword = "RAS";
                            _texController.text = _keyword;
                            setState(() {});
                          },
                          child: const Chip(
                              backgroundColor: Colors.green,
                              label: Text(
                                "RAS",
                                style: TextStyle(color: Colors.white),
                              )),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _keyword = "MAUVAIS";
                            _texController.text = _keyword;
                            setState(() {});
                          },
                          child: const Chip(
                              backgroundColor: Colors.orangeAccent,
                              label: Text(
                                "MAUVAIS",
                                style: TextStyle(color: Colors.black),
                              )),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _keyword = "CRITIQUE";
                            _texController.text = _keyword;
                            setState(() {});
                          },
                          child: const Chip(
                              backgroundColor: Colors.redAccent,
                              label: Text(
                                "CRITIQUE",
                                style: TextStyle(color: Colors.black),
                              )),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            _keyword = "ABSENT";
                            _texController.text = _keyword;
                            setState(() {});
                          },
                          child: const Chip(
                              backgroundColor: Colors.white24,
                              label: Text(
                                "ABSENT",
                                style: TextStyle(color: Colors.black),
                              )),
                        )
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
                    columns: const [
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Heure")),
                      DataColumn(label: Text("Matériel")),
                      DataColumn(label: Text("Site")),
                      DataColumn(label: Text("Superviseur")),
                      DataColumn(label: Text("Contact")),
                      DataColumn(label: Text("Statut")),
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
  static List<CheckList> dataForprint = [];
  List<CheckList> data;
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
            (element.cattool.label
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                element.cattool.department!.label
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                element.status.toLowerCase().contains(keyword.toLowerCase()) ||
                "${element.supervisor?.firstName ?? ""}${element.supervisor?.lastName ?? ""}"
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                element.site.name
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (element.supervisor?.phone ?? "")
                    .toLowerCase()
                    .contains(keyword.toLowerCase())) &&
            (element.date.isAfter(debut) &&
                element.date.isBefore(fin.add(const Duration(days: 1)))))
        .toList();
    //sort the data
    data.sort((p1, p2) {
      return p1.site.name.compareTo(p2.site.name);
    });
    dataForprint = data;
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
    CheckList checkList = data[index];
    //Site site = data[index]["site"];
    // List<PointingSite> pointages = data[index]["pointages"];
    return DataRow(cells: [
      DataCell(Text(checkList.date.toString().split(" ")[0])),
      DataCell(Text(
          "${checkList.date.hour}:${checkList.date.minute}:${checkList.date.second}")),
      DataCell(Text(checkList.cattool.label)),
      DataCell(Text(checkList.site.name)),
      DataCell(Text(
          "${checkList.supervisor?.firstName ?? ""} ${checkList.supervisor?.lastName ?? ""}")),
      DataCell(Text(checkList.supervisor?.phone ?? "")),
      DataCell(checkList.status == "RAS"
          ? Chip(
              backgroundColor: Colors.green,
              label: Text(
                checkList.status,
                style: const TextStyle(color: Colors.white),
              ))
          : checkList.status == "CRITIQUE"
              ? Chip(
                  backgroundColor: Colors.redAccent,
                  label: Text(checkList.status,
                      style: const TextStyle(color: Colors.white)))
              : checkList.status == "ABSENT"
                  ? Chip(
                      backgroundColor: Colors.white24,
                      label: Text(checkList.status))
                  : Chip(
                      backgroundColor: Colors.orangeAccent,
                      label: Text(checkList.status))),
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

class ToolStatusAction extends StatefulWidget {
  ToolStatusAction({super.key, required this.pointing});
  PointingTools pointing;
  @override
  _ToolStatusActionState createState() => _ToolStatusActionState();
}

class _ToolStatusActionState extends State<ToolStatusAction> {
  bool _pointing = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pointing
            ? Loading(size: 34, inline: false)
            : Checkbox(
                value: widget.pointing.supported,
                onChanged: (value) {
                  if (widget.pointing.supported == false) {
                    _pointing = true;
                    widget.pointing.supported = true;
                    PointingToolService().update(widget.pointing).then((value) {
                      setState(() {
                        _pointing = false;
                      });
                    }).onError((error, stackTrace) {
                      setState(() {
                        _pointing = false;
                      });
                    });
                  }
                }),
        widget.pointing.supported
            ? const SizedBox.shrink()
            : const Text("prise en charge")
      ],
    );
  }
}
