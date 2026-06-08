import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';

import '../model.dart';
import '../services/access_control.dart';
import '../services/loading.dart';
import '../services/manager.dart';
import '../services/profil.dart';
import '../services/tenant_options.dart';

class AddManager extends StatefulWidget {
  const AddManager({super.key, required this.manager});
  final Manager manager;

  @override
  _AddSupervisorState createState() => _AddSupervisorState();
}

class _AddSupervisorState extends State<AddManager> {
  final TextEditingController _firstName_ctrl = TextEditingController();
  final TextEditingController _lastName_ctrl = TextEditingController();
  final TextEditingController _phone_ctrl = TextEditingController();
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _pass_ctrl = TextEditingController();
  final TextEditingController _poste_ctrl = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _adding = false;
  bool _loadingTenants = true;
  List<Tenant> _tenants = TenantOptions.fallback;
  String? _selectedTenantId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _email_ctrl.text = widget.manager.email;
    _poste_ctrl.text = widget.manager.poste;
    _firstName_ctrl.text = widget.manager.firstName;
    _lastName_ctrl.text = widget.manager.lastName;
    _phone_ctrl.text = widget.manager.phone;
    _selectedTenantId =
        widget.manager.hasTenantId ? widget.manager.tenantId : null;
    if (!AccessControl.canBypassTenantFilter) {
      _selectedTenantId = AccessControl.currentTenantId;
    }
    _loadTenants();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _phone_ctrl.dispose();
    _lastName_ctrl.dispose();
    _firstName_ctrl.dispose();
    _phone_ctrl.dispose();

    _email_ctrl.dispose();
    _pass_ctrl.dispose();
  }

  Future<void> _loadTenants() async {
    final tenants = await TenantOptions.load(includeTenantId: _selectedTenantId);
    if (!mounted) return;

    setState(() {
      _tenants = AccessControl.canBypassTenantFilter
          ? tenants
          : tenants
              .where((tenant) => tenant.id == AccessControl.currentTenantId)
              .toList();
      if (_tenants.isEmpty) {
        _tenants = [
          Tenant(
            id: AccessControl.currentTenantId,
            label: AccessControl.currentTenantId.toUpperCase(),
            countryCode: AccessControl.currentTenantId.toUpperCase(),
          ),
        ];
      }
      _loadingTenants = false;
    });
  }

  bool get _selectedProfileCanBypassTenant {
    return canBypassTenantForProfile(widget.manager.profil);
  }

  Widget _buildTenantField() {
    if (_loadingTenants) {
      return Loading(size: 28, inline: true);
    }

    final items = <DropdownMenuItem<String?>>[
      if (_selectedProfileCanBypassTenant && AccessControl.canBypassTenantFilter)
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Tous les pays'),
        ),
      ..._tenants.map(
        (tenant) => DropdownMenuItem<String?>(
          value: tenant.id,
          child: Text(tenant.label),
        ),
      ),
    ];

    return DropdownButtonFormField<String?>(
      value: _selectedTenantId,
      hint: const Text('Pays'),
      decoration: const InputDecoration(
        hintText: 'Pays',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.public),
      ),
      validator: (value) {
        if (_selectedProfileCanBypassTenant) return null;
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Pays obligatoir';
      },
      isExpanded: true,
      items: items,
      onChanged: AccessControl.canBypassTenantFilter
          ? (value) {
              setState(() {
                _selectedTenantId = value;
              });
            }
          : null,
      onSaved: (value) {
        _selectedTenantId = value;
      },
    );
  }

  void _applyTenantToManager() {
    final tenantId = _selectedTenantId?.trim();
    widget.manager.hasTenantId = tenantId != null && tenantId.isNotEmpty;
    if (widget.manager.hasTenantId) {
      widget.manager.tenantId = tenantId!;
    } else {
      widget.manager.tenantId = TenantDefaults.defaultTenantId;
    }
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return PageModel(
      pageIndex: 1,
      title: "Gestion utilisateurs -> Edition utilisateur",
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: _padding, right: _padding, top: 8.0, bottom: 8.0),
          child: Form(
            key: _key,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstName_ctrl,
                  onChanged: (value) {
                    widget.manager.firstName = value;
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
                    widget.manager.lastName = value;
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
                    widget.manager.phone = value;
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
                  controller: _poste_ctrl,
                  onChanged: (value) {
                    widget.manager.poste = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "Poste obligatoir";
                  },
                  decoration: const InputDecoration(
                      hintText: "Poste",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(
                  height: 20,
                ),
                StreamBuilder(
                    stream: ProfilService().all(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var docs = snapshot.data?.docs
                            .map((e) => jsonDecode(jsonEncode(e.data())))
                            .toList();
                        List<Profil>? data =
                            docs?.map((e) => Profil.fromJson(e)).toList();

                        return DropdownButtonFormField<Profil>(
                          hint: const Text("Profil"),
                          decoration: const InputDecoration(
                              hintText: "Profil",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person)),
                          validator: (value) {
                            return value != null ? null : "Profil obligatoir";
                          },
                          isExpanded: true,
                          value: widget.manager.profil,
                          items: data
                              ?.map((Profil profil) => DropdownMenuItem<Profil>(
                                  value: profil, child: Text(profil.name)))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              widget.manager.profil = value;
                              if (canBypassTenantForProfile(value)) {
                                _selectedTenantId = null;
                              } else {
                                _selectedTenantId ??=
                                    AccessControl.canBypassTenantFilter
                                        ? null
                                        : AccessControl.currentTenantId;
                              }
                            });
                          },
                          onSaved: (value) {
                            widget.manager.profil = value;
                          },
                        );
                      } else {
                        return const Text(
                            "Chargements des profils en cours...");
                      }
                    }),
                const SizedBox(
                  height: 20,
                ),
                _buildTenantField(),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: widget.manager.email.isNotEmpty,
                  controller: _email_ctrl,
                  onChanged: (value) {
                    widget.manager.email = value;
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
                widget.manager.UID.isNotEmpty
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
                                widget.manager.poste = _poste_ctrl.text;
                                widget.manager.firstName = _firstName_ctrl.text;
                                widget.manager.lastName = _lastName_ctrl.text;
                                widget.manager.email = _email_ctrl.text;
                                widget.manager.phone = _phone_ctrl.text;
                                _applyTenantToManager();

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (widget.manager.UID.isEmpty) {
                                    await ManagerService()
                                        .add(widget.manager, _pass_ctrl.text)
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
                                    await ManagerService()
                                        .update(widget.manager)
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
                          widget.manager.UID.isEmpty
                              ? const SizedBox.shrink()
                              : widget.manager.profil!
                                      .getModule(ModuleName.MANAGER)!
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

                                          await ManagerService()
                                              .delete(widget.manager)
                                              .then((value) {
                                            setState(() {
                                              _adding = false;
                                            });
                                            context.pop();
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
