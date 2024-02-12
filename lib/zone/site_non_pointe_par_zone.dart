import 'package:flutter/material.dart';
import 'package:spas_web/services/site.dart';

import '../generated/assets.dart';
import '../model.dart';
import '../services/loading.dart';
import '../services/pointerZone.dart';

class SiteNonVisiteParZone extends StatefulWidget {
  SiteNonVisiteParZone({super.key, required this.zoneMember});
  ZoneMember zoneMember;
  @override
  _SiteNonVisiteParZoneState createState() => _SiteNonVisiteParZoneState();
}

class _SiteNonVisiteParZoneState extends State<SiteNonVisiteParZone> {
  final SiteService _service = SiteService();

  List<Site> _siteOfZone = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsFlutterBinding.ensureInitialized();
    getSiteOfSupervisor();
  }

  getSiteOfSupervisor() async {
    _siteOfZone = await _service.allAsModel();
    _siteOfZone = _siteOfZone
        .where((element) =>
            element.actif == true && (element.zone == widget.zoneMember.zone))
        .toList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      //height: MediaQuery.of(context).size.height - 192,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Sites non visités par ${widget.zoneMember.firstName} ${widget.zoneMember.lastName}",
                style: const TextStyle(fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ))
            ],
          ),
          const Divider(),
          Expanded(
            //height: MediaQuery.of(context).size.height -
            //   (MediaQuery.of(context).size.height - 556),
            child: FutureBuilder(
                future: PointingZoneService().allFuture(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var data = snapshot.data
                        ?.where((element) =>
                            element.isToday() &&
                            element.zoneMember?.UID == widget.zoneMember.UID)
                        .toList();

                    List<Site> siteNonPointe = [];
                    for (Site site in _siteOfZone) {
                      List<PointingZone> fitch = [];
                      fitch = data
                              ?.where((element) => element.site.UID == site.UID)
                              .toList() ??
                          [];
                      if (fitch.isEmpty) {
                        siteNonPointe.add(site);
                      }
                    }
                    return ListView.builder(
                        itemCount: siteNonPointe.length,
                        itemBuilder: (context, index) {
                          Site? site = siteNonPointe[index];
                          return Card(
                            elevation: 0.3,
                            child: ListTile(
                              leading: const CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                    AssetImage(Assets.assetsIconSite),
                              ),
                              title: Text(site.name,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  )),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Adresse : ${site.adresse}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      )),
                                  Text("Phone : ${site.phone}",
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        });
                  } else {
                    return Center(
                      child: Loading(
                        size: 64,
                        inline: true,
                      ),
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }
}
