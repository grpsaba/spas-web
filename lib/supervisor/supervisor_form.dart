import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/supervisor.dart';

class AddSupervisor extends StatefulWidget {
  AddSupervisor({super.key, required this.supervisor});
  Supervisor supervisor;

  @override
  _AddSupervisorState createState() => _AddSupervisorState();
}

class _AddSupervisorState extends State<AddSupervisor> {
  final TextEditingController _code_ctrl = TextEditingController();
  final TextEditingController _firstName_ctrl = TextEditingController();
  final TextEditingController _lastName_ctrl = TextEditingController();
  final TextEditingController _phone_ctrl = TextEditingController();
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _pass_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _adding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _email_ctrl.text = widget.supervisor.email;
    _code_ctrl.text = widget.supervisor.code;
    _firstName_ctrl.text = widget.supervisor.firstName;
    _lastName_ctrl.text = widget.supervisor.lastName;
    _phone_ctrl.text = widget.supervisor.phone;
    _pass_ctrl.text = widget.supervisor.code;
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
    _pass_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Edition superviseur",
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
                TextFormField(
                  readOnly: widget.supervisor.code.isNotEmpty,
                  controller: _code_ctrl,
                  onChanged: (value) {
                    widget.supervisor.code = value;
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
                    widget.supervisor.firstName = value;
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
                    widget.supervisor.lastName = value;
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
                    widget.supervisor.phone = value;
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
                  readOnly: widget.supervisor.email.isNotEmpty,
                  controller: _email_ctrl,
                  onChanged: (value) {
                    widget.supervisor.email = value;
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
                widget.supervisor.UID.isNotEmpty
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
                                widget.supervisor.code = _code_ctrl.text;
                                widget.supervisor.firstName =
                                    _firstName_ctrl.text;
                                widget.supervisor.lastName =
                                    _lastName_ctrl.text;
                                widget.supervisor.email = _email_ctrl.text;
                                widget.supervisor.phone = _phone_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (widget.supervisor.UID.isEmpty) {
                                    await SupervisorService()
                                        .add(widget.supervisor, _pass_ctrl.text)
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
                                    await SupervisorService()
                                        .update(widget.supervisor)
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
                          widget.supervisor.UID.isEmpty
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

                                      await SupervisorService()
                                          .delete(widget.supervisor)
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
