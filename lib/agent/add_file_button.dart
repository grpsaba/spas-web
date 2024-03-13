import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/loading.dart';

import '../const.dart';
import '../services/agent.dart';

class FileFormValidationButton extends StatefulWidget {
  FileFormValidationButton({
    super.key,
    required this.doc,
    required this.agent,
  });
  DocumentFile doc;
  Agent agent;

  @override
  _FileFormValidationButtonState createState() =>
      _FileFormValidationButtonState();
}

class _FileFormValidationButtonState extends State<FileFormValidationButton> {
  bool _creating = false;
  @override
  Widget build(BuildContext context) {
    return _creating
        ? Loading(size: 64, inline: true)
        : ElevatedButton(
            onPressed: () {
              setState(() {
                _creating = true;
              });
              if (widget.doc.title.isEmpty || widget.doc.path.isEmpty) {
                setState(() {
                  _creating = false;
                });
                MotionToast.error(description: const Text("Document invalide"))
                    .show(context);
              } else {
                widget.agent.docs?.add(widget.doc);
                AgentService().update(widget.agent).then((value) {
                  setState(() {
                    _creating = false;
                  });
                  MotionToast.success(
                          description:
                              const Text("Document ajouté avec succès"))
                      .show(context);
                  Navigator.pop(context, true);
                }).onError((error, stackTrace) {
                  setState(() {
                    _creating = false;
                  });
                  widget.agent.docs?.remove(widget.doc);
                  MotionToast.error(description: Text(error.toString()))
                      .show(context);
                });
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor),
            child: const Text(
              "Valider",
              style: TextStyle(color: Colors.white),
            ),
          );
  }
}
