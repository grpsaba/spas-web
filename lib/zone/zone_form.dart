import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/zone.dart';

import '../model.dart';
import '../services/loading.dart';

class AddZone extends StatefulWidget {
  AddZone({
    super.key,
    required this.zone,
  });
  Zone zone;

  @override
  _AddZoneState createState() => _AddZoneState();
}

class _AddZoneState extends State<AddZone> {
  final TextEditingController _code_ctrl = TextEditingController();
  final TextEditingController _name_ctrl = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _adding = false;
  late final bool _isCreateMode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _isCreateMode = widget.zone.codeZone.isEmpty;
    _code_ctrl.text = widget.zone.codeZone;
    _name_ctrl.text = widget.zone.name;

    WidgetsFlutterBinding.ensureInitialized();
  }

  /*getSiteCode() async {
    List<Site> sites = await SiteService().allAsModel();
    if (widget.site.codeSite.isNotEmpty) {
      _code_ctrl.text = widget.site.codeSite;
    } else {
      _code_ctrl.text = "SABA${sites.length + 1}";
    }
  }*/

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _name_ctrl.dispose();

    _code_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return PageModel(
      pageIndex: 14,
      title: "Gestion des zones -> Edition de Zone",
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: _padding, right: _padding, top: 20, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _name_ctrl,
                  onChanged: (value) {
                    widget.zone.name = value;
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
                  readOnly: !_isCreateMode,
                  controller: _code_ctrl,
                  onChanged: (value) {
                    widget.zone.codeZone = value;
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
                                if (widget.zone.codeZone.isEmpty) {
                                  widget.zone.codeZone = _code_ctrl.text;
                                }
                                widget.zone.name = _name_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (_isCreateMode) {
                                    ZoneService()
                                        .add(widget.zone)
                                        .then((value) {
                                      setState(() {
                                        _adding = false;
                                      });
                                      context.pop();
                                    }).onError((error, stackTrace) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(error.toString())));
                                      setState(() {
                                        _adding = false;
                                      });
                                    });
                                  } else {
                                    ZoneService()
                                        .update(widget.zone)
                                        .then((value) {
                                      setState(() {
                                        _adding = false;
                                      });
                                      context.pop();
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
                          widget.zone.codeZone.isEmpty
                              ? const SizedBox.shrink()
                              : AuthService.currentManager!.profil!
                                      .getModule(ModuleName.SITE)!
                                      .delete
                                  ? const SizedBox
                                      .shrink() /*ElevatedButton(
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

                                          await SiteService()
                                              .delete(widget.site)
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
                                      ))*/
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
