import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/loading.dart';
import '../services/zoneMember.dart';

class ZoneMemberList extends StatefulWidget {
  const ZoneMemberList({super.key});

  @override
  _ZoneMemberListState createState() => _ZoneMemberListState();
}

class _ZoneMemberListState extends State<ZoneMemberList> {
  final ZoneMemberService _service = ZoneMemberService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<ZoneMember> _dataToexport = [];
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
      pageIndex: 16,
      title: "Gestion des chefs de zone",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data = docs?.map((e) => ZoneMember.fromJson(e)).toList();

                  //copy to _dataToexport
                  _dataToexport = data!;
                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Chefs de zones"),
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
                        AuthService.currentManager!.profil!
                                .getModule(ModuleName.SITE)!
                                .add
                            ? Tooltip(
                                message: "Ajouter un chef de zone",
                                child: ElevatedButton(
                                  onPressed: () {
                                    ZoneMember zm = ZoneMember(
                                        UID: '',
                                        code: '',
                                        firstName: '',
                                        lastName: '',
                                        phone: '',
                                        email: '',
                                        actif: false,
                                        poste: '',
                                        zone: null);
                                    context.go("/chefszone/add", extra: zm);
                                  },
                                  child: const Icon(Icons.add),
                                ),
                              )
                            : const SizedBox.shrink(),
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
                      //DataColumn(label: Text("Code")),
                      DataColumn(label: Text("Prénom")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Contact")),
                      DataColumn(label: Text("email")),
                      DataColumn(label: Text("Poste")),
                      DataColumn(label: Text("Zone")),
                      DataColumn(label: Text("Statut")),
                      DataColumn(label: Text("Action")),
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
}

class _DataSource extends DataTableSource {
  List<ZoneMember> data;
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
    data = data.where((zoneMember) {
      return zoneMember.firstName
              .toLowerCase()
              .contains(keyword.toLowerCase()) ||
          zoneMember.lastName.toLowerCase().contains(keyword.toLowerCase()) ||
          zoneMember.code.toLowerCase().contains(keyword.toLowerCase()) ||
          zoneMember.phone.toLowerCase().contains(keyword.toLowerCase()) ||
          zoneMember.zone!.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
    if (index >= data.length) {
      return const DataRow(cells: [
        //DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    ZoneMember zoneMember = data[index];

    return DataRow(cells: [
      //DataCell(Text(supervisor.code)),
      DataCell(Text(zoneMember.firstName)),
      DataCell(Text(zoneMember.lastName)),
      DataCell(Text(zoneMember.phone)),
      DataCell(Text(zoneMember.email)),
      DataCell(Text(zoneMember.poste ?? "")),
      DataCell(Chip(
          backgroundColor: Colors.orange,
          side: BorderSide.none,
          label: Text(zoneMember.zone?.name ?? ""))),
      DataCell(ZoneMemberStatut(
        zoneMember: zoneMember,
      )),
      DataCell(Row(
        children: [
          zoneMember.actif!
              ? IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    // ignore: use_build_context_synchronously
                    context.go("/chefszone/add", extra: zoneMember);
                  },
                )
              : const SizedBox.shrink(),
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

//widget d'état du superviseur

class ZoneMemberStatut extends StatefulWidget {
  ZoneMemberStatut({super.key, required this.zoneMember});
  ZoneMember zoneMember;

  @override
  _ZoneMemberStatutState createState() => _ZoneMemberStatutState();
}

class _ZoneMemberStatutState extends State<ZoneMemberStatut> {
  bool _updating = false;
  @override
  Widget build(BuildContext context) {
    return _updating
        ? Loading(size: 28, inline: false)
        : GestureDetector(
            onTap: () {
              if (AuthService.currentManager!.profil!
                  .getModule(ModuleName.SUPERVISEUR)!
                  .validation) {
                actifInactifAgent();
              }
            },
            child: Chip(
                backgroundColor:
                    widget.zoneMember.actif! ? Colors.green : Colors.redAccent,
                label: Row(
                  children: [
                    AuthService.currentManager!.profil!
                            .getModule(ModuleName.SUPERVISEUR)!
                            .validation
                        ? Checkbox(
                            value: widget.zoneMember.actif!,
                            onChanged: ((value) {
                              actifInactifAgent();
                            }))
                        : const SizedBox.shrink(),
                    widget.zoneMember.actif!
                        ? const Text(
                            "Actif",
                            style: TextStyle(color: Colors.white),
                          )
                        : const Text("Inactif",
                            style: TextStyle(color: Colors.white)),
                  ],
                )),
          );
  }

  void actifInactifAgent() {
    setState(() {
      _updating = true;
    });
    widget.zoneMember.actif = widget.zoneMember.actif! ? false : true;
    ZoneMemberService().update(widget.zoneMember).then((value) {
      setState(() {
        _updating = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _updating = false;
      });
    });
  }
}
