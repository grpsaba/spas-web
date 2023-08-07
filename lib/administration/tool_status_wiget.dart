import 'dart:convert';

import 'package:flutter/material.dart';

import '../model.dart';
import '../services/player.dart';
import '../services/pointerTool.dart';

class ToolStatus extends StatefulWidget {
  const ToolStatus({super.key});

  @override
  _ToolStatusState createState() => _ToolStatusState();
}

class _ToolStatusState extends State<ToolStatus> {
  PointingToolService _siteService = PointingToolService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _siteService.all(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var docs = snapshot.data?.docs
                .map((e) => jsonDecode(jsonEncode(e.data())))
                .toList();
            var lst = jsonDecode(jsonEncode(docs));
            //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

            List<PointingTools>? data =
                docs?.map((e) => PointingTools.fromJson(e)).toList();
            var dataToolCritique = data
                ?.where((pointage) =>
                    pointage.status.contains("CRITIQUE") &&
                    pointage.supported == false)
                .toList();
            var dataToolMauvais = data
                ?.where((pointage) =>
                    pointage.status.contains("MAUVAIS") &&
                    pointage.supported == false)
                .toList();
            if (dataToolCritique == null && dataToolMauvais == null) {
              Audio().stopSOs();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ignore: unnecessary_null_comparison
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  // ignore: unnecessary_null_comparison
                  dataToolCritique == null
                      ? const Text(
                          "0",
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        )
                      : Text("${dataToolCritique.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30)),
                  const SizedBox(
                    width: 10,
                  ),
                  const Icon(
                    Icons.warning,
                    color: Colors.orangeAccent,
                  ),
                  dataToolMauvais == null
                      ? const Text("0",
                          style: TextStyle(color: Colors.white, fontSize: 30))
                      : Text("${dataToolMauvais.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30))
                ],
              );
            }
            if (dataToolCritique!.isEmpty && dataToolMauvais!.isEmpty) {
              Audio().stopSOs();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ignore: unnecessary_null_comparison
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  // ignore: unnecessary_null_comparison
                  dataToolCritique == null
                      ? const Text("0",
                          style: TextStyle(color: Colors.white, fontSize: 30))
                      : Text("${dataToolCritique.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30)),
                  const SizedBox(
                    width: 10,
                  ),
                  const Icon(
                    Icons.warning,
                    color: Colors.orangeAccent,
                  ),
                  dataToolMauvais == null
                      ? const Text("0",
                          style: TextStyle(color: Colors.white, fontSize: 30))
                      : Text("${dataToolMauvais.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30))
                ],
              );
            } else {
              Audio().sos();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ignore: unnecessary_null_comparison
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  // ignore: unnecessary_null_comparison
                  dataToolCritique == null
                      ? const Text("0",
                          style: TextStyle(color: Colors.white, fontSize: 30))
                      : Text("${dataToolCritique.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30)),
                  const SizedBox(
                    width: 10,
                  ),
                  const Icon(
                    Icons.warning,
                    color: Colors.orangeAccent,
                  ),
                  dataToolMauvais == null
                      ? const Text("0",
                          style: TextStyle(color: Colors.white, fontSize: 30))
                      : Text("${dataToolMauvais.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30))
                ],
              );
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
