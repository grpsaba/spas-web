import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/agentType.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../services/loading.dart';

class AddAgentYpe extends StatefulWidget {
  AddAgentYpe({super.key, required this.agType});
  AgentType agType;

  @override
  _AddAgentYpeState createState() => _AddAgentYpeState();
}

class _AddAgentYpeState extends State<AddAgentYpe> {
  final TextEditingController _label_ctrl = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _adding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _label_ctrl.text = widget.agType.label;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _label_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return PageModel(
      pageIdex: 13,
      titile: "Edition Type Agent",
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: _padding, right: _padding, top: 8.0, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              children: [
                TextFormField(
                  controller: _label_ctrl,
                  onChanged: (value) {
                    widget.agType.label = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Libellé obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Libellé",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(
                  height: 20,
                ),
                _adding
                    ? Loading(size: 48, inline: false)
                    : Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  fixedSize: const Size(150, 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              onPressed: () async {
                                widget.agType.label = _label_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });

                                  await AgentTypeService()
                                      .add(widget.agType)
                                      .then((value) {
                                    setState(() {
                                      _adding = false;
                                    });
                                    context.pop();
                                  }).onError((error, stackTrace) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(error.toString())));
                                    setState(() {
                                      _adding = false;
                                    });
                                  });
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text('Valider')
                                ],
                              )),
                          const SizedBox(
                            width: 20,
                          ),
                          AuthService.currentManager!.profil!
                                  .getModule(ModuleName.AGENT_TYPE)!
                                  .delete
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      fixedSize: const Size(150, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20))),
                                  onPressed: () async {
                                    if (_key.currentState!.validate()) {
                                      setState(() {
                                        _adding = true;
                                      });

                                      await AgentTypeService()
                                          .delete(widget.agType)
                                          .then((value) {
                                        setState(() {
                                          _adding = false;
                                        });
                                        context.pop();
                                      }).onError((error, stackTrace) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text(error.toString())));
                                        setState(() {
                                          _adding = false;
                                        });
                                      });
                                    }
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.white),
                                      )
                                    ],
                                  ))
                              : const SizedBox.shrink()
                        ],
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
