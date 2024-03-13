import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/agentType.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/loading.dart';

class AgentTypeList extends StatefulWidget {
  const AgentTypeList({super.key});

  @override
  _AgentTypeListState createState() => _AgentTypeListState();
}

class _AgentTypeListState extends State<AgentTypeList> {
  final AgentTypeService _service = AgentTypeService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<AgentType> _dataToexport = [];
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
      pageIdex: 13,
      titile: "Gestions des type agents",
      child: SingleChildScrollView(
          child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var data = docs?.map((e) => AgentType.fromJson(e)).toList();

                  //copy to _dataToexport
                  _dataToexport = data!;
                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Liste des type agents"),
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
                                .getModule(ModuleName.AGENT_TYPE)!
                                .add
                            ? ElevatedButton(
                                onPressed: () {
                                  context.go("/typesagent/add",
                                      extra: AgentType(
                                        label: '',
                                      ));
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
  List<AgentType> data;
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
      ]);
    }
    AgentType agtype = data[index];

    return DataRow(cells: [
      DataCell(Text(
        agtype.label,
        style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20),
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
                context.go("/typesagent/add", extra: agtype);
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
