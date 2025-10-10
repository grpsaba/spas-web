import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/providers/home_provider.dart';
import 'package:spas_web/services/pointerSite.dart';
import 'package:spas_web/services/supervisor.dart';
import 'package:spas_web/supervisor/rapportPointageGenerator.dart';
import 'package:spas_web/utilsClass.dart';

class SitePointageMap extends StatefulWidget {
  const SitePointageMap({super.key,  this.date});
  final DateTime? date;
  @override
  _SitePointageMapState createState() => _SitePointageMapState();
}

class _SitePointageMapState extends State<SitePointageMap> {
  List<Supervisor> supervisors = [];
  bool isLoading = false;
  double progress = 0.0;
  List<Map<String, dynamic>> reportData = [];
late HomeProvider _provider;
  @override
  void initState() {
    _provider = Provider.of<HomeProvider>(listen: false, context);
    super.initState();
    _fetchSupervisors();
  }

  Future<void> _fetchSupervisors() async {
    supervisors = await SupervisorService().allFuture(); // garde comme avant
    setState(() {});
  }

  Future<void> _generateReport() async {
    if (supervisors.isEmpty) return;
    setState(() {
      isLoading = true;
      progress = 0.0;
    });

    final days = UtilsClass().jourDuMois(widget.date?? DateTime.now());
    final uids = supervisors.map((s) => s.UID).toList();
    final total = uids.length * days.length;
    int done = 0;
    
   // final helper = AggregationHelper();
    final results = <Map<String, dynamic>>[];

    // On lance supervisor par supervisor pour garder la logique simple et CLARE
    for (final s in supervisors) {
       
       final sites =  _provider.sites.where((site)=>
          site.supervisor?.UID==s.UID|| site.supervisor_2?.UID==s.UID).toList();
          final nbSitesBySup =sites.length;
      final perSupervisor = <Map<String, dynamic>>[];
      for (final day in days) {
        final count = await PointingSiteService().countForSupervisorOnDate(s.UID, day);
       
        perSupervisor.add({'date': day, 'count': count});
        done++;
        setState(() { progress = done / total; });
      }
      results.add({'supervisor': s, 'Pointages': perSupervisor,'nbSite':nbSitesBySup});
    }

    setState(() {
      reportData = results;
      isLoading = false;
      progress = 0.0;
    });

    // Appelle ton générateur Excel avec reportData
    RapportPointage.printReportToExcelWeb(reportData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = {
      'bg': const Color(0xFF404040),
      'secondary': const Color(0xFF727171).withOpacity(0.4),
      'primary': Colors.indigo,
      'text': Colors.white,
    };

    return Scaffold(
      backgroundColor: colors['bg'],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.print, size: 68, color: colors['primary']),
              const SizedBox(height: 12),
              Text(
                'Pointages — mois sélectionné',
                style: TextStyle(fontSize: 20, color: colors['text'], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text('Génération en cours : ${(progress*100).toStringAsFixed(0)}%', style: TextStyle(color: colors['text'])),
                  ],
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _generateReport,
                icon: const Icon(Icons.download),
                label: const Text('Télécharger le rapport'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors['primary'],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
