import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/loading.dart';

import '../pdf/api/pdf_api.dart';
import '../services/export.dart';
import '../services/note.dart';

class ImprimeRapport extends StatefulWidget {
  ImprimeRapport({super.key, required this.source});
  String source;
  @override
  _ImprimeRapportState createState() => _ImprimeRapportState();
}

class _ImprimeRapportState extends State<ImprimeRapport> {
  TextEditingController _debut_ctrl = TextEditingController();
  TextEditingController _fin_ctrl = TextEditingController();
  bool _onGener = false;
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _debut_ctrl.dispose();
    _fin_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIdex: 9,
      titile: "Rapport de ${widget.source}",
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Rapport de ${widget.source}"),
              const SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                controller: _debut_ctrl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Debut"),
                keyboardType: TextInputType.datetime,
                onTap: () {
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(3000))
                      .then((value) {
                    _dateDebut = value ?? DateTime.now();
                    _debut_ctrl.text =
                        "${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}";
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                controller: _fin_ctrl,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Fin"),
                keyboardType: TextInputType.datetime,
                onTap: () {
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(3000))
                      .then((value) {
                    _dateFin = value ?? DateTime.now();
                    _fin_ctrl.text =
                        "${_dateFin.day}/${_dateFin.month}/${_dateFin.year}";
                  });
                },
              ),
              const SizedBox(height: 40),
              _onGener
                  ? Loading(size: 64, inline: false)
                  : ElevatedButton(
                      onPressed: () {
                        _onGener = true;
                        setState(() {});
                        NoteService().allFuture().then((data) {
                          _onGener = false;
                          setState(() {});
                          NoteRepport.export(
                                  data, _dateDebut, _dateFin, widget.source)
                              .then((file) {
                            PdfApi.openFile(file);
                          });
                        }).onError((error, stackTrace) {
                          _onGener = false;
                          setState(() {});
                        });
                      },
                      child: const Text('Valider')),
            ],
          ),
        ),
      ),
    );
  }
}
