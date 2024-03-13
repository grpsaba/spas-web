import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/Categorietool.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/loading.dart';

class CatToolList extends StatefulWidget {
  const CatToolList({
    super.key,
  });

  @override
  _CatToolListState createState() => _CatToolListState();
}

class _CatToolListState extends State<CatToolList> {
  final CategorieToolService _service = CategorieToolService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<CategorieTool> _dataToexport = [];
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
      pageIdex: 11,
      titile: "Gestion des équipement",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data =
                      docs?.map((e) => CategorieTool.fromJson(e)).toList();

                  //copy to _dataToexport
                  _dataToexport = data!;
                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Liste des Equipements"),
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
                                .getModule(ModuleName.CATEGORIE_TOOL)!
                                .add
                            ? ElevatedButton(
                                onPressed: () {
                                  CategorieTool ct = CategorieTool(
                                    label: '',
                                    department: Department(label: ''),
                                  );
                                  context.go('equipements/add', extra: ct);
                                },
                                child: const Icon(Icons.add),
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
                      DataColumn(label: Text("Libellé")),
                      DataColumn(label: Text("Département")),
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
  List<CategorieTool> data;
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
    data = data.where((tool) {
      return tool.label.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
    if (index >= data.length) {
      return const DataRow(cells: [
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    CategorieTool catTool = data[index];

    return DataRow(cells: [
      DataCell(Text(
        catTool.label,
        style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20),
      )),
      DataCell(Text(
        catTool.department?.label ?? "",
        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20),
      )),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                // ignore: use_build_context_synchronously
                context.go('equipements/add', extra: catTool);
              },
            ),
          ],
        ),
      ),
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
