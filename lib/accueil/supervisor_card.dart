import 'package:flutter/material.dart';

import '../const.dart';
import '../services/supervisor.dart';

class SupervisorCard extends StatelessWidget {
  const SupervisorCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 100,
      width: 200,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: AppConstants.secondaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            width: 200,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: AppConstants.secondaryColor,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20.0),
                    topLeft: Radius.circular(20.0))),
            child: const Text(
              "Superviseurs",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder(
              future: SupervisorService().allFuture(""),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    "0",
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  );
                }
                if (snapshot.hasData) {
                  var data = snapshot.data
                      ?.where((element) => element.actif == true)
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
    );
  }
}
