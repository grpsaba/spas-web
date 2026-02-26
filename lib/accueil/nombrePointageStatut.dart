import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/models/date_filter.dart';
import 'package:spas_web/services/pointage_weighted_engine.dart';
import 'package:spas_web/services/pointerSite.dart';

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

  int _countRequestedDays(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    final isExclusiveEnd = endDate.hour == 0 &&
        endDate.minute == 0 &&
        endDate.second == 0 &&
        endDate.millisecond == 0 &&
        endDate.microsecond == 0;

    final days = isExclusiveEnd
        ? end.difference(start).inDays
        : end.difference(start).inDays + 1;

    return days <= 0 ? 1 : days;
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
            final docs = snapshot.data?.docs
                    .map((e) => Map<String, dynamic>.from(e.data() as Map<String, dynamic>))
                    .toList() ??
                [];

            return FutureBuilder<List<Site>>(
                future: SiteService().allBySupervisor(widget.supervisor),
                builder: (context, sitesSnapshot) {
                  if (sitesSnapshot.hasData) {
                    final sites = sitesSnapshot.data ?? [];
                    final periodDays = _countRequestedDays(_startDate, _endDate);

                    final weighted = PointageWeightedEngine.computeForSitePointings(
                      allSites: sites,
                      pointingDocs: docs,
                      supervisorUid: widget.supervisor.UID,
                      periodDays: periodDays,
                    );

                    final percentage = weighted.performancePercent.clamp(0.0, 100.0);

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
                          "Poids: ${weighted.realizedWeight.toStringAsFixed(1)}/${weighted.expectedWeight.toStringAsFixed(1)}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Sites: ${weighted.visitedSites}/${weighted.totalSites}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10,
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
