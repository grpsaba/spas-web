import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/search_textField.dart';

import '../generated/assets.dart';
import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../services/agent.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerAgent.dart';

class ListAbsenceAgent extends StatefulWidget {
  const ListAbsenceAgent({super.key});

  @override
  _ListAbsenceAgentState createState() => _ListAbsenceAgentState();
}

class _ListAbsenceAgentState extends State<ListAbsenceAgent> {
  String _keyword = "";
  List<Agent> _listAgent = [];
  List<Agent> _listAgentNonScanner = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
  }

  shearchAgent() {
    _listAgent = _listAgent
        .where((element) => (element.firstName
                .toLowerCase()
                .contains(_keyword.toLowerCase()) ||
            element.lastName.toLowerCase().contains(_keyword.toLowerCase()) ||
            element.code.toLowerCase().contains(_keyword.toLowerCase()) ||
            element.site!.name.toLowerCase().contains(_keyword.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8.0),
        height: MediaQuery.of(context).size.height - 192,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Agents non pointés",
                  style: TextStyle(fontSize: 15),
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
                IconButton(
                    onPressed: () async {
                      var document = await AgentListToPDF.export(_listAgent,
                          title: "Agents non pointés");
                      PdfApi.openFile(document);
                    },
                    icon: const Icon(Icons.print)),
              ],
            ),
            const Divider(),
            SizedBox(
              height: MediaQuery.of(context).size.height - 264,
              child: StreamBuilder(
                  stream: AgentService().all(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const SizedBox.shrink();
                    if (snapshot.hasData) {
                      //mettre les données collectée en forma json
                      var docs = snapshot.data?.docs
                          .map((e) => jsonDecode(jsonEncode(e.data())))
                          .toList();
                      //filter les données selon la plage
                      _listAgent = docs!
                          .map((e) => Agent.fromJson(e))
                          .toList()
                          .where((element) => element.site != null)
                          .toList();

                      return StreamBuilder(
                          stream: PointingAgentService().all(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const SizedBox.shrink();
                            }
                            if (snapshot.hasData) {
                              DateTime.now().add(const Duration(days: 1));
                              //mettre les données collectée en forma json
                              var docs = snapshot.data?.docs
                                  .map((e) => jsonDecode(jsonEncode(e.data())))
                                  .toList();
                              //filter les données selon la plage
                              var collection = docs
                                  ?.map((e) => PointingAgent.fromJson(e))
                                  .toList();
                              collection = collection
                                  ?.where((element) => element.isToday())
                                  .toList();
                              //transformer les données sous forme maps site => liste pointage du site

                              List<Agent>? agents = collection
                                  ?.map((e) => e.agent)
                                  .toSet()
                                  .toList();
                              //elimination des doublons
                              /*var temps = [];
            for (Site site in sites ?? []) {
              temps.add(site);
              sites?.removeWhere((element) => element.UID == site.UID);
            }*/ //initialiser la liste des agents non scannés
                              _listAgentNonScanner = [];
                              for (Agent agent in agents ?? []) {
                                _listAgent.removeWhere((element) => element.code
                                    .toLowerCase()
                                    .contains(agent.code.toLowerCase()));
                              }
                              shearchAgent();
                              return ListView.builder(
                                  itemCount: _listAgent.length,
                                  itemBuilder: (context, index) {
                                    Agent agent = _listAgent[index];
                                    return Card(
                                      elevation: 0.3,
                                      child: ListTile(
                                        onTap: () {},
                                        leading: const CircleAvatar(
                                          radius: 18,
                                          backgroundImage: AssetImage(
                                              Assets.assetsIconAgent),
                                        ),
                                        title: Text(
                                            "${agent.firstName} ${agent.lastName}",
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            )),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("IM : ${agent.code}",
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                )),
                                            Text("Site : ${agent.site?.name}",
                                                style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            } else {
                              return Center(
                                child: Loading(
                                  size: 64,
                                  inline: false,
                                ),
                              );
                            }
                          });
                    } else {
                      return Center(
                        child: Loading(
                          size: 64,
                          inline: false,
                        ),
                      );
                    }
                  }),
            ),
          ],
        ));
  }
}
