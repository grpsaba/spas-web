import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/notes/imprime_rapport.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/models/date_filter.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/supervisor.dart';
import 'Site_non_visite_par_sup.dart';
import 'nombrePointageStatut.dart';

class SitePointingListWithStatus extends StatefulWidget {
  final List<Supervisor> supList;
  const SitePointingListWithStatus({super.key, required this.supList});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SitePointingListWithStatus> {
  final SupervisorService _supervisorService = SupervisorService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  DateFilter _selectedDateFilter = DateFilter.today;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  /*Site _selectedSite = Site(
      nbAgent: 0,
      UID: "",
      codeSite: "",
      name: "",
      adresse: "",
      phone: "",
      latLng: LatLngModel(lng: 0.0, lat: 0.0),
      email: "",
      supervisor: null,
      token: '');*/
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8.0),
        height: MediaQuery.of(context).size.height - 192,
        decoration: BoxDecoration(
            color: AppConstants.secondaryColor,
            borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text(
                  "Pointages site",
                  style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
            Row(
              children: [
               
                Expanded(
                  child: SearchTextField(
                      fillColor: AppConstants.bgColor,
                      hintColor: AppConstants.secondaryColor,
                      textColor: Colors.white,
                      onSearch: (value) {
                        setState(() {
                          _keyword = value;
                        });
                      },
                      onPress: () {}),
                ),
                const SizedBox(width: 5),
                _buildDateFilterDropdown(),
              ],
            ),
            const Divider(),
            Expanded(
              child: sipervisorList(data: widget.supList),

              // FutureBuilder(
              //     future: _supervisorService.allActifFuture(_keyword),
              //     builder: (context, snapshot) {
              //       switch (snapshot.connectionState) {
              //         case ConnectionState.none:
              //           // TODO: Handle this case.
              //           return const SizedBox.shrink();
              //         case ConnectionState.waiting:
              //           // TODO: Handle this case.
              //           return Loading(size: 64, inline: false);

              //         case ConnectionState.active:
              //           // TODO: Handle this case.

              //           var data = snapshot.data ?? [];

              //           return sipervisorList(data: data);
              //         case ConnectionState.done:
              //           var data = snapshot.data ?? [];
              //           return sipervisorList(data: data);
              //       }
              //     }),
            ),
          ],
        ));
  }

  Widget sipervisorList({required List<Supervisor> data}) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          Supervisor supervisor = data[index];
          return Card(
            elevation: 0.2,
            color: AppConstants.secondaryColor.withOpacity(0.3),
            child: ListTile(
              //selected: site.UID == _selectedSite.UID,
              selectedTileColor: AppConstants.secondaryColor,
              title: Text(
                '${supervisor.firstName} ${supervisor.lastName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              subtitle: NbPointageStatus(
                supervisor: supervisor,
                dateFilter: _selectedDateFilter,
                customStartDate: _customStartDate,
                customEndDate: _customEndDate,
              ),
              trailing: IconButton(
                tooltip: "Rapport",
                icon: const Icon(
                  Icons.description,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ImprimeRapport(
                              source:
                                  "${supervisor.firstName} ${supervisor.lastName}")));
                },
              ),
              /* leading: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          AssetImage(Assets.assetsAgent),
                                    )),*/
              onTap: () {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        contentPadding: const EdgeInsets.all(0.0),
                        alignment: Alignment.center,
                        content: Builder(
                          builder: (context) {
                            // Get available height and width of the build area of this widget. Make a choice depending on the size.

                            var width = MediaQuery.of(context).size.width;

                            return Container(
                              width: width - (width - 500),
                              child:
                                  // Container()
                                  SiteNonVisite(
                                supervisor: supervisor,
                              ),
                            );
                          },
                        ),
                      );
                    });
              },
            ),
          );
        });
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: AppConstants.bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateFilter>(
          value: _selectedDateFilter,
          padding: EdgeInsets.all(0),
          dropdownColor: AppConstants.bgColor,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          items: DateFilter.values.map((DateFilter filter) {
            return DropdownMenuItem<DateFilter>(
              value: filter,
              child: Text(
                filter.label,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (DateFilter? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedDateFilter = newValue;
                if (newValue == DateFilter.custom) {
                  _showCustomDatePicker();
                } else {
                  _customStartDate = null;
                  _customEndDate = null;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _customEndDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _customEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    } else {
      // Si l'utilisateur annule, revenir au filtre précédent
      setState(() {
        _selectedDateFilter = DateFilter.today;
      });
    }
  }
}
