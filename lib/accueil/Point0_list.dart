import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/services/agent.dart';

import '../agent/agent_form.dart';
import '../generated/assets.dart';
import '../model.dart';
import '../search_textField.dart';
import '../services/loading.dart';

class PointZeroList extends StatefulWidget {
  const PointZeroList({super.key});

  @override
  _PointZeroListState createState() => _PointZeroListState();
}

class _PointZeroListState extends State<PointZeroList> {
  final AgentService _service = AgentService();

  String _keyword = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      //height: MediaQuery.of(context).size.height - 192,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Points Zéro",
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
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ))
            ],
          ),
          const Divider(),
          SizedBox(
            height: MediaQuery.of(context).size.height -
                (MediaQuery.of(context).size.height - 556),
            child: StreamBuilder(
                stream: _service.all(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var docs = snapshot.data?.docs
                        .map((e) => jsonDecode(jsonEncode(e.data())))
                        .toList();
                    var data = docs
                        ?.map((e) => Agent.fromJson(e))
                        .toList()
                        .where((element) =>
                            (element.firstName
                                    .toLowerCase()
                                    .contains(_keyword.toLowerCase()) ||
                                element.lastName
                                    .toLowerCase()
                                    .contains(_keyword.toLowerCase()) ||
                                element.phone
                                    .toLowerCase()
                                    .contains(_keyword.toLowerCase())) &&
                            element.categorie == "POINT ZERO" &&
                            element.actif == true)
                        .toList()
                        .reversed
                        .toList();

                    return ListView.builder(
                        itemCount: data?.length,
                        itemBuilder: (context, index) {
                          Agent? agent = data?[index];
                          return Card(
                            elevation: 0.3,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AddAgent(
                                              agent: agent!,
                                              update: true,
                                            )));
                              },
                              leading: const CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                    AssetImage(Assets.assetsIconAgent),
                              ),
                              title:
                                  Text("${agent?.firstName} ${agent?.lastName}",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                      )),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("IM : ${agent?.code}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      )),
                                  Text("Phone : ${agent?.phone}",
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
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
    );
  }
}
