import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/agent.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/site.dart';
import '../services/tool.dart';

class ToolList extends StatefulWidget {
  const ToolList({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<ToolList> {
  final ToolService _service = ToolService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<Tool> _dataToexport = [];
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
      pageIndex: 5,
      title: "Gestion des matériaux",
      child: SingleChildScrollView(
          // child: StreamBuilder(
          //     stream: _service.all(),
          //     builder: (context, snapshot) {
          //       if (snapshot.hasData) {
          //         var docs = snapshot.data?.docs
          //             .map((e) => jsonDecode(jsonEncode(e.data())))
          //             .toList();
          //         var data = docs?.map((e) => Tool.fromJson(e)).toList();

          //         //copy to _dataToexport
          //         _dataToexport = data!;
          //         return PaginatedDataTable(
          //           header: Row(
          //             children: [
          //               const Text("Liste des matériaux"),
          //               const SizedBox(
          //                 width: 10,
          //               ),
          //               SearchTextField(
          //                   onSearch: (value) {
          //                     setState(() {
          //                       _keyword = value;
          //                     });
          //                   },
          //                   onPress: () {}),
          //               const SizedBox(
          //                 width: 10,
          //               ),
          //               AuthService.currentManager!.profil!
          //                       .getModule(ModuleName.TOOL)!
          //                       .add
          //                   ? ElevatedButton(
          //                       onPressed: () {
          //                         Tool tool = Tool(
          //                           serialNumber: '',
          //                           label: '',
          //                           site: null,
          //                           catTool: null,
          //                         );
          //                         context.go('/tools/add', extra: tool);
          //                       },
          //                       child: const Icon(Icons.add),
          //                     )
          //                   : const SizedBox.shrink(),
          //               const SizedBox(
          //                 width: 10,
          //               ),
          //               AuthService.currentManager!.profil!
          //                       .getModule(ModuleName.TOOL)!
          //                       .generBadge
          //                   ? Tooltip(
          //                       message: "Générer les QR CODES",
          //                       child: ElevatedButton(
          //                         style: ElevatedButton.styleFrom(
          //                             shape: RoundedRectangleBorder(
          //                                 borderRadius:
          //                                     BorderRadius.circular(100))),
          //                         onPressed: () {
          //                           CarteGenerator.generateMiltiQrTool(
          //                               _dataToexport);
          //                         },
          //                         child: const Icon(
          //                           Icons.badge,
          //                         ),
          //                       ),
          //                     )
          //                   : const SizedBox.shrink(),
          //             ],
          //           ),
          //           actions: [
          //             RowPerPageWidget(
          //               controller: _texController,
          //               incremente: () {
          //                 setState(() {
          //                   rowParPage += 1;
          //                   _texController.text = rowParPage.toString();
          //                 });
          //               },
          //               decremente: () {
          //                 setState(() {
          //                   rowParPage = rowParPage <= defauldRowParPage
          //                       ? defauldRowParPage
          //                       : rowParPage - 1;

          //                   _texController.text = rowParPage.toString();
          //                 });
          //               },
          //             )
          //           ],
          //           rowsPerPage: rowParPage,
          //           showFirstLastButtons: true,
          //           columns: const [
          //             DataColumn(label: Text("SN")),
          //             DataColumn(label: Text("Libellé")),
          //             DataColumn(label: Text("Equipement")),
          //             DataColumn(label: Text("Site")),
          //             DataColumn(label: Text("Action")),
          //           ],
          //           source: _DataSource(
          //             context: context,
          //             keyword: _keyword,
          //             data: data,
          //           ),
          //         );
          //       } else {
          //         return Center(
          //           child: Loading(
          //             size: 64,
          //             inline: true,
          //           ),
          //         );
          //       }
          //     })
              ),
    );
  }
}

class _DataSource extends DataTableSource {
  List<Tool> data;
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
      return tool.label.toLowerCase().contains(keyword.toLowerCase()) ||
          tool.serialNumber.toLowerCase().contains(keyword.toLowerCase()) ||
          tool.site!.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
    if (index >= data.length) {
      return const DataRow(cells: [
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }
    Tool tool = data[index];

    return DataRow(cells: [
      DataCell(Text(tool.serialNumber)),
      DataCell(Text(tool.label)),
      DataCell(Chip(
        label: Text(
          tool.catTool?.label ?? "Inconnu",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
      )),
      DataCell(Text(tool.site!.name)),
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
                context.go('/tools/add', extra: tool);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100))),
              onPressed: () {
                CarteGenerator.generateQrTool(tool);
              },
              child: const Icon(
                Icons.badge,
              ),
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

  Widget nbAgent(Supervisor supervisor) {
    return FutureBuilder(
        future: AgentService().allBySupervisor(supervisor.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.hasData) {
            var data = snapshot.data;
            return Text("${data?.length}");
          } else {
            return const SizedBox.shrink();
          }
        });
  }

  Widget nbSite(Supervisor supervisor) {
    return FutureBuilder(
        future: SiteService().allBySupervisor(supervisor),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.hasData) {
            var data = snapshot.data;
            return Text("${data?.length}");
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
