import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/profil.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/loading.dart';
import '../services/manager.dart';
import 'manager_form.dart';

class ManagerList extends StatefulWidget {
  ManagerList({super.key, required this.manager});
  Manager manager;
  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<ManagerList> {
  final ManagerService _service = ManagerService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<Manager> _dataToexport = [];
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
                  var data = docs?.map((e) => Manager.fromJson(e)).toList();

                  //copy to _dataToexport
                  _dataToexport = data!;
                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Liste des Controleurs"),
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
                                .getModule(ModuleName.MANAGER)!
                                .add
                            ? Tooltip(
                                message: "Ajouter un controleur",
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => AddManager(
                                                    manager: Manager(
                                                  poste: '',
                                                  firstName: '',
                                                  lastName: '',
                                                  phone: '',
                                                  email: '',
                                                  profil: null,
                                                  UID: '',
                                                  token: '',
                                                ))));
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(
                          width: 10,
                        ),
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
                      DataColumn(label: Text("Prénom")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Poste")),
                      DataColumn(label: Text("Profil")),
                      DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                        context: context,
                        keyword: _keyword,
                        data: data,
                        managerLoged: widget.manager),
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
  List<Manager> data;
  String keyword;
  BuildContext context;
  Manager managerLoged;

  _DataSource(
      {required this.context,
      required this.data,
      required this.keyword,
      required this.managerLoged});
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data.where((manager) {
      return manager.firstName.toLowerCase().contains(keyword.toLowerCase()) ||
          manager.lastName.toLowerCase().contains(keyword.toLowerCase()) ||
          manager.phone.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
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
    Manager manager = data[index];

    return DataRow(cells: [
      DataCell(Text(manager.firstName)),
      DataCell(Text(manager.lastName)),
      DataCell(Text(manager.email)),
      DataCell(Text(manager.poste)),
      DataCell(FutureBuilder(
          future: ProfilService().one(manager.profil?.name ?? ""),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var profil = snapshot.data;
              return Chip(
                label: Text(profil?.name ?? "Inconnu",
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: Theme.of(context).primaryColor,
              );
            } else {
              return const Chip(
                label: Text("Inconnu", style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              );
            }
          })),
      DataCell(Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddManager(
                            manager: managerLoged,
                          )));
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
