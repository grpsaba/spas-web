import 'package:flutter/material.dart';

import '../model.dart';
import '../services/profil.dart';

class ModuleList extends StatefulWidget {
  ModuleList({super.key, required this.profil});
  Profil profil;
  @override
  _ModuleListState createState() => _ModuleListState();
}

class _ModuleListState extends State<ModuleList> {
  final TextEditingController _texController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final List<ModuleName> _moduleNames = ModuleName.values;
  final Module _module = Module(
      moduleName: ModuleName.MANAGER,
      add: true,
      delete: false,
      validation: false,
      view: false,
      print: true,
      generBadge: true);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _texController.dispose();
  }

  List<Module> _completeModules(List<Module> existingModules) {
    return ModuleName.values.map((moduleName) {
      return existingModules.firstWhere(
        (module) => module.moduleName == moduleName,
        orElse: () => Module(
          moduleName: moduleName,
          add: false,
          delete: false,
          validation: false,
          view: false,
          print: false,
          generBadge: false,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.profil.name,
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        /* Container(
          padding: const EdgeInsets.all(8.0),
          //decoration: BoxDecoration(color: Colors.blueGrey),
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profil.name,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<ModuleName>(
                  hint: const Text("Module"),
                  decoration: const InputDecoration(
                      hintText: "Module",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work)),
                  validator: (value) {
                    return value != null ? null : "Module obligatoir";
                  },
                  isExpanded: true,
                  value: _moduleNames.first,
                  items: _moduleNames
                      .map((e) => DropdownMenuItem<ModuleName>(
                          value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (value) {
                    _module.moduleName = value!;
                  },
                  onSaved: (value) {
                    _module.moduleName = value!;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                            value: _module.validation,
                            onChanged: (value) {
                              setState(() {
                                _module.validation =
                                    _module.validation ? false : true;
                              });
                            }),
                        const Text('Validation')
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: _module.add,
                            onChanged: (value) {
                              setState(() {
                                _module.add = _module.add ? false : true;
                              });
                            }),
                        const Text('Ajout')
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: _module.delete,
                            onChanged: (value) {
                              setState(() {
                                _module.delete = _module.delete ? false : true;
                              });
                            }),
                        const Text('Suppression')
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: _module.view,
                            onChanged: (value) {
                              setState(() {
                                _module.view = _module.view ? false : true;
                              });
                            }),
                        const Text('Visualisation')
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: _module.print,
                            onChanged: (value) {
                              setState(() {
                                _module.print = _module.print ? false : true;
                              });
                            }),
                        const Text('Impression')
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: _module.generBadge,
                            onChanged: (value) {
                              setState(() {
                                _module.generBadge =
                                    _module.generBadge ? false : true;
                              });
                            }),
                        const Text('Générer les codes QR')
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                FittedBox(
                  child: ElevatedButton(
                      onPressed: () {
                        if (_key.currentState!.validate()) {
                          Module module = _module;
                          widget.profil.modules.add(module);
                          ProfilService().update(widget.profil).then((value) {
                            setState(() {});
                          });
                        }
                      },
                      child: const Row(
                        children: [
                          Text("Ajouter"),
                          Icon(
                            Icons.add,
                          ),
                        ],
                      )),
                )
              ],
            ),
          ),
        ),*/
        FutureBuilder(
            future: ProfilService().one(widget.profil.name),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var profil = snapshot.data;
                if (profil == null) return const SizedBox.shrink();
                final modules = _completeModules(profil.modules);
                profil.modules = modules;

                return SizedBox(
                  height: MediaQuery.of(context).size.height - 160,
                  child: ListView.builder(
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        Module? module = modules[index];
                        return Card(
                          child: ListTile(
                            onTap: () {},
                            title: Text(module!.moduleName.name),
                            subtitle: Row(
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                        value: module.validation,
                                        onChanged: (value) {
                                          module.validation = value!;
                                          ProfilService()
                                              .update(profil!)
                                              .then((value) {
                                            setState(() {});
                                          });
                                        }),
                                    const Text('Validation')
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                        value: module.add,
                                        onChanged: (value) {
                                          module.add = value!;
                                          ProfilService()
                                              .update(profil!)
                                              .then((value) {
                                            setState(() {});
                                          });
                                        }),
                                    const Text('Ajout')
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                        value: module.delete,
                                        onChanged: (value) {
                                          module.delete = value!;
                                          ProfilService()
                                              .update(profil!)
                                              .then((value) {
                                            setState(() {});
                                          });
                                        }),
                                    const Text('Suppression')
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                        value: module.view,
                                        onChanged: (value) {
                                          module.view = value!;
                                          ProfilService()
                                              .update(profil!)
                                              .then((value) {
                                            setState(() {});
                                          });
                                        }),
                                    const Text('Visualisation')
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                        value: module.print,
                                        onChanged: (value) {
                                          module.print = value!;
                                          ProfilService()
                                              .update(profil!)
                                              .then((value) {
                                            setState(() {});
                                          });
                                        }),
                                    const Text('Impression')
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                        value: module.generBadge,
                                        onChanged: (value) {
                                          module.generBadge = value!;
                                          ProfilService()
                                              .update(profil!)
                                              .then((value) {
                                            setState(() {});
                                          });
                                        }),
                                    const Text('Générer QR code')
                                  ],
                                )
                              ],
                            ),
                            leading: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                            /* trailing: IconButton(
                              onPressed: () {
                                profil?.modules.removeAt(index);
                                ProfilService().update(profil!).then((value) {
                                  setState(() {});
                                });
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),*/
                          ),
                        );
                      }),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
      ],
    );
  }
}
