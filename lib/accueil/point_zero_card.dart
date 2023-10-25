import 'package:flutter/material.dart';

import '../services/agent.dart';
import 'Point0_list.dart';

class PointZeroCard extends StatelessWidget {
  const PointZeroCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                contentPadding: const EdgeInsets.all(0.0),
                alignment: Alignment.center,
                content: Builder(
                  builder: (context) {
                    // Get available height and width of the build area of this widget. Make a choice depending on the size.
                    var height = MediaQuery.of(context).size.height;
                    var width = MediaQuery.of(context).size.width;

                    return Container(
                      width: width - (width - 500),
                      child: const PointZeroList(),
                    );
                  },
                ),
              );
            });
      },
      child: Container(
        //height: 100,
        //: 200,
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              //width: 200,
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20.0),
                      topLeft: Radius.circular(20.0))),
              child: const Text(
                "Les Points Zéro",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder(
                future: AgentService().allFuture(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      "0",
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    );
                  }
                  if (snapshot.hasData) {
                    var data = snapshot.data
                        ?.where((element) =>
                            element.typeAgent?.label == "POINT ZERO" &&
                            element.actif == true)
                        .toList();

                    return Text(
                      "${data?.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 30),
                    );
                  } else {
                    return const Text(
                      "0",
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    );
                  }
                })
          ],
        ),
      ),
    );
  }
}
