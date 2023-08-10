import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

import '../model.dart';
import '../services/agent.dart';

class NbAgentStatus extends StatefulWidget {
  NbAgentStatus({super.key, required this.site});
  Site site;
  @override
  _NbAgentStatusState createState() => _NbAgentStatusState();
}

class _NbAgentStatusState extends State<NbAgentStatus> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AgentService().allBySite(widget.site.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.hasData) {
            var data = snapshot.data?.where((element) => element.actif == true);
            int? value = data?.length;
            double? purcent = value! * 100 / widget.site.nbAgent;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FAProgressBar(
                  //progressType: LinearProgressBar.progressTypeLinear,
                  displayText: "%",
                  size: 15,
                  maxValue: 100.0,
                  currentValue: purcent,
                  progressColor: purcent <= 30
                      ? Colors.red
                      : purcent <= 60
                          ? Colors.orange
                          : Colors.green,
                  backgroundColor: Colors.grey,
                ),
                Text("Agent $value/${widget.site.nbAgent}"),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
