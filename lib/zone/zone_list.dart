import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/loading.dart';
import '../services/zone.dart';

class ZoneList extends StatefulWidget {
  const ZoneList({
    super.key,
  });

  @override
  _ZoneListState createState() => _ZoneListState();
}

class _ZoneListState extends State<ZoneList> {
  final ZoneService _service = ZoneService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  bool _sortAscending = false;
  int _sortColumnIndex = 0;
  //filtre statut
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
    return PageModel(
      pageIndex: 14,
      title: "Gestion des zones",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data = docs?.map((e) => Zone.fromJson(e)).toList();

                  data!.sort((zone1, zone2) {
                    return zone1.name.compareTo(zone2.name);
                  });

                  //copy to _dataToexport
                  //_dataToexport = data!;
                  return PaginatedDataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    header: Row(
                      children: [
                        const Text("Liste des  zones"),
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
                        AuthService.currentManager!.profil!
                                .getModule(ModuleName.SITE)!
                                .add
                            ? Tooltip(
                                message: "Ajouter une zone",
                                child: ElevatedButton(
                                  onPressed: () {
                                    Zone zone = Zone(
                                      codeZone: "",
                                      name: "",
                                    );
                                    context.go("/zones/add", extra: zone);
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )
                            : const SizedBox(),
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
                      ),
                    ],
                    rowsPerPage: rowParPage,
                    showFirstLastButtons: true,
                    columns: [
                      const DataColumn(label: Text("Code")),
                      DataColumn(
                          onSort: (columnIndex, _) {
                            setState(() {
                              sortZone(columnIndex, data);
                            });
                          },
                          label: const Text("Nom")),
                      const DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                      context: context,
                      keyword: _keyword,
                      data: data,
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

  sortZone(index, List<Zone> data) {
    _sortColumnIndex = index;
    if (_sortAscending == true) {
      _sortAscending = false;
      data.sort((zone1, zone2) {
        return zone1.name.compareTo(zone2.name);
      });
    } else {
      _sortAscending = true;
      data.sort((zone1, zone2) {
        return zone2.name.compareTo(zone1.name);
      });
    }
  }
}

class _DataSource extends DataTableSource {
  static List<Zone> dataToprint = [];
  List<Zone> data;

  String keyword;
  BuildContext context;

  _DataSource({
    required this.context,
    required this.data,
    required this.keyword,
  });
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data.where((element) {
      return element.name.toLowerCase().contains(keyword.toLowerCase()) ||
          element.codeZone.toLowerCase() == (keyword.toLowerCase());
    }).toList();
    dataToprint = data;
    if (index >= data.length) {
      return const DataRow(cells: [
        //DataCell(Text("")),
        //DataCell(Text("")),
        DataCell(Text("")),

        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    Zone zone = data[index];

    return DataRow(cells: [
      DataCell(Text(zone.codeZone)),
      DataCell(Text(zone.name)),
      DataCell(Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              // ignore: use_build_context_synchronously
              context.go("/zones/add", extra: zone);
            },
          ),
          AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!.delete
              ? DeleteZone(zone: zone)
              : const SizedBox.shrink()
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

//widget d'état du site

//widget btn delete du site

class DeleteZone extends StatefulWidget {
  DeleteZone({super.key, required this.zone});
  Zone zone;
  @override
  _DeleteZoneState createState() => _DeleteZoneState();
}

class _DeleteZoneState extends State<DeleteZone> {
  bool _deleting = false;
  @override
  Widget build(BuildContext context) {
    return _deleting
        ? Loading(size: 28, inline: false)
        : IconButton(
            onPressed: () {
              deleteSite();
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ));
  }

  void deleteSite() {
    setState(() {
      _deleting = true;
    });
    ZoneService().delete(widget.zone).then((value) {
      setState(() {
        _deleting = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _deleting = false;
      });
    });
  }
}
