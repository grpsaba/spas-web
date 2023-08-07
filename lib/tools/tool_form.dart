import 'package:flutter/material.dart';

import '../liste_selection_pages/site_search_dialog.dart';
import '../model.dart';
import '../services/loading.dart';
import '../services/tool.dart';

class AddTool extends StatefulWidget {
  AddTool({super.key, required this.tool, this.update = false});
  Tool tool;
  bool update;

  @override
  _AddSupervisorState createState() => _AddSupervisorState();
}

class _AddSupervisorState extends State<AddTool> {
  TextEditingController _sn_ctrl = TextEditingController();
  TextEditingController _label_ctrl = TextEditingController();

  TextEditingController _site_ctrl = TextEditingController();
  GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _adding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _sn_ctrl.text = widget.tool.serialNumber;
    _label_ctrl.text = widget.tool.label;

    _site_ctrl.text =
        widget.tool.site == null ? '' : '${widget.tool.site?.name}';
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _sn_ctrl.dispose();
    _label_ctrl.dispose();
    _site_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _padding = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Edition Matériel",
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
                                widget.tool.site = site;
                                Navigator.pop(context);
                                widget.tool.site == null
                                    ? _site_ctrl.text = ''
                                    : _site_ctrl.text =
                                        '${widget.tool.site?.name} ';
                              },
                            ),
                          );
                        });
                  },
                  validator: (value) {
                    return widget.tool.site != null ? null : "Site obligatoir";
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
                  readOnly: widget.tool.serialNumber.isNotEmpty,
                  controller: _sn_ctrl,
                  onChanged: (value) {
                    widget.tool.serialNumber = value;
                  },
                  validator: (value) {
                    return value!.isNotEmpty ? null : "SN obligatoir";
                  },
                  decoration: const InputDecoration(
                      //filled: true,
                      hintText: "Numéro de série",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build_circle)),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _label_ctrl,
                  onChanged: (value) {
                    widget.tool.label = value;
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
                                widget.tool.serialNumber = _sn_ctrl.text;
                                widget.tool.label = _label_ctrl.text;

                                if (_key.currentState!.validate()) {
                                  setState(() {
                                    _adding = true;
                                  });
                                  if (!widget.update) {
                                    await ToolService()
                                        .add(widget.tool)
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
                                    await ToolService()
                                        .update(widget.tool)
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

                                      await ToolService()
                                          .delete(widget.tool)
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
