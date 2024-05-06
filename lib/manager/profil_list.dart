import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/profil.dart';
import 'module_list.dart';

class ProfilList extends StatefulWidget {
  ProfilList({
    super.key,
  });

  @override
  _ProfilListState createState() => _ProfilListState();
}

class _ProfilListState extends State<ProfilList> {
  final ProfilService _service = ProfilService();
  final TextEditingController _texController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  Profil selectedProfil = Profil(name: "", modules: []);
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // liste profil
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(color: Colors.blueGrey),
                child: Form(
                  key: _key,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 250,
                        child: TextFormField(
                          controller: _texController,
                          validator: (value) {
                            return value!.isEmpty
                                ? "Nom du profil obligatoire"
                                : null;
                          },
                          decoration: InputDecoration(
                              hintText: "Ajouter un profil",
                              hintStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.3),
                              border: const OutlineInputBorder(
                                  borderSide: BorderSide.none)),
                        ),
                      ),
                      AuthService.currentManager!.profil!
                              .getModule(ModuleName.MANAGER)!
                              .add
                          ? IconButton(
                              onPressed: () {
                                if (_key.currentState!.validate()) {
                                  ProfilService().add(Profil(
                                      name: _texController.text, modules: []));
                                }
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ))
                          : const SizedBox.shrink()
                    ],
                  ),
                ),
              ),
              StreamBuilder(
                  stream: _service.all(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var docs = snapshot.data?.docs
                          .map((e) => jsonDecode(jsonEncode(e.data())))
                          .toList();
                      var data = docs?.map((e) => Profil.fromJson(e)).toList();

                      //copy to _dataToexport
                      return Container(
                        height: 500,
                        child: ListView.builder(
                            itemCount: data?.length,
                            itemBuilder: (context, index) {
                              Profil? profil = data?[index];
                              return Card(
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      selectedProfil = profil;
                                    });
                                  },
                                  title: Text(profil!.name),
                                  leading: Icon(
                                    Icons.person,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            }),
                      );
                    } else {
                      return Center(
                        child: Loading(
                          size: 64,
                          inline: true,
                        ),
                      );
                    }
                  }),
            ],
          ),
        ),
        //liste module
        AuthService.currentManager!.profil!.getModule(ModuleName.MANAGER)!.add
            ? Expanded(
                flex: 2,
                child: ModuleList(
                  profil: selectedProfil,
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}

//module liste widget
