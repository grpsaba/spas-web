import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/services/export.dart';

import '../generated/assets.dart';
import '../model.dart';
import '../search_textField.dart';
import '../services/authentication.dart';
import '../services/loading.dart';
import '../services/note.dart';

class NoteListTB extends StatefulWidget {
  NoteListTB({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<NoteListTB> {
  final NoteService _service = NoteService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;
  List<Note> _dataToexport = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rowParPage = defauldRowParPage;
    _texController.text = defauldRowParPage.toString();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _texController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      //height: MediaQuery.of(context).size.height - 192,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Notes",
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(
                width: 5,
              ),
              SearchTextField(
                  onSearch: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                  onPress: () {}),
              Tooltip(
                message: "Imprimer",
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100))),
                  onPressed: () {
                    NoteListToPDF.printNote(_dataToexport);
                  },
                  child: const Icon(
                    Icons.print,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ))
            ],
          ),
          const Divider(),
          SizedBox(
            height: MediaQuery.of(context).size.height -
                (MediaQuery.of(context).size.height - 556),
            child: StreamBuilder(
                stream: _service.all(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var docs = snapshot.data?.docs
                        .map((e) => jsonDecode(jsonEncode(e.data())))
                        .toList();
                    var data = docs
                        ?.map((e) => Note.fromJson(e))
                        .toList()
                        .where((element) =>
                            (element.site!.name
                                    .toLowerCase()
                                    .contains(_keyword.toLowerCase()) ||
                                element.source
                                    .toLowerCase()
                                    .contains(_keyword.toLowerCase())) &&
                            element.viewed == false)
                        .toList()
                        .reversed
                        .toList();

                    data?.sort((n1, n2) {
                      return n2.date.compareTo(n1.date);
                    });
                    //copy to _dataToexport
                    _dataToexport = data!;
                    return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          Note note = data[index];
                          return Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                          radius: 18,
                                          child: Image(
                                            fit: BoxFit.contain,
                                            image: AssetImage(
                                                Assets.assetsIconManager),
                                          )),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text("${note.source} -"),
                                              Text(
                                                note.title,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            note.date.toString().split(" ")[0],
                                            style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Container(
                                  width: 600,
                                  padding: const EdgeInsets.all(8.0),
                                  color: Colors.blueGrey,
                                  child: Text(
                                    note.note,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      note.viewed
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 28,
                                            )
                                          : const Icon(
                                              Icons.warning,
                                              color: Colors.orange,
                                              size: 28,
                                            ),
                                      Text(
                                        note.site!.name,
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Divider(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 100,
                                    child: AuthService.currentManager!.profil!
                                            .getModule(ModuleName.NOTE)!
                                            .add
                                        ? TextButton(
                                            onPressed: () {
                                              note.viewed = true;
                                              _service.update(note);
                                            },
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.black54,
                                                ),
                                                Text(
                                                  "Noté",
                                                  style: TextStyle(
                                                      color: Colors.black54),
                                                )
                                              ],
                                            ))
                                        : const SizedBox.shrink(),
                                  ),
                                )
                              ],
                            ),
                          );
                        });
                  } else {
                    return Center(
                      child: Loading(
                        size: 64,
                        inline: true,
                      ),
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }
}
