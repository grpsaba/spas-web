import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/services/Categorietool.dart';
import 'package:spas_web/services/department.dart';

import '../model.dart';
import '../services/loading.dart';

class AddCatTool extends StatefulWidget {
  AddCatTool({super.key, required this.catTool, required this.manager});
  CategorieTool catTool;

  Manager manager;
  @override
  _AddCatToolState createState() => _AddCatToolState();
}

class _AddCatToolState extends State<AddCatTool> {
  final TextEditingController _label_ctrl = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _adding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _label_ctrl.text = widget.catTool.label;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _label_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Edition Equipement",
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
                TextFormField(
                  controller: _label_ctrl,
                  onChanged: (value) {
                    widget.catTool.label = value;
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
                              prefixIcon: Icon(Icons.person)),
                          validator: (value) {
                            return value != null
                                ? null
                                : "Département obligatoir";
                          },
                          isExpanded: true,
                          value: data
                              ?.where((element) => element.label.contains(
                                  widget.catTool.department?.label ?? ""))
                              .toList()
                              .first,
                          items: data
                              ?.map((Department department) =>
                                  DropdownMenuItem<Department>(
                                      value: department,
                                      child: Text(department.label)))
                              .toList(),
                          onChanged: (value) {
                            widget.catTool.department = value!;
                          },
                          onSaved: (value) {
                            widget.catTool.department = value!;
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
                                widget.catTool.label = _label_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });

                                  await CategorieToolService()
                                      .add(widget.catTool)
                                      .then((value) {
                                    setState(() {
                                      _adding = false;
                                    });
                                    Navigator.of(context).pop();
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
                          widget.manager.profil!
                                  .getModule(ModuleName.CATEGORIE_TOOL)!
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

                                      await CategorieToolService()
                                          .delete(widget.catTool)
                                          .then((value) {
                                        setState(() {
                                          _adding = false;
                                        });
                                        Navigator.of(context).pop();
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
