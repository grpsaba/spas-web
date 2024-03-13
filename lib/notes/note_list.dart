import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';

import '../generated/assets.dart';
import '../model.dart';
import '../search_textField.dart';
import '../services/department.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/note.dart';
import 'note_contant.dart';

class NoteList extends StatefulWidget {
  const NoteList({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<NoteList> {
  final NoteService _service = NoteService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  String _department = "";
  List<Note> _dataToprint = [];
  int rowParPage = 0;
  int defauldRowParPage = 10;
  int _selectedIndex = 0;
  Note? _selectedNote;
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
    return PageModel(
      pageIdex: 9,
      titile: "Gestion des notes",
      child: SingleChildScrollView(
          child: Row(
        children: [
          Container(
            width: 500,
            padding: const EdgeInsets.all(3.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // const Text("Liste des Notes"),
                    Tooltip(
                      message: "Imprimer",
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100))),
                        onPressed: () {
                          NoteListToPDF.printNote(_dataToprint);
                        },
                        child: const Icon(
                          Icons.print,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
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
                    StreamBuilder(
                        stream: DepartmentService().all(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var docs = snapshot.data?.docs
                                .map((e) => jsonDecode(jsonEncode(e.data())))
                                .toList();
                            List<Department>? data = docs
                                ?.map((e) => Department.fromJson(e))
                                .toList();

                            return Expanded(
                              child: DropdownButtonFormField<Department>(
                                hint: const Text("Département"),
                                decoration: const InputDecoration(
                                  hintText: "Département",
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.apartment),
                                ),
                                validator: (value) {
                                  return value != null
                                      ? null
                                      : "Département obligatoir";
                                },
                                isExpanded: true,
                                value: data?.first,
                                items: data
                                    ?.map((Department department) =>
                                        DropdownMenuItem<Department>(
                                            value: department,
                                            child: Text(department.label)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _department = value?.label ?? "";
                                  });
                                },
                                onSaved: (value) {
                                  setState(() {
                                    _department = value?.label ?? "";
                                  });
                                },
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                  ],
                ),
                const Divider(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 114,
                  child: StreamBuilder(
                      stream: _service.all(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var docs = snapshot.data?.docs
                              .map((e) => jsonDecode(jsonEncode(e.data())))
                              .toList();

                          var data =
                              docs?.map((e) => Note.fromJson(e)).toList();
                          data?.sort((n1, n2) {
                            return n2.date.compareTo(n1.date);
                          });

                          data = data?.where((note) {
                            if (note.department == null) {
                              return note.source.contains(_keyword) ||
                                  note.title.contains(_keyword) ||
                                  note.site!.name.contains(_keyword) ||
                                  note.note.contains(_keyword);
                            } else {
                              return (note.source.contains(_keyword) ||
                                      note.title.contains(_keyword) ||
                                      note.site!.name.contains(_keyword)) &&
                                  note.department!.label.contains(_department);
                            }
                          }).toList();
                          //copy to _dataToprint
                          _dataToprint = data ?? [];

                          return ListView.builder(
                              itemCount: data?.length,
                              itemBuilder: (context, index) {
                                Note note = data![index];
                                return Card(
                                  elevation: 0.5,
                                  child: ListTile(
                                      onTap: () {
                                        setState(() {
                                          _selectedIndex = index;
                                          _selectedNote = note;
                                        });
                                      },
                                      selectedTileColor:
                                          Colors.indigo.withOpacity(0.2),
                                      selected: _selectedIndex == index,
                                      title: Text(note.title,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(note.source),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            "Site: ${note.site!.name}",
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 13),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            "Date: ${note.date.toString().split(" ")[0]}",
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      leading: const CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            AssetImage(Assets.assetsAgent),
                                      ),
                                      trailing: Stack(
                                        children: [
                                          note.viewed
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                )
                                              : const Icon(Icons.warning,
                                                  color: Colors.orangeAccent),
                                          note.comments == null
                                              ? const SizedBox.shrink()
                                              : note.comments!.isEmpty
                                                  ? const SizedBox.shrink()
                                                  : Positioned(
                                                      top: 0.0,
                                                      right: 0.0,
                                                      child: Text(
                                                        "${note.comments?.length ?? 0}",
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                        ],
                                      )),
                                );
                              });
                        } else {
                          return Center(
                            child: Loading(
                              size: 64,
                              inline: true,
                            ),
                          );
                        }
                      }),
                ),
              ],
            ),
          ),
          _selectedNote == null
              ? const SizedBox.shrink()
              : Expanded(
                  child: NotesContant(
                    note: _selectedNote!,
                  ),
                )
        ],
      )
          /*StreamBuilder(
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
              })*/
          ),
    );
  }
}

/*class _DataSource extends DataTableSource {
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
    data.sort((p1, p2) {
      return p2.date.compareTo(p1.date);
    });
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
      DataCell(InfoPopupWidget(
        contentTitle: note.note,
        child: const Icon(
          Icons.info,
          color: Colors.red,
        ),
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
*/
