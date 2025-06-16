import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:spas_web/administration/path_error_page.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/generated/assets.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent.dart';
import 'package:spas_web/services/loading.dart';
import 'package:universal_html/html.dart' as html;

import '../uploadManager/file_image.dart';

class AgentFolder extends StatefulWidget {
  const AgentFolder({super.key, this.code = "XXXX"});
  final String? code;
  @override
  _AgentFolderState createState() => _AgentFolderState();
}

class _AgentFolderState extends State<AgentFolder>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.code == null
        ? const PathErrorPage2(
            error: 'Code agent inconnu',
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: AppConstants.primaryColor,
              leading: const Image(
                image: AssetImage(Assets.assetsLogo),
              ),
              title: const Text(
                "GROUPE SABA : CONSULTATION DE DOSSIER AGANT",
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: FutureBuilder(
              future: AgentService().one(widget.code),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Agent? agent = snapshot.data;
                  if (agent == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 80,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Agent ${widget.code} introuvable!",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 20),
                          )
                        ],
                      ),
                    );
                  } else {
                    return body(agent);
                  }
                } else {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 80,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Agent ${widget.code} introuvable!",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 20),
                          )
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Loading(size: 64, inline: false),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Recherche de l'agent ${widget.code} en cours...",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 20),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          );
  }

  Widget body(Agent agent) {
    return Row(
      children: [
        agentInfo(agent),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //contacts header
              const Text(
                "Contacts de référence",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(
                height: 10,
              ),
              //list Contacts
              agent.contacts == null
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        ...agent.contacts!.map((contact) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  color: AppConstants.bgColor.withOpacity(0.7)),
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
              const Text(
                "Documents",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(
                height: 15,
              ),
              //liste documents
              agent.docs == null
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 10.0,
                      children: [
                        ...agent.docs!.map((doc) {
                          return docCard(doc);
                        })
                      ],
                    )
            ],
          ),
        ))
      ],
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
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget agentInfo(Agent agent) {
    return Container(
      width: 250,
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3)),
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
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3)),
              accountName: Text(
                "${agent.firstName} ${agent.lastName}",
                style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold),
              ),
              accountEmail: RichText(
                text: TextSpan(
                    children: [
                      TextSpan(
                          text: agent.phone,
                          style: const TextStyle(color: Colors.black))
                    ],
                    text: "CONTACT: ",
                    style: const TextStyle(color: AppConstants.primaryColor)),
              )),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: agentInfoItem(title: "CODE", value: agent.code)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: agentInfoItem(title: "EMAIL", value: agent.email),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: agentInfoItem(
                title: "DEPARTEMENT", value: agent.department?.label ?? ""),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: agentInfoItem(title: "SITE", value: agent.site?.name ?? ""),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: agentInfoItem(
                title: "DATE D'EMBAUCHE",
                value: agent.dateEmbauche != null
                    ? intl.DateFormat.yMd().format(agent.dateEmbauche!)
                    : ""),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: agentInfoItem(
                title: "DATE ARRÊT",
                value: agent.dateArret != null
                    ? intl.DateFormat.yMd().format(agent.dateArret!)
                    : ""),
          ),
        ],
      ),
    );
  }

  Widget agentInfoItem({required String title, required String value}) {
    return RichText(
      text: TextSpan(
          children: [
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: Colors.black, fontStyle: FontStyle.italic))
          ],
          text: "$title : ",
          style: const TextStyle(
              color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
    );
  }
}
