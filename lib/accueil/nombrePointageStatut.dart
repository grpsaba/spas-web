import 'package:flutter/material.dart';
import 'package:spas_web/accueil/widgets/dashboard_progress_bar.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/models/date_filter.dart';
import 'package:spas_web/services/pointerSite.dart';

import '../model.dart';
import '../services/site.dart';

class NbPointageStatus extends StatefulWidget {
  final Supervisor supervisor;
  final DateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool lightTheme;

  const NbPointageStatus({
    super.key,
    required this.supervisor,
    this.dateFilter = DateFilter.today,
    this.customStartDate,
    this.customEndDate,
    this.lightTheme = false,
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
                    final progressColor = percentage <= 30
                        ? const Color(0xFFD14343)
                        : percentage <= 60
                            ? const Color(0xFFB76E00)
                            : const Color(0xFF198754);
                    final primaryTextColor = widget.lightTheme
                        ? const Color(0xFF172033)
                        : Colors.white;
                    final secondaryTextColor = widget.lightTheme
                        ? const Color(0xFF667085)
                        : Colors.white.withValues(alpha: 0.6);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DashboardProgressBar(
                                value: percentage,
                                color: progressColor,
                                trackColor: widget.lightTheme
                                    ? const Color(0xFFE9EDF4)
                                    : AppConstants.bgColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${percentage.round()}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: progressColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sites: $visitedSitesCount/$nbTotalSites",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.dateFilter != DateFilter.today)
                          Text(
                            widget.dateFilter.label,
                            style: TextStyle(
                              color: primaryTextColor.withValues(alpha: 0.45),
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
