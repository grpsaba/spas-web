import 'package:flutter/material.dart';
import 'package:spas_web/accueil/progressionPointageSiteGlobal.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/pointerSite.dart';

class PointageSiteCard extends StatelessWidget {
  final int nombreSite;
  const PointageSiteCard({
    super.key,
    required this.nombreSite,
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
                 // var docs = snapshot.data?.docs.map((e) => e.data()).toList();
                  // var collection = docs
                  //     ?.map((e) =>
                  //         PointingSite.fromJson(e as Map<String, dynamic>))
                  //     .toList();

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PointageSiteGlobal(
                      nbSite: nombreSite,
                      data: snapshot.data,
                    ),
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const CircularProgressIndicator();
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
