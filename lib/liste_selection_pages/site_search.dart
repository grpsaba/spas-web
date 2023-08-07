import 'dart:convert';

import 'package:animation_search_bar/animation_search_bar.dart';
import 'package:flutter/material.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/site.dart';

class SiteSearch extends StatefulWidget {
  SiteSearch({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SiteSearch> {
  SiteService _siteService = SiteService();
  TextEditingController _texController = TextEditingController();
  String _keyword = "";
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: PreferredSize(
              preferredSize: const Size(double.infinity, 65),
              child: SafeArea(
                  child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 0,
                          offset: Offset(0, 5))
                    ]),
                alignment: Alignment.center,
                child: AnimationSearchBar(
                  textStyle: const TextStyle(color: Colors.white),
                  hintStyle: const TextStyle(color: Colors.white),
                  backIconColor: Colors.white,
                  closeIconColor: Colors.white,
                  searchIconColor: Colors.white,
                  cursorColor: Colors.white,
                  hintText: "Rechercher ici...",
                  centerTitle: "Sélectionner un site",
                  centerTitleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25),
                  onChanged: (text) {
                    setState(() {
                      _keyword = text;
                    });
                  },
                  searchTextEditingController: _texController,
                ),
              ))),
          body: StreamBuilder(
              stream: _siteService.all(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }
                if (snapshot.hasData) {
                  var docs = snapshot.data?.docs
                      .map((e) => jsonDecode(jsonEncode(e.data())))
                      .toList();
                  var lst = jsonDecode(jsonEncode(docs));
                  //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

                  var data = docs?.map((e) => Site.fromJson(e)).toList();
                  data = data
                      ?.where((element) => element.name.contains(_keyword))
                      .toList();
                  return ListView.builder(
                      itemCount: data!.length,
                      itemBuilder: (context, index) {
                        Site site = data![index];
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                site.name,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  "Contact:${site.phone}  Adresse:${site.adresse}"),
                              leading: Icon(
                                Icons.location_on,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.of(context).pop(site);
                              },
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
              })),
    );
  }
}
