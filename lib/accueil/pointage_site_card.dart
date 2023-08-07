import 'package:flutter/material.dart';
import 'package:spas_web/accueil/progressionPointageSiteGlobal.dart';
import 'package:spas_web/services/pointerSite.dart';

class PointageSiteCard extends StatelessWidget {
  const PointageSiteCard({
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
              "Pointages site",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder(
              stream: PointingSiteService().all(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    "0",
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  );
                }
                if (snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: PointageSiteGlobal(),
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
