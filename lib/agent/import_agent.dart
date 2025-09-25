import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/agent/upload_excel_file.dart';
import 'package:spas_web/services/agentType.dart';
import 'package:spas_web/services/department.dart';

import '../liste_selection_pages/site_search_dialog.dart';
import '../model.dart';
import '../services/loading.dart';

class ImportAgent extends StatefulWidget {
  const ImportAgent({
    super.key,
  });

  @override
  _ImportAgentState createState() => _ImportAgentState();
}

class _ImportAgentState extends State<ImportAgent> {
  final TextEditingController _code_ctrl = TextEditingController();
  final TextEditingController _startRow_ctrl = TextEditingController();
  final TextEditingController _firstName_ctrl = TextEditingController();
  final TextEditingController _lastName_ctrl = TextEditingController();
  final TextEditingController _phone_ctrl = TextEditingController();
  final TextEditingController _site_ctrl = TextEditingController();
  final TextEditingController _type_ctrl = TextEditingController();
  final TextEditingController _categorie_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _adding = false;
  late Site _selectedSite;
  final UploadExcel _uploadExcel = UploadExcel(
      site: null,
      type: '',
      domaine: '',
      codeClIndex: 0,
      contactClIndex: 0,
      firstNameClIndex: 0,
      lastNameClIndex: 0,
      sartRowIndex: 0);
  Excel? _excel;
  AgentType _selected_typeAgents = AgentType(label: "");
  Department _selected_departement = Department(label: "");
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _type_ctrl.dispose();
    _phone_ctrl.dispose();
    _lastName_ctrl.dispose();
    _firstName_ctrl.dispose();
    _code_ctrl.dispose();
    _startRow_ctrl.dispose();
    _site_ctrl.dispose();
    _categorie_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).size.width * 0.1;
    return PageModel(
      pageIndex: 3,
      title: "Gestion des agents -> import Agents",
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: padding, right: padding, top: 8.0, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              children: [
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
                                _selectedSite = site;
                                _site_ctrl.text = site.name;
                                _uploadExcel.site = site;
                                Navigator.pop(context);
                              },
                            ),
                          );
                        });
                  },
                  validator: (value) {
                    return _selectedSite != null ? null : "Site obligatoir";
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
                FutureBuilder(
                    future: AgentTypeService().allFuture(),
                    builder: (context, snapshot) {
                      List<AgentType> categories = snapshot.data ?? [];
                      return DropdownButtonFormField(
                        hint: const Text("Catégorie"),
                        decoration: const InputDecoration(
                            hintText: "Catégorie",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work)),
                        validator: (value) {
                          return _selected_typeAgents.label.isNotEmpty
                              ? null
                              : "Catégorie obligatoir";
                        },
                        isExpanded: true,
                        value: null,
                        items: categories
                            .map((e) => DropdownMenuItem<AgentType>(
                                value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (value) {
                          _selected_typeAgents = value!;
                        },
                        onSaved: (value) {
                          _selected_typeAgents = value!;
                        },
                      );
                    }),
                const SizedBox(
                  height: 20,
                ),
                FutureBuilder(
                    future: DepartmentService().allFuture(),
                    builder: (context, snapshot) {
                      List<Department> departements = snapshot.data ?? [];
                      return DropdownButtonFormField(
                        hint: const Text("Domaine"),
                        decoration: const InputDecoration(
                            hintText: "Domaine",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work)),
                        validator: (value) {
                          return _selected_departement.label.isNotEmpty
                              ? null
                              : "Domaine obligatoir";
                        },
                        isExpanded: true,
                        value: null,
                        items: departements
                            .map((e) => DropdownMenuItem<Department>(
                                value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (value) {
                          _selected_departement = value!;
                        },
                        onSaved: (value) {
                          _selected_departement = value!;
                        },
                      );
                    }),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () async {
                      _excel = await _uploadExcel.upload();
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file),
                        _excel != null
                            ? const Text(
                                "Fichier chargé!",
                                style: TextStyle(color: Colors.green),
                              )
                            : const Text("Charger le Fichier Excel")
                      ],
                    )),
                const SizedBox(
                  height: 20,
                ),
                _excel != null
                    ? const Text(
                        "NB: le numéro d'index commence par 0",
                        style: TextStyle(color: Colors.red),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(
                  height: 20,
                ),
                _excel != null
                    ? Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                            controller: _startRow_ctrl,
                            onChanged: (value) {
                              _uploadExcel.sartRowIndex =
                                  int.tryParse(value) ?? 0;
                            },
                            validator: (value) {
                              return int.tryParse(value!) != null
                                  ? null
                                  : "Index invalide";
                            },
                            decoration: const InputDecoration(
                              hintText: "Index première ligne des données",
                              border: OutlineInputBorder(),
                            ),
                          )),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                              child: TextFormField(
                            controller: _code_ctrl,
                            onChanged: (value) {
                              _uploadExcel.codeClIndex =
                                  int.tryParse(value) ?? 0;
                            },
                            validator: (value) {
                              return int.tryParse(value!) != null
                                  ? null
                                  : "Index invalide";
                            },
                            decoration: const InputDecoration(
                              hintText: "Index colonne Matricule",
                              border: OutlineInputBorder(),
                            ),
                          )),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                              child: TextFormField(
                            controller: _firstName_ctrl,
                            onChanged: (value) {
                              _uploadExcel.firstNameClIndex =
                                  int.tryParse(value) ?? 0;
                            },
                            validator: (value) {
                              return int.tryParse(value!) != null
                                  ? null
                                  : "Index invalide";
                            },
                            decoration: const InputDecoration(
                              hintText: "Index colonne Prénom",
                              border: OutlineInputBorder(),
                            ),
                          )),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                              child: TextFormField(
                            controller: _lastName_ctrl,
                            onChanged: (value) {
                              _uploadExcel.lastNameClIndex =
                                  int.tryParse(value) ?? 0;
                            },
                            validator: (value) {
                              return int.tryParse(value!) != null
                                  ? null
                                  : "Index invalide";
                            },
                            decoration: const InputDecoration(
                              hintText: "Index colonne Nom",
                              border: OutlineInputBorder(),
                            ),
                          )),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                              child: TextFormField(
                            controller: _phone_ctrl,
                            onChanged: (value) {
                              _uploadExcel.contactClIndex =
                                  int.tryParse(value) ?? 0;
                            },
                            validator: (value) {
                              return int.tryParse(value!) != null
                                  ? null
                                  : "Index invalide";
                            },
                            decoration: const InputDecoration(
                              hintText: "Index colonne Contact",
                              border: OutlineInputBorder(),
                            ),
                          ))
                        ],
                      )
                    : const SizedBox.shrink(),
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
                              onPressed: () {
                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  _uploadExcel.crateAgentFromExcel(
                                      _excel!,
                                      _selected_departement,
                                      _selected_typeAgents);
                                  setState(() {
                                    _adding = false;
                                    Navigator.pop(context);
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
                                  Text('Importer')
                                ],
                              )),
                          const SizedBox(
                            width: 20,
                          ),
                          _adding
                              ? const SizedBox.shrink()
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      fixedSize: const Size(150, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20))),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cancel),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        'Annuler',
                                        style: TextStyle(color: Colors.white),
                                      )
                                    ],
                                  ))
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
