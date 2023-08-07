import 'package:flutter/material.dart';

import '../model.dart';
import '../services/agent.dart';
import '../services/loading.dart';
import '../services/supervisor.dart';

class SiteDetail extends StatefulWidget {
  SiteDetail({super.key, required this.site});
  Site site;
  @override
  State<SiteDetail> createState() => _SupervisorDetalState();
}

class _SupervisorDetalState extends State<SiteDetail> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.site.name,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              labelColor: Theme.of(context).primaryColor,
              tabs: [
                tabLabelAgent(),
                const Tab(
                  text: "Matériaux",
                ),
                const Tab(
                  text: "Superviseur",
                )
              ],
            ),
          ),
          body: TabBarView(
            children: [
              agentList(),
              const Text("Materiaux"),
              siteSupervisor(),
            ],
          ),
        ));
  }

  Widget siteSupervisor() {
    return FutureBuilder(
        future: SupervisorService().one(widget.site.supervisor?.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (snapshot.hasData) {
            var data = snapshot.data;
            return header(data!);
          } else {
            return Center(
              child: Loading(
                size: 64,
                inline: false,
              ),
            );
          }
        });
  }

  Widget qrZone(Supervisor supervisor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Image(
          image: AssetImage("assets/agent.png"),
          width: 250,
          height: 250,
        ),
        Column(children: [
          Text(
            supervisor.firstName,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 25),
          ),
          Text(
            supervisor.lastName,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 25),
          ),
        ]),
      ],
    );
  }

  Widget detailZone(Supervisor supervisor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Code: ${supervisor.code}",
          style: const TextStyle(
              color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          "Contact : ${supervisor.phone}",
          style: const TextStyle(
              color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          "email: ${supervisor.email}",
          style: const TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              overflow: TextOverflow.fade),
        ),
      ],
    );
  }

  Widget header(Supervisor supervisor) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          )),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [qrZone(supervisor), detailZone(supervisor)],
            ),
          ),
        ],
      ),
    );
  }

  Widget agentList() {
    return FutureBuilder(
        future: AgentService().allBySite(widget.site.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (snapshot.hasData) {
            var data = snapshot.data;
            return ListView.builder(
                itemCount: data!.length,
                itemBuilder: (context, index) {
                  Agent agent = data![index];
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          "${agent.firstName} ${agent.lastName}",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Contact ${agent.phone}  IM:${agent.code}"),
                            Text(
                                "Superviseur 1: ${agent.site?.supervisor?.firstName} ${agent.site?.supervisor?.lastName}"),
                            agent.site?.supervisor_2 == null
                                ? const SizedBox.shrink()
                                : Text(
                                    "Superviseur 2: ${agent.site?.supervisor_2?.firstName} ${agent.site?.supervisor_2?.lastName}"),
                            Text("Email ${agent.email}")
                          ],
                        ),
                        leading: const CircleAvatar(
                          backgroundImage: AssetImage("assets/icon_agent.png"),
                        ),
                        onTap: () {},
                      ),
                      const Divider()
                    ],
                  );
                });
          } else {
            return Center(
              child: Loading(
                size: 64,
                inline: false,
              ),
            );
          }
        });
  }

  Widget tabLabelAgent() {
    return FutureBuilder(
        future: AgentService().allBySite(widget.site.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Tab(text: "Agents");
          if (snapshot.hasData) {
            var data = snapshot.data;
            return Tab(text: "${data?.length} Agents");
          } else {
            return const Tab(text: "Agents");
          }
        });
  }
}
