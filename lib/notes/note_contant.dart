import 'package:flutter/material.dart';

import '../generated/assets.dart';
import '../model.dart';

class NotesContant extends StatefulWidget {
  NotesContant({super.key, required this.note});
  Note note;
  @override
  _NotesContantState createState() => _NotesContantState();
}

class _NotesContantState extends State<NotesContant> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(Assets.assetsAgent),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.note.source),
                Text(
                  "Date: ${widget.note.date.toString().split(" ")[0]}",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "Site: ${widget.note.site!.name}",
                  style: const TextStyle(color: Colors.indigo, fontSize: 15),
                ),
              ],
            )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.note.title,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Container(
          width: 600,
          padding: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Text(
            widget.note.note,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.note.viewed
              ? const Text(
                  "Traitée",
                  style: TextStyle(color: Colors.green, fontSize: 12),
                )
              : const Text(
                  "En attente",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
        ),
        const Divider(),
      ],
    );
  }
}
