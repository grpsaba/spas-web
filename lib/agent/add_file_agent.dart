import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:motion_toast/motion_toast.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent.dart';
import 'package:spas_web/uploadManager/upload.dart';
import 'package:universal_html/html.dart' as html;

import '../uploadManager/file_image.dart';
import 'add_contact_button.dart';
import 'add_file_button.dart';

class AgentAddFile extends StatefulWidget {
  const AgentAddFile({super.key, required this.agent});
  final Agent agent;
  @override
  _AgentAddFileState createState() => _AgentAddFileState();
}

class _AgentAddFileState extends State<AgentAddFile>
    with SingleTickerProviderStateMixin {
  String ref = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ref =
        "${widget.agent.firstName} ${widget.agent.lastName} ${widget.agent.phone}";
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 3,
      title: "${widget.agent.firstName} ${widget.agent.lastName}",
      child: Row(
        children: [
          agentInfo(),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //contacts header
                Row(
                  children: [
                    const Text(
                      "Contacts de référence",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          addContact();
                        },
                        style: ElevatedButton.styleFrom(
                            elevation: 0.0,
                            backgroundColor: AppConstants.primaryColor),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.white,
                            ),
                            Text(
                              "Ajouter un Contacts de reference",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                //list Contacts
                widget.agent.contacts == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          ...widget.agent.contacts!.map((contact) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    color:
                                        AppConstants.bgColor.withOpacity(0.7)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      child: Icon(Icons.perm_contact_cal),
                                    ),
                                    const SizedBox(
                                      height: 5.0,
                                    ),
                                    Text(
                                      contact.title,
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    Text(
                                      contact.contact,
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    const SizedBox(
                                      height: 8.0,
                                    ),
                                    IconButton(
                                        tooltip: "Supprimer",
                                        onPressed: () {
                                          deleteContact(contact);
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ))
                                  ],
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                const SizedBox(
                  height: 20,
                ),
                // documents header
                const Divider(),
                Row(
                  children: [
                    const Text(
                      "Documents",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          addFile();
                        },
                        style: ElevatedButton.styleFrom(
                            elevation: 0.0,
                            backgroundColor: AppConstants.primaryColor),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(
                              Icons.phone,
                              color: Colors.white,
                            ),
                            Text(
                              "Ajouter un document",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                //liste documents
                widget.agent.docs == null
                    ? const SizedBox.shrink()
                    : Wrap(
                        spacing: 10.0,
                        children: [
                          ...widget.agent.docs!.map((doc) {
                            return docCard(doc);
                          })
                        ],
                      )
              ],
            ),
          ))
        ],
      ),
    );
  }

  Widget docCard(DocumentFile doc) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage(
                        ExtentionLogo().getLogo(extention: doc.extention)))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Flexible(
                    child: Text(
                  doc.title,
                  textAlign: TextAlign.center,
                )),
                IconButton(
                    tooltip: "Télécharger",
                    onPressed: () {
                      html.window.open(doc.path, "_blank");
                    },
                    icon: const Icon(Icons.download)),
                IconButton(
                    tooltip: "Supprimer",
                    onPressed: () {
                      deleteDoc(doc);
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }

  void addFile() {
    DocumentFile defaultDoc = DocumentFile(title: "", path: "", extention: "");
    showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ajout de document",
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ))
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //on recupère la liste des devises ici

                TextFormField(
                  decoration: const InputDecoration(
                    hintText: "Libellé",
                  ),
                  onChanged: (value) {
                    defaultDoc.title = value;
                  },
                ),
                UploadTaskManager(
                  onUploaded: (link) {
                    defaultDoc.path = link;
                  },
                  ref: ref,
                  onSelected: (extention) {
                    defaultDoc.extention = extention;
                  },
                )
              ],
            ),
            actions: [
              FileFormValidationButton(
                doc: defaultDoc,
                agent: widget.agent,
              )
            ],
          );
        }).then((value) {
      if (value == true) {
        setState(() {});
      }
    });
  }

  Widget agentInfo() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                child: Icon(
                  Icons.person,
                  size: 64,
                ),
              ),
              decoration: const BoxDecoration(color: Colors.transparent),
              accountName: Text(
                "${widget.agent.firstName} ${widget.agent.lastName}",
                style: const TextStyle(color: Colors.black),
              ),
              accountEmail: Text(
                "Contact : ${widget.agent.phone}",
                style: const TextStyle(color: Colors.black),
              )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Code: ${widget.agent.code}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Email: ${widget.agent.email}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Département: ${widget.agent.department?.label ?? ""}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Site: ${widget.agent.site?.name ?? ""}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.agent.dateEmbauche != null
                  ? "Date d'embauche: ${intl.DateFormat.yMd().format(widget.agent.dateEmbauche!)}"
                  : "Date d'embauche:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.agent.dateArret != null
                  ? "Date arrêt: ${intl.DateFormat.yMd().format(widget.agent.dateArret!)}"
                  : "Date arrêt:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  void addContact() {
    ConactReference defaultContact =
        ConactReference(title: "", certified: false, contact: "");
    showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ajout de contact",
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ))
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //on recupère la liste des devises ici

                TextFormField(
                  decoration: const InputDecoration(
                    hintText: "Libellé",
                  ),
                  onChanged: (value) {
                    defaultContact.title = value;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Contact",
                  ),
                  onChanged: (value) {
                    defaultContact.contact = value;
                  },
                ),
              ],
            ),
            actions: [
              ContactFormValidationButton(
                contact: defaultContact,
                agent: widget.agent,
              )
            ],
          );
        }).then((value) {
      if (value == true) {
        setState(() {});
      }
    });
  }

  void deleteContact(ConactReference contact) {
    widget.agent.contacts?.remove(contact);
    AgentService().update(widget.agent).then((value) {
      MotionToast.success(
              description: const Text("Contact supprimé avec succès"))
          .show(context);
      setState(() {});
    }).onError((error, stackTrace) {
      MotionToast.error(description: Text(error.toString())).show(context);
    });
  }

  void deleteDoc(DocumentFile doc) {
    widget.agent.docs?.remove(doc);
    AgentService().update(widget.agent).then((value) {
      MotionToast.success(
              description: const Text("Document supprimé avec succès"))
          .show(context);
      setState(() {});
    }).onError((error, stackTrace) {
      MotionToast.error(description: Text(error.toString())).show(context);
    });
  }
}
