import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/zone.dart';
import '../services/zoneMember.dart';

class AddZoneMember extends StatefulWidget {
  AddZoneMember({super.key, required this.zoneMember, required this.manager});
  ZoneMember zoneMember;
  Manager manager;

  @override
  _AddZoneMemberState createState() => _AddZoneMemberState();
}

class _AddZoneMemberState extends State<AddZoneMember> {
  final TextEditingController _code_ctrl = TextEditingController();
  final TextEditingController _firstName_ctrl = TextEditingController();
  final TextEditingController _lastName_ctrl = TextEditingController();
  final TextEditingController _phone_ctrl = TextEditingController();
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _pass_ctrl = TextEditingController();
  final TextEditingController _post_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _adding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _post_ctrl.text = widget.zoneMember.poste!;
    _email_ctrl.text = widget.zoneMember.email;
    _code_ctrl.text = widget.zoneMember.code;
    _firstName_ctrl.text = widget.zoneMember.firstName;
    _lastName_ctrl.text = widget.zoneMember.lastName;
    _phone_ctrl.text = widget.zoneMember.phone;
    _pass_ctrl.text = widget.zoneMember.code;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _post_ctrl.dispose();
    _phone_ctrl.dispose();
    _lastName_ctrl.dispose();
    _firstName_ctrl.dispose();
    _code_ctrl.dispose();
    _email_ctrl.dispose();
    _pass_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Edition Chef de zone",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: _padding, right: _padding, top: 8.0, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              children: [
                StreamBuilder(
                    stream: ZoneService().all(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var docs = snapshot.data?.docs
                            .map((e) => jsonDecode(jsonEncode(e.data())))
                            .toList();
                        List<Zone>? data =
                            docs?.map((e) => Zone.fromJson(e)).toList();

                        return DropdownButtonFormField<Zone>(
                          hint: const Text("Zone"),
                          decoration: const InputDecoration(
                              hintText: "Zone",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.apartment)),
                          validator: (value) {
                            return value != null ? null : "Zone obligatoir";
                          },
                          isExpanded: true,
                          value: data
                              ?.where((element) => element.codeZone.contains(
                                  widget.zoneMember.zone?.codeZone ?? ""))
                              .toList()
                              .first,
                          items: data
                              ?.map((Zone zone) => DropdownMenuItem<Zone>(
                                  value: zone, child: Text(zone.name)))
                              .toList(),
                          onChanged: (value) {
                            widget.zoneMember.zone = value!;
                          },
                          onSaved: (value) {
                            widget.zoneMember.zone = value!;
                          },
                        );
                      } else {
                        return const Text("Chargements des zones en cours...");
                      }
                    }),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: widget.zoneMember.code.isNotEmpty,
                  controller: _code_ctrl,
                  onChanged: (value) {
                    widget.zoneMember.code = value;
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
                    widget.zoneMember.firstName = value;
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
                    widget.zoneMember.lastName = value;
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
                  controller: _post_ctrl,
                  onChanged: (value) {
                    widget.zoneMember.poste = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Poste obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Poste",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _phone_ctrl,
                  onChanged: (value) {
                    widget.zoneMember.phone = value;
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
                  readOnly: widget.zoneMember.email.isNotEmpty,
                  controller: _email_ctrl,
                  onChanged: (value) {
                    widget.zoneMember.email = value;
                  },
                  validator: (value) {
                    return EmailValidator.validate(value!)
                        ? null
                        : "email obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(
                  height: 20,
                ),
                widget.zoneMember.UID.isNotEmpty
                    ? const SizedBox.shrink()
                    : TextFormField(
                        obscureText: _obscurePass,
                        controller: _pass_ctrl,
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "mot de passe obligatoir";
                        },
                        decoration: InputDecoration(
                            hintText: "Mot de passe",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePass = _obscurePass ? false : true;
                                  });
                                },
                                icon: _obscurePass
                                    ? const Icon(Icons.remove_red_eye)
                                    : const Icon(
                                        Icons.remove_red_eye_outlined)),
                            prefixIcon: const Icon(Icons.password)),
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
                                widget.zoneMember.poste = _post_ctrl.text;
                                widget.zoneMember.code = _code_ctrl.text;
                                widget.zoneMember.firstName =
                                    _firstName_ctrl.text;
                                widget.zoneMember.lastName =
                                    _lastName_ctrl.text;
                                widget.zoneMember.email = _email_ctrl.text;
                                widget.zoneMember.phone = _phone_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (widget.zoneMember.UID.isEmpty) {
                                    await ZoneMemberService()
                                        .add(widget.zoneMember, _pass_ctrl.text)
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
                                    await ZoneMemberService()
                                        .update(widget.zoneMember)
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
                          widget.zoneMember.UID.isEmpty
                              ? const SizedBox.shrink()
                              : widget.manager.profil!
                                      .getModule(ModuleName.SUPERVISEUR)!
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

                                          await ZoneMemberService()
                                              .delete(widget.zoneMember)
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
                                  : const SizedBox.shrink(),
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
