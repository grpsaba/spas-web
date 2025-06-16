import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/services/supervisor.dart';

class HomeProvider extends ChangeNotifier {
  int nbSite = 0;
  bool greeting = false;
  List<Site> sites = [];
  List<Supervisor> supvisor = [];

  getSites() async {
    List<Site> sits = await SiteService().allAsModel();
    await Future.delayed(const Duration(seconds: 3));

    sites = sits.where((element) => element.actif == true).toList();
    nbSite = sites.length;
    greeting = true;
    notifyListeners();
  }

  getSupvisor() async {
    List<Supervisor> sup = await SupervisorService().allFuture();
    await Future.delayed(const Duration(seconds: 4));

    supvisor = sup;

    notifyListeners();
  }

  void cleanArrays() async {
    sites.clear();
    supvisor.clear();
    notifyListeners();
  }

  void onRefresh() async {
    getSites();
    getSupvisor();
  }
}
