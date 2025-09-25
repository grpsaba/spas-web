import 'dart:convert';

import 'package:flutter/material.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/player.dart';
import '../services/site.dart';

class Sos extends StatefulWidget {
  Sos({
    super.key,
  });

  @override
  _AlertState createState() => _AlertState();
}

class _AlertState extends State<Sos> {
  SiteService _siteService = SiteService();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Audio().stopSOs();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _siteService.allSos(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var docs = snapshot.data?.docs
                .map((e) => jsonDecode(jsonEncode(e.data())))
                .toList();

            List<Site>? data = docs?.map((e) => Site.fromJson(e)).toList();
           
            if (data == null) {
              Audio().stopSOs();

              return const SizedBox.shrink();
            }
            if (data.isEmpty) {
              Audio().stopSOs();

              return const SizedBox.shrink();
            } else {
              debugPrint("${data.length} sos");
              TTS().speetch(
                  "Sos sur ${data.first.name}, superviseur ${data.first.supervisor!.firstName} ${data.first.supervisor!.lastName}");
              Audio().sos();

              return Tooltip(
                message: data.map((site)=>" ${site.name} : ${site.supervisor?.firstName??''} ${site.supervisor?.lastName}??'").toList().toString(),
                child: GestureDetector(
                    onTap: () {
                      /* Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SiteSOSList()));*/
                    },
                    child: Loading(
                        size: 34, inline: false, sos: true, status: true)),
              );
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
