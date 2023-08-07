import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/const.dart';

import '../model.dart';
import '../search_textField.dart';
import '../services/loading.dart';
import '../services/site.dart';

class SiteSearchDialog extends StatefulWidget {
  SiteSearchDialog({super.key, required this.onSelected});
  final void Function(Site site) onSelected;
  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SiteSearchDialog> {
  final SiteService _siteService = SiteService();
  //final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            height: 60,
            //width: 400,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SearchTextField(
                    onSearch: (value) {
                      _keyword = value;
                      setState(() {});
                    },
                    onPress: () {}),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
          Container(
              padding: const EdgeInsets.all(8.0),
              height: AppConstants.dialogHeight,
              width: AppConstants.dialogWidth,
              child: StreamBuilder(
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
                          ?.where((element) => element.name
                              .toLowerCase()
                              .startsWith(_keyword.toLowerCase()))
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
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),
                                    onTap: () => widget.onSelected(site)),
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
                  }))
        ]);
  }
}
