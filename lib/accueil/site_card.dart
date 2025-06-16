import 'package:flutter/material.dart';
import 'package:spas_web/administration/sos_wiget.dart';

import '../const.dart';
import '../services/site.dart';

class SiteCard extends StatelessWidget {
  final int nombreSites;
  const SiteCard({
    super.key,
    required this.nombreSites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 100,
      width: 200,
      decoration: BoxDecoration(
          color: AppConstants.secondaryColor,
          borderRadius: BorderRadius.circular(20.0)),
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
            child: Row(
              children: [
                Sos(),
                const SizedBox(width: 10),
                const Text(
                  "Sites",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$nombreSites",
            style: const TextStyle(color: Colors.white, fontSize: 30),
          )
          // FutureBuilder(
          //     future: SiteService().allAsModel(),
          //     builder: (context, snapshot) {
          //       if (snapshot.hasError) {
          //         return const Text(
          //           "0",
          //           style: TextStyle(color: Colors.white, fontSize: 30),
          //         );
          //       }
          //       if (snapshot.hasData) {
          //         var data = snapshot.data
          //             ?.where((element) => element.actif == true)
          //             .toList();
          //         return Text(
          //           "${data?.length}",
          //           style: const TextStyle(color: Colors.white, fontSize: 30),
          //         );
          //       } else {
          //         return const Text(
          //           "0",
          //           style: TextStyle(color: Colors.white, fontSize: 30),
          //         );
          //       }
          //     }),
        ],
      ),
    );
  }
}
