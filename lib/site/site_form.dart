import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:spas_web/liste_selection_pages/supervisor_search_dialog.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/site.dart';

class AddSite extends StatefulWidget {
  AddSite({super.key, required this.site});
  Site site;

  @override
  _AddSupervisorState createState() => _AddSupervisorState();
}

class _AddSupervisorState extends State<AddSite> {
  final TextEditingController _code_ctrl = TextEditingController();
  final TextEditingController _name_ctrl = TextEditingController();
  final TextEditingController _adresse_ctrl = TextEditingController();
  final TextEditingController _phone_ctrl = TextEditingController();
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _lat_ctrl = TextEditingController();
  final TextEditingController _lng_ctrl = TextEditingController();
  final TextEditingController _pass_ctrl = TextEditingController();
  final TextEditingController _supervisor_ctrl = TextEditingController();
  final TextEditingController _supervisor2_ctrl = TextEditingController();
  final TextEditingController _nbagent_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _adding = false;
  bool _isTwoSupervisor = false;
  @override
  void initState() {
    // TODO: implement initState
    _isTwoSupervisor = widget.site.supervisor_2 == null ? false : true;
    super.initState();
    _email_ctrl.text = widget.site.email;
    _code_ctrl.text = widget.site.codeSite;
    _name_ctrl.text = widget.site.name;
    _adresse_ctrl.text = widget.site.adresse;
    _lat_ctrl.text = widget.site.latLng.lat.toString();
    _lng_ctrl.text = widget.site.latLng.lng.toString();
    _pass_ctrl.text = widget.site.codeSite;
    _phone_ctrl.text = widget.site.phone;

    _nbagent_ctrl.text =
        widget.site.nbAgent == 0 ? "" : widget.site.nbAgent.toString();
    _supervisor_ctrl.text = widget.site.supervisor == null
        ? ''
        : '${widget.site.supervisor?.firstName} ${widget.site.supervisor?.lastName}';
    _supervisor2_ctrl.text = widget.site.supervisor_2 == null
        ? ''
        : '${widget.site.supervisor_2?.firstName} ${widget.site.supervisor_2?.lastName}';
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _lng_ctrl.dispose();
    _lat_ctrl.dispose();
    _name_ctrl.dispose();
    _adresse_ctrl.dispose();
    _code_ctrl.dispose();
    _email_ctrl.dispose();
    _pass_ctrl.dispose();
    _supervisor_ctrl.dispose();
    _supervisor2_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Edition de site",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: _padding, right: _padding, top: 20, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Checkbox(
                        value: _isTwoSupervisor,
                        onChanged: (value) {
                          setState(() {
                            _isTwoSupervisor = value!;
                            if (!_isTwoSupervisor) {
                              widget.site.supervisor_2 = null;
                            }
                          });
                        }),
                    _isTwoSupervisor
                        ? const Text("Deux Superviseurs")
                        : const Text("Un Superviseur")
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: _supervisor_ctrl,
                        onTap: () async {
                          await showDialog(
                              context: context,
                              builder: (_) {
                                return AlertDialog(
                                  alignment: Alignment.center,
                                  contentPadding: const EdgeInsets.all(0.0),
                                  content: SupervisorSearchDialog(
                                    onSelected: (supervisor) {
                                      widget.site.supervisor = supervisor;
                                      Navigator.pop(context);
                                      widget.site.supervisor == null
                                          ? _supervisor_ctrl.text = ''
                                          : _supervisor_ctrl.text =
                                              '${widget.site.supervisor?.firstName} ${widget.site.supervisor?.lastName}';
                                    },
                                  ),
                                );
                              });
                        },
                        validator: (value) {
                          return widget.site.supervisor != null
                              ? null
                              : "Superviseur obligatoir";
                        },
                        decoration: const InputDecoration(
                            //filled: true,
                            hintText: "Superviseur 1",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person)),
                      ),
                    ),
                    !_isTwoSupervisor
                        ? const SizedBox.shrink()
                        : const SizedBox(
                            width: 20,
                          ),
                    !_isTwoSupervisor
                        ? const SizedBox.shrink()
                        : Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: _supervisor2_ctrl,
                              onTap: () async {
                                await showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        alignment: Alignment.center,
                                        contentPadding:
                                            const EdgeInsets.all(0.0),
                                        content: SupervisorSearchDialog(
                                          onSelected: (supervisor) {
                                            widget.site.supervisor_2 =
                                                supervisor;
                                            Navigator.pop(context);
                                            widget.site.supervisor_2 == null
                                                ? _supervisor2_ctrl.text = ''
                                                : _supervisor2_ctrl.text =
                                                    '${widget.site.supervisor_2?.firstName} ${widget.site.supervisor_2?.lastName}';
                                          },
                                        ),
                                      );
                                    });
                              },
                              decoration: const InputDecoration(
                                  //filled: true,
                                  hintText: "Superviseur 2",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person)),
                            ),
                          ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                        child: TextFormField(
                      readOnly: widget.site.codeSite.isNotEmpty,
                      controller: _code_ctrl,
                      onChanged: (value) {
                        widget.site.codeSite = value;
                      },
                      validator: (value) {
                        return value!.isNotEmpty ? null : "Code obligatoir";
                      },
                      decoration: const InputDecoration(
                          //filled: true,
                          hintText: "Code",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.build_circle)),
                    ))
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _name_ctrl,
                        onChanged: (value) {
                          widget.site.name = value;
                        },
                        validator: (value) {
                          return value!.isNotEmpty ? null : "Nom obligatoir";
                        },
                        decoration: const InputDecoration(
                            hintText: "Nom",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person)),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                        child: TextFormField(
                      keyboardType: TextInputType.phone,
                      controller: _phone_ctrl,
                      onChanged: (value) {
                        widget.site.phone = value;
                      },
                      validator: (value) {
                        return value!.isNotEmpty ? null : "Contact obligatoir";
                      },
                      decoration: const InputDecoration(
                          hintText: "Contact",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin_circle_outlined)),
                    ))
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adresse_ctrl,
                        onChanged: (value) {
                          widget.site.adresse = value;
                        },
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "Adresse obligatoir";
                        },
                        decoration: const InputDecoration(
                            hintText: "Adresse",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin_circle_outlined)),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _nbagent_ctrl,
                        onChanged: (value) {
                          widget.site.nbAgent = int.parse(value);
                        },
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "Nombre agent obligatoir";
                        },
                        decoration: const InputDecoration(
                            hintText: "Nombre agent prévus",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person)),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: const Text("Position GPS")),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _lat_ctrl,
                      onChanged: (value) {
                        widget.site.latLng.lat = double.parse(value);
                      },
                      validator: (value) {
                        return value!.isNotEmpty ? null : "Latitude obligatoir";
                      },
                      decoration: const InputDecoration(
                          hintText: "Latitude",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on)),
                    )),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _lng_ctrl,
                        onChanged: (value) {
                          widget.site.latLng.lng = double.parse(value);
                        },
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "Longitude obligatoir";
                        },
                        decoration: const InputDecoration(
                            hintText: "Longitude",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                      readOnly: widget.site.email.isNotEmpty,
                      controller: _email_ctrl,
                      onChanged: (value) {
                        widget.site.email = value;
                      },
                      validator: (value) {
                        return EmailValidator.validate(value!)
                            ? null
                            : "email invalide";
                      },
                      decoration: const InputDecoration(
                          hintText: "Email",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email)),
                    )),
                    const SizedBox(
                      width: 20,
                    ),
                    widget.site.UID.isNotEmpty
                        ? const SizedBox.shrink()
                        : Expanded(
                            child: TextFormField(
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
                                          _obscurePass =
                                              _obscurePass ? false : true;
                                        });
                                      },
                                      icon: _obscurePass
                                          ? const Icon(Icons.remove_red_eye)
                                          : const Icon(
                                              Icons.remove_red_eye_outlined)),
                                  prefixIcon: const Icon(Icons.password)),
                            ),
                          ),
                  ],
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
                                widget.site.codeSite = _code_ctrl.text;
                                widget.site.name = _name_ctrl.text;
                                widget.site.adresse = _adresse_ctrl.text;
                                widget.site.email = _email_ctrl.text;
                                widget.site.phone = _phone_ctrl.text;
                                widget.site.latLng.lng =
                                    double.parse(_lng_ctrl.text);
                                widget.site.latLng.lat =
                                    double.parse(_lat_ctrl.text);

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (widget.site.UID.isEmpty) {
                                    SiteService()
                                        .add(widget.site, _pass_ctrl.text)
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
                                    SiteService()
                                        .update(widget.site)
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
                          widget.site.UID.isEmpty
                              ? const SizedBox.shrink()
                              : ElevatedButton(
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
