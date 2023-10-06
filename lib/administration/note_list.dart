import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/search_textField.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/note.dart';

class NoteList extends StatefulWidget {
  const NoteList({super.key, required Manager manager});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<NoteList> {
  final NoteService _service = NoteService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  bool _checked = false;
  int rowParPage = 0;
  int defauldRowParPage = 10;

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
                  var data = docs?.map((e) => Note.fromJson(e)).toList();
                  data?.sort((n1, n2) {
                    return n2.date.compareTo(n1.date);
                  });
                  //copy to _dataToexport

                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Liste des Notes"),
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
                        Tooltip(
                          message: "Imprimer",
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            onPressed: () {
                              NoteListToPDF.printNote(_DataSource.dataToPrint);
                            },
                            child: const Icon(
                              Icons.print,
                            ),
                          ),
                        ),
                        /* const SizedBox(
                          width: 10,
                        ),
                        Tooltip(
                          message: "Ajouter un controleur",
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => AddNote(
                                              manager: Manager(
                                            poste: '',
                                            firstName: '',
                                            lastName: '',
                                            phone: '',
                                            email: '',
                                            role: 'Controleur',
                                            UID: '',
                                            token: '',
                                          ))));
                            },
                            child: const Icon(Icons.add),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),*/
                        /*Tooltip(
                          message: "Générer les QR CODES",
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            onPressed: () {
                              CarteGenerator.generateMiltiCarteAgent(
                                  _dataToexport);
                            },
                            child: const Icon(
                              Icons.badge,
                            ),
                          ),
                        )*/
                      ],
                    ),
                    actions: [
                      Row(
                        children: [
                          Checkbox(
                              value: _checked,
                              onChanged: (value) {
                                _checked = value!;
                                setState(() {});
                              }),
                          _checked
                              ? const Text("Traitées")
                              : const Text("En attente")
                        ],
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
                      )
                    ],
                    rowsPerPage: rowParPage,
                    showFirstLastButtons: true,
                    columns: const [
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Heure")),
                      DataColumn(label: Text("Titre")),
                      DataColumn(label: Text("Source")),
                      DataColumn(label: Text("Etat")),
                      DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                      context: context,
                      keyword: _keyword,
                      checked: _checked,
                      data: data!,
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

class _DataSource extends DataTableSource {
  static List<Note> dataToPrint = [];
  List<Note> data;
  String keyword;
  bool checked;
  BuildContext context;

  _DataSource(
      {required this.context,
      required this.data,
      required this.keyword,
      required this.checked});
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data.reversed.toList();
    data = data.where((note) {
      return (note.viewed == checked) &&
          (note.title.toLowerCase().contains(keyword.toLowerCase()) ||
              note.site!.name.toLowerCase().contains(keyword.toLowerCase()) ||
              note.source.toLowerCase().contains(keyword.toLowerCase()));
    }).toList();
    dataToPrint = data;
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
    Note note = data[index];

    return DataRow(cells: [
      DataCell(Text(note.date.toString().split(" ")[0])),
      DataCell(Text("${note.date.hour}:${note.date.minute}")),
      DataCell(Text(note.title)),
      DataCell(Text(note.source)),
      DataCell(note.viewed
          ? const Chip(
              label: Text("Traitée", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            )
          : const Chip(
              label: Text(
                "En attente",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
            )),
      DataCell(Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              /*Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddManager(
                            manager: manager,
                          )));*/
            },
          ),
          /* ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
            onPressed: () {
               CarteGenerator.generateCarteAgent(agent);
            },
            child: const Icon(
              Icons.badge,
            ),
          ),*/
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
