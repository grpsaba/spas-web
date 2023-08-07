import 'package:flutter/material.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/site.dart';

class SiteStatus extends StatefulWidget {
  SiteStatus({super.key, required this.site});
  Site site;
  @override
  _AlertState createState() => _AlertState();
}

class _AlertState extends State<SiteStatus> {
  SiteService _siteService = SiteService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child:
          Loading(size: 25, inline: false, sos: true, status: widget.site.sos),
    );
  }
}
