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
        stream: _siteService.all(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var docs = snapshot.data?.docs
                .map((e) => jsonDecode(jsonEncode(e.data())))
                .toList();
            var lst = jsonDecode(jsonEncode(docs));
            //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

            List<Site>? data = docs?.map((e) => Site.fromJson(e)).toList();
            data = data
                ?.where((site) => site.sos == true && site.actif == true)
                .toList();

            if (data == null) {
              Audio().stopSOs();

              return const SizedBox.shrink();
            }
            if (data.isEmpty) {
              Audio().stopSOs();

              return const SizedBox.shrink();
            } else {
              TTS().speetch(
                  "Sos sur ${data.first.name},superviseur ${data.first.supervisor!.firstName} ${data.first.supervisor!.lastName}, Zone ${data.first.zone?.codeZone ?? ""}");
              Audio().sos();

              return GestureDetector(
                  onTap: () {
                    /* Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SiteSOSList()));*/
                  },
                  child: Loading(
                      size: 34, inline: false, sos: true, status: true));
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
