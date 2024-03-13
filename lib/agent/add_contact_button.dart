import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/loading.dart';

import '../const.dart';
import '../services/agent.dart';

class ContactFormValidationButton extends StatefulWidget {
  ContactFormValidationButton({
    super.key,
    required this.contact,
    required this.agent,
  });
  ConactReference contact;
  Agent agent;

  @override
  _ContactFormValidationButtonState createState() =>
      _ContactFormValidationButtonState();
}

class _ContactFormValidationButtonState
    extends State<ContactFormValidationButton> {
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
              if (widget.contact.title.isEmpty ||
                  widget.contact.contact.isEmpty) {
                setState(() {
                  _creating = false;
                });
                MotionToast.error(description: const Text("Contact invalide"))
                    .show(context);
              } else {
                widget.agent.contacts?.add(widget.contact);
                AgentService().update(widget.agent).then((value) {
                  setState(() {
                    _creating = false;
                  });
                  MotionToast.success(
                          description: const Text("Contact ajouté avec succès"))
                      .show(context);
                  Navigator.pop(context, true);
                }).onError((error, stackTrace) {
                  setState(() {
                    _creating = false;
                  });
                  widget.agent.contacts?.remove(widget.contact);
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
