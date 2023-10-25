import 'package:flutter/material.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/services/note.dart';

import '../generated/assets.dart';
import '../model.dart';
import '../services/export.dart';

class NotesContant extends StatefulWidget {
  NotesContant({super.key, required this.note, required this.manager});
  Note note;
  Manager manager;
  @override
  _NotesContantState createState() => _NotesContantState();
}

class _NotesContantState extends State<NotesContant> {
  TextEditingController _comment_ctrl = TextEditingController();
  GlobalKey<FormState> _key = GlobalKey<FormState>();
  bool _addingComment = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.note.comments != null) {
      widget.note.comments = widget.note.comments?.reversed.toList();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _comment_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: MediaQuery.of(context).size.height,
      child: Column(
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
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.note.viewed
                    ? const Text(
                        "Prise en charge éffective",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      )
                    : const Text(
                        "En attente de prise en charge",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
              ),
              widget.note.viewed
                  ? const SizedBox.shrink()
                  : widget.manager.profil!
                          .getModule(ModuleName.NOTE)!
                          .validation
                      ? IconButton(
                          tooltip: "Marquer comme prise en charge",
                          onPressed: () {
                            widget.note.viewed = true;
                            NoteService().update(widget.note);
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ))
                      : const SizedBox.shrink(),
              IconButton(
                  onPressed: () {
                    NoteListToPDF.printOneNote(widget.note);
                  },
                  icon: const Icon(
                    Icons.print,
                  ))
            ],
          ),
          const Divider(),
          //add comments
          widget.note.viewed
              ? const SizedBox.shrink()
              : SizedBox(
                  width: 500,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        child:
                            Image(image: AssetImage(Assets.assetsIconManager)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.0)),
                          child: Form(
                            key: _key,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    validator: (value) {
                                      return value!.isNotEmpty
                                          ? null
                                          : "commentaire invalide";
                                    },
                                    controller: _comment_ctrl,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                        hintText:
                                            "Que pensez-vous de cette note ${widget.manager.firstName}",
                                        border: InputBorder.none),
                                  ),
                                ),
                                _addingComment
                                    ? Loading(size: 32, inline: false)
                                    : IconButton(
                                        onPressed: () {
                                          if (_key.currentState!.validate()) {
                                            setState(() {
                                              _addingComment = true;
                                            });
                                            Comment comment = Comment(
                                                manager: widget.manager,
                                                title: _comment_ctrl.text,
                                                date: DateTime.now());
                                            if (widget.note.comments == null) {
                                              widget.note.comments = [comment];
                                            } else {
                                              widget.note.comments!
                                                  .add(comment);
                                            }
                                            NoteService()
                                                .add(widget.note)
                                                .then((value) {
                                              setState(() {
                                                _addingComment = false;
                                                _comment_ctrl.text = "";
                                              });
                                            }).onError((error, stackTrace) {
                                              setState(() {
                                                _addingComment = false;
                                                _comment_ctrl.text = "";
                                              });
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.send))
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
          //comments list
          const SizedBox(
            height: 5,
          ),
          Expanded(
            child: ListView.builder(
                itemCount: widget.note.comments?.length,
                itemBuilder: (context, index) {
                  Comment? coment = widget.note.comments?[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          child: Image(
                              image: AssetImage(Assets.assetsIconManager)),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.0)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${coment?.manager.firstName} ${coment?.manager.lastName}",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(coment?.title ?? "")
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
