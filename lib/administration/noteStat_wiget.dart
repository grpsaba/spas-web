import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/services/note.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/player.dart';

class NoteStat extends StatefulWidget {
  const NoteStat({super.key});

  @override
  _NoteStatState createState() => _NoteStatState();
}

class _NoteStatState extends State<NoteStat> {
  final NoteService _siteService = NoteService();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Audio().stopSOs();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _siteService.allNoViewedNote(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var docs = snapshot.data?.docs
                .map((e) => jsonDecode(jsonEncode(e.data())))
                .toList();
            var lst = jsonDecode(jsonEncode(docs));
            //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

            List<Note>? data = docs?.map((e) => Note.fromJson(e)).toList();
            //data = data?.where((note) => note.viewed == false).toList();
            if (data == null) {

              return const SizedBox.shrink();
            }
            if (data.isEmpty) {

              return const SizedBox.shrink();
            } else {
              TTS().speetch('${data.length} Notes superviseur en attente de traitement.');
              return GestureDetector(
                  onTap: () {
                    /* Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SiteSOSList()));*/
                  },
                  child: Loading(
                      size: 18, inline: false, sos: true, status: true));
            }
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
