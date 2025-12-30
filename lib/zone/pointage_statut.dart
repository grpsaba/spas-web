import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:spas_web/const.dart';

import '../model.dart';
import '../services/pointerZone.dart';
import '../services/site.dart';

class ZonePointageProgressBar extends StatefulWidget {
  ZonePointageProgressBar(
      {super.key, required this.zoneMember, DateTime? month})
      : month = month ?? DateTime.now();
  final ZoneMember zoneMember;
  final DateTime month;
  @override
  _ZonePointageProgressBarState createState() =>
      _ZonePointageProgressBarState();
}

class _ZonePointageProgressBarState extends State<ZonePointageProgressBar> {
  //int nbSite = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //WidgetsFlutterBinding.ensureInitialized();
    //getNbSite();
  }

  /*getNbSite() async {
    List<Site> sites = await SiteService().allByZone(widget.zoneMember.zone!);

    nbSite = sites.length;
  }*/

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PointingZone>>(
        stream: PointingZoneService().allByZoneMember(
            zoneMember: widget.zoneMember, month: widget.month),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error.toString());
            return const SizedBox.shrink();
          }
          if (snapshot.hasData) {
            final collection = snapshot.data ?? [];
            final siteIds =
                collection.map((pointing) => pointing.site.UID).toSet();
            return FutureBuilder(
                future: SiteService().allByZone(widget.zoneMember.zone!),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var data = snapshot.data ?? [];
                    int value = siteIds.length;
                    double purcent = 0;
                    //prendre le nombre de site su superviseur
                    if (data.length == 0) {
                      purcent = 0.0;
                    } else {
                      purcent = value * 100 / data.length;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FAProgressBar(
                          //progressType: LinearProgressBar.progressTypeLinear,
                          displayText: "%",
                          size: 12,
                          maxValue: 100.0,
                          currentValue: purcent,
                          progressColor: purcent <= 30
                              ? Colors.red
                              : purcent <= 60
                                  ? Colors.orange
                                  : Colors.green,
                          backgroundColor: AppConstants.bgColor,
                        ),
                        Text("site: $value/${data.length}",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12))
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  } else {
                    return const LinearProgressIndicator();
                  }
                });
          } else {
            return const LinearProgressIndicator();
          }
        });
  }
}
