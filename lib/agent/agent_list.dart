import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/agent/agent_form.dart';
import 'package:spas_web/search_textField.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../rowperPageWidget.dart';
import '../services/agent.dart';
import '../services/export.dart';
import '../services/loading.dart';

class AgentList extends StatefulWidget {
  const AgentList({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<AgentList> {
  final AgentService _service = AgentService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
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
                  var data = docs?.map((e) => Agent.fromJson(e)).toList();

                  return PaginatedDataTable(
                    header: Row(
                      children: [
                        const Text("Liste des agents"),
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
                          message: "Ajouter un Agent",
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => AddAgent(
                                          agent: Agent(
                                              type: "SECURITÉ",
                                              code: '',
                                              firstName: '',
                                              lastName: '',
                                              phone: '',
                                              email: '',
                                              tracking: false,
                                              site: null,
                                              incumbent: true,
                                              start: null,
                                              and: null,
                                              permission: false,
                                              permissionType: ''))));
                            },
                            child: const Icon(Icons.add),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Tooltip(
                          message: "Générer les QR CODES",
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100))),
                            onPressed: () {
                              CarteGenerator.generateMiltiCarteAgent(
                                  _DataSource.dataForPrint);
                            },
                            child: const Icon(
                              Icons.badge,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                            onPressed: () async {
                              var document = await AgentListToPDF.export(
                                  _DataSource.dataForPrint);
                              PdfApi.openFile(document);
                            },
                            icon: const Icon(Icons.print)),
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
                      DataColumn(label: Text("Domaine")),
                      DataColumn(label: Text("Code")),
                      DataColumn(label: Text("Prénom")),
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Contact")),
                      DataColumn(label: Text("Site")),
                      DataColumn(label: Text("Action")),
                    ],
                    source: _DataSource(
                      context: context,
                      keyword: _keyword,
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
  static List<Agent> dataForPrint = [];
  List<Agent> data = [];
  String keyword;
  BuildContext context;

  _DataSource(
      {required this.context, required this.data, required this.keyword});
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    data = data.where((agent) {
      return agent.firstName.toLowerCase().contains(keyword.toLowerCase()) ||
          agent.site!.name.toLowerCase().contains(keyword.toLowerCase()) ||
          agent.code.toLowerCase().contains(keyword.toLowerCase()) ||
          agent.phone.toLowerCase().contains(keyword.toLowerCase()) &&
              agent.site != null;
    }).toList();
    dataForPrint = data;
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
    Agent agent = data[index];

    return DataRow(cells: [
      DataCell(Chip(
        label: Text(
          agent.type,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor:
            agent.type == "SECURITÉ" ? Colors.redAccent : Colors.blue,
      )),
      DataCell(Text(agent.code)),
      DataCell(Text(agent.firstName)),
      DataCell(Text(agent.lastName)),
      DataCell(Text(agent.phone)),
      DataCell(Text(agent.site!.name)),
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
                      builder: (_) => AddAgent(
                            agent: agent,
                            update: true,
                          )));
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
            onPressed: () {
              CarteGenerator.generateCarteAgent(agent);
            },
            child: const Icon(
              Icons.badge,
            ),
          ),
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
