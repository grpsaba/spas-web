import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/accueil/note_list_tb.dart';

import '../administration/noteStat_wiget.dart';
import '../const.dart';
import '../model.dart';
import '../services/note.dart';

class NoteCard extends StatelessWidget {
  NoteCard({super.key});

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

                    return SizedBox(
                      width: width - (width - 500),
                      child: NoteListTB(),
                    );
                  },
                ),
              );
            });
      },
      child: Container(
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
              child: const Text(
                "Notes",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
                stream: NoteService().all(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      "0",
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    );
                  }
                  if (snapshot.hasData) {
                    var docs = snapshot.data?.docs
                        .map((e) => jsonDecode(jsonEncode(e.data())))
                        .toList();

                    List<Note>? data =
                        docs?.map((e) => Note.fromJson(e)).toList();

                    data = data?.where((note) => note.viewed == false).toList();

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const NoteStat(),
                        Text(
                          "${data?.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 30),
                        ),
                      ],
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
