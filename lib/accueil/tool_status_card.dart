import 'package:flutter/material.dart';

import '../administration/tool_status_wiget.dart';

class ToolStatusCard extends StatelessWidget {
  const ToolStatusCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 100,
      width: 200,
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            width: 200,
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20.0),
                    topLeft: Radius.circular(20.0))),
            child: const Text(
              "Statut des matériaux",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          const ToolStatus()
        ],
      ),
    );
  }
}
