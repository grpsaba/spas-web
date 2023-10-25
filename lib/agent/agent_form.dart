import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/services/agentType.dart';

import '../liste_selection_pages/site_search_dialog.dart';
import '../model.dart';
import '../services/agent.dart';
import '../services/department.dart';
import '../services/loading.dart';

class AddAgent extends StatefulWidget {
  AddAgent(
      {super.key,
      required this.agent,
      this.update = false,
      required this.manager});
  Agent agent;
  bool update;
  Manager manager;

  @override
  _AddSupervisorState createState() => _AddSupervisorState();
}

class _AddSupervisorState extends State<AddAgent> {
  final TextEditingController _code_ctrl = TextEditingController();
  final TextEditingController _firstName_ctrl = TextEditingController();
  final TextEditingController _lastName_ctrl = TextEditingController();
  final TextEditingController _phone_ctrl = TextEditingController();
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _site_ctrl = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _adding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _email_ctrl.text = widget.agent.email;
    _code_ctrl.text = widget.agent.code;
    _firstName_ctrl.text = widget.agent.firstName;
    _lastName_ctrl.text = widget.agent.lastName;
    _phone_ctrl.text = widget.agent.phone;
    _site_ctrl.text =
        widget.agent.site == null ? '' : '${widget.agent.site?.name}';
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _phone_ctrl.dispose();
    _lastName_ctrl.dispose();
    _firstName_ctrl.dispose();
    _code_ctrl.dispose();
    _email_ctrl.dispose();
    _site_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Edition Agent",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: padding, right: padding, top: 8.0, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              children: [
                StreamBuilder(
                    stream: DepartmentService().all(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var docs = snapshot.data?.docs
                            .map((e) => jsonDecode(jsonEncode(e.data())))
                            .toList();
                        List<Department>? data =
                            docs?.map((e) => Department.fromJson(e)).toList();

                        return DropdownButtonFormField<Department>(
                          hint: const Text("Département"),
                          decoration: const InputDecoration(
                              hintText: "Département",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.apartment)),
                          validator: (value) {
                            return value != null
                                ? null
                                : "Département obligatoir";
                          },
                          isExpanded: true,
                          value: data
                              ?.where((element) => element.label.contains(
                                  widget.agent.department?.label ?? ""))
                              .toList()
                              .first,
                          items: data
                              ?.map((Department department) =>
                                  DropdownMenuItem<Department>(
                                      value: department,
                                      child: Text(department.label)))
                              .toList(),
                          onChanged: (value) {
                            widget.agent.department = value!;
                          },
                          onSaved: (value) {
                            widget.agent.department = value!;
                          },
                        );
                      } else {
                        return const Text(
                            "Chargements des départements en cours...");
                      }
                    }),
                const SizedBox(
                  height: 20,
                ),
                StreamBuilder(
                    stream: AgentTypeService().all(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var docs = snapshot.data?.docs
                            .map((e) => jsonDecode(jsonEncode(e.data())))
                            .toList();

                        List<AgentType>? data =
                            docs?.map((e) => AgentType.fromJson(e)).toList();

                        return DropdownButtonFormField<AgentType>(
                          hint: const Text("Type"),
                          decoration: const InputDecoration(
                              hintText: "Type",
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(Icons.supervised_user_circle_outlined)),
                          validator: (value) {
                            return value != null ? null : "Type obligatoir";
                          },
                          isExpanded: true,
                          value: data
                              ?.where((element) => element.label.contains(
                                  widget.agent.typeAgent?.label ?? ""))
                              .toList()
                              .first,
                          items: data
                              ?.map((AgentType agtType) =>
                                  DropdownMenuItem<AgentType>(
                                      value: agtType,
                                      child: Text(agtType.label)))
                              .toList(),
                          onChanged: (value) {
                            widget.agent.typeAgent = value!;
                          },
                          onSaved: (value) {
                            widget.agent.typeAgent = value!;
                          },
                        );
                      } else {
                        return const Text(
                            "Chargements des départements en cours...");
                      }
                    }),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: true,
                  controller: _site_ctrl,
                  onTap: () async {
                    /*widget.agent.site = await Navigator.push<Site>(context,
                        MaterialPageRoute(builder: (_) => SiteSearch()));
                    widget.agent.site == null
                        ? _site_ctrl.text = ''
                        : _site_ctrl.text = '${widget.agent.site?.name} ';
                    setState(() {});*/
                    await showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            alignment: Alignment.center,
                            contentPadding: const EdgeInsets.all(0.0),
                            content: SiteSearchDialog(
                              onSelected: (site) {
                                widget.agent.site = site;
                                Navigator.pop(context);
                                widget.agent.site == null
                                    ? _site_ctrl.text = ''
                                    : _site_ctrl.text =
                                        '${widget.agent.site?.name} ';
                              },
                            ),
                          );
                        });
                  },
                  validator: (value) {
                    return widget.agent.site != null ? null : "Site obligatoir";
                  },
                  decoration: const InputDecoration(
                      //filled: true,
                      hintText: "Site",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: widget.agent.code.isNotEmpty,
                  controller: _code_ctrl,
                  onChanged: (value) {
                    widget.agent.code = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Code obligatoir";
                  },
                  decoration: const InputDecoration(
                      //filled: true,
                      hintText: "Code",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build_circle)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _firstName_ctrl,
                  onChanged: (value) {
                    widget.agent.firstName = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Prénom obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Prénom",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _lastName_ctrl,
                  onChanged: (value) {
                    widget.agent.lastName = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Nom obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Nom",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _phone_ctrl,
                  onChanged: (value) {
                    widget.agent.phone = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Téléphone obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Téléphone",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: widget.agent.email.isNotEmpty,
                  controller: _email_ctrl,
                  onChanged: (value) {
                    widget.agent.email = value;
                  },
                  decoration: const InputDecoration(
                      hintText: "Email facultatif",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email)),
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
                                widget.agent.code = _code_ctrl.text;
                                widget.agent.firstName = _firstName_ctrl.text;
                                widget.agent.lastName = _lastName_ctrl.text;
                                widget.agent.email = _email_ctrl.text;
                                widget.agent.phone = _phone_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (!widget.update) {
                                    await AgentService()
                                        .add(widget.agent)
                                        .then((value) {
                                      setState(() {
                                        _adding = false;
                                      });
                                      Navigator.of(context).pop();
                                    }).onError((error, stackTrace) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(error.toString())));
                                      setState(() {
                                        _adding = false;
                                      });
                                    });
                                  } else {
                                    await AgentService()
                                        .update(widget.agent)
                                        .then((value) {
                                      setState(() {
                                        _adding = false;
                                      });
                                      Navigator.of(context).pop();
                                    }).onError((error, stackTrace) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(error.toString())));
                                      setState(() {
                                        _adding = false;
                                      });
                                    });
                                  }
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
                          widget.update == false
                              ? const SizedBox.shrink()
                              : widget.manager.profil!
                                      .getModule(ModuleName.AGENT)!
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

                                          await AgentService()
                                              .delete(widget.agent)
                                              .then((value) {
                                            setState(() {
                                              _adding = false;
                                            });
                                            Navigator.of(context).pop();
                                          }).onError((error, stackTrace) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        error.toString())));
                                            setState(() {
                                              _adding = false;
                                            });
                                          });
                                        }
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.delete),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            'Supprimer',
                                            style:
                                                TextStyle(color: Colors.white),
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
