import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/services/pointerSite.dart';
import 'package:spas_web/models/date_filter.dart';

import '../model.dart';
import '../services/site.dart';

class NbPointageStatus extends StatefulWidget {
  final Supervisor supervisor;
  final DateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const NbPointageStatus({
    super.key,
    required this.supervisor,
    this.dateFilter = DateFilter.today,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  _NbAgentStatusState createState() => _NbAgentStatusState();
}

class _NbAgentStatusState extends State<NbPointageStatus> {
  //int nbSite = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // WidgetsFlutterBinding.ensureInitialized();
    //getNbSite();
  }

  /*getNbSite() async {
    List<Site> sites =
        await SiteService().allBySupervisor(widget.supervisor.UID);

    nbSite = sites.length;
  }*/

  DateTime get _startDate {
    if (widget.dateFilter == DateFilter.custom &&
        widget.customStartDate != null) {
      return widget.customStartDate!;
    }
    return widget.dateFilter.startDate;
  }

  DateTime get _endDate {
    if (widget.dateFilter == DateFilter.custom &&
        widget.customEndDate != null) {
      return widget.customEndDate!;
    }
    return widget.dateFilter.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: PointingSiteService().getPointingStatsBySupervisor(
          supervisor: widget.supervisor,
          startDate: _startDate,
          endDate: _endDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasData) {
            // Traitement optimisé côté Firebase - plus de filtrage frontend
            var docs = snapshot.data?.docs.map((e) => e.data()).toList();
            var collection = docs
                ?.map((e) => PointingSite.fromJson(e as Map<String, dynamic>))
                .toList();

            // Utiliser Set pour éviter les doublons de sites
            Set<String> uniqueSiteIds =
                collection?.map((e) => e.site.UID).toSet() ?? {};
            int visitedSitesCount = uniqueSiteIds.length;

            return FutureBuilder(
                future:
                    SiteService().allSitesCountBySupervisor(widget.supervisor),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    int nbTotalSites = snapshot.data ?? 0;
                    int diviseur = nbTotalSites <= 0 ? 1 : nbTotalSites;
                    double percentage = (visitedSitesCount * 100.0 / diviseur)
                        .clamp(0.0, 100.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FAProgressBar(
                          displayText: "%",
                          size: 12,
                          maxValue: 100.0,
                          currentValue: percentage,
                          progressColor: percentage <= 30
                              ? Colors.red
                              : percentage <= 60
                                  ? Colors.orange
                                  : Colors.green,
                          backgroundColor: AppConstants.bgColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sites: $visitedSitesCount/$nbTotalSites",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        if (widget.dateFilter != DateFilter.today)
                          Text(
                            widget.dateFilter.label,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return const Text(
                      "Erreur de chargement",
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    );
                  } else {
                    return const SizedBox(
                      height: 12,
                      child: LinearProgressIndicator(),
                    );
                  }
                });
          } else {
            return const SizedBox(
              height: 12,
              child: LinearProgressIndicator(),
            );
          }
        });
  }
}
